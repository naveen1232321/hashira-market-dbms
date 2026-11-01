-- ==============================================================================
-- Hashira Market DBMS - Views, Stored Procedures & Triggers
-- File: views_and_procedures.sql
-- Description: Advanced database objects demonstrating ACID transactions,
--              business logic encapsulation, analytical views, and audit triggers.
-- ==============================================================================

USE mini_world_db;

-- ==============================================================================
-- SECTION 1: AUDIT INFRASTRUCTURE
-- ==============================================================================

CREATE TABLE IF NOT EXISTS AUDIT_COMPANY_MARKETCAP (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    CompanyID VARCHAR(10) NOT NULL,
    OldMarketCap DECIMAL(18,2) NOT NULL,
    NewMarketCap DECIMAL(18,2) NOT NULL,
    ChangeAmount DECIMAL(18,2) GENERATED ALWAYS AS (NewMarketCap - OldMarketCap) STORED,
    ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ChangedBy VARCHAR(50) DEFAULT 'SYSTEM',
    INDEX idx_audit_company (CompanyID, ChangedAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- SECTION 2: ANALYTICAL & BUSINESS VIEWS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- View 1: vw_investor_financial_overview
-- Unified snapshot of each investor's cash, portfolio market valuation,
-- total holdings count, and overall estimated net worth.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_investor_financial_overview AS
SELECT 
    i.InvestorID,
    CONCAT(i.FirstName, ' ', i.LastName) AS FullName,
    i.Type AS InvestorType,
    i.Wallet AS CashBalance,
    COALESCE(COUNT(DISTINCT p.StockID), 0) AS UniqueStocksHeld,
    COALESCE(SUM(p.Quantity), 0) AS TotalSharesHeld,
    COALESCE(SUM(p.Quantity * p.PurchasePrice), 0.00) AS TotalPortfolioCostBasis,
    COALESCE(SUM(p.Quantity * s.BaseValue), 0.00) AS CurrentPortfolioValue,
    ROUND(i.Wallet + COALESCE(SUM(p.Quantity * s.BaseValue), 0.00), 2) AS EstimatedNetWorth,
    ROUND(
        CASE 
            WHEN COALESCE(SUM(p.Quantity * p.PurchasePrice), 0) > 0 
            THEN ((SUM(p.Quantity * s.BaseValue) - SUM(p.Quantity * p.PurchasePrice)) / SUM(p.Quantity * p.PurchasePrice)) * 100
            ELSE 0.00 
        END, 2
    ) AS UnrealizedROI_Pct
FROM INVESTOR i
LEFT JOIN PORTFOLIO p ON i.InvestorID = p.InvestorID
LEFT JOIN STOCK s ON p.StockID = s.StockID
GROUP BY i.InvestorID, i.FirstName, i.LastName, i.Type, i.Wallet;

-- ------------------------------------------------------------------------------
-- View 2: vw_sector_market_distribution
-- Aggregates capital distribution across sectors with economy share %.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_sector_market_distribution AS
SELECT 
    s.SectorID,
    s.Name AS SectorName,
    s.RiskLevel,
    COUNT(DISTINCT c.CompanyID) AS TotalCompanies,
    COUNT(DISTINCT stk.StockID) AS TotalStocksListed,
    COALESCE(SUM(c.MarketCap), 0.00) AS SectorTotalMarketCap,
    ROUND(
        COALESCE(SUM(c.MarketCap), 0.00) / 
        NULLIF((SELECT SUM(MarketCap) FROM COMPANY), 0) * 100, 
        2
    ) AS EconomyMarketSharePct
FROM SECTOR s
LEFT JOIN COMPANY c ON s.SectorID = c.SectorID
LEFT JOIN STOCK stk ON c.CompanyID = stk.CompanyID
GROUP BY s.SectorID, s.Name, s.RiskLevel;

-- ------------------------------------------------------------------------------
-- View 3: vw_battle_market_sentiment_feed
-- Correlates combat victories and losses with immediate stock market impact.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_battle_market_sentiment_feed AS
SELECT 
    f.FightID,
    f.Location,
    w.InvestorID AS WinnerID,
    CONCAT(w.FirstName, ' ', w.LastName) AS WinnerName,
    w.Type AS WinnerType,
    l.InvestorID AS LoserID,
    CONCAT(l.FirstName, ' ', l.LastName) AS LoserName,
    l.Type AS LoserType,
    ne.NewsID,
    ne.Description AS MarketNarrative,
    ne.StockEffect AS StockEffectPct,
    ne.ImpactLevel,
    ne.Timestamp AS EventTime
FROM FIGHT f
INNER JOIN INVESTOR w ON f.WinnerInvestorID = w.InvestorID
INNER JOIN INVESTOR l ON f.LoserInvestorID = l.InvestorID
LEFT JOIN NEWS_EFFECT ne ON f.FightID = ne.FightID;

-- ------------------------------------------------------------------------------
-- View 4: vw_mentor_mentee_network
-- Demonstrates self-referential relationships, comparing mentor experience
-- and mentee performance metrics.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_mentor_mentee_network AS
SELECT 
    m.InvestorID AS MentorID,
    CONCAT(m.FirstName, ' ', m.LastName) AS MentorName,
    m.WinRate AS MentorWinRate,
    m.TotalBattles AS MentorBattles,
    COUNT(a.InvestorID) AS NumberOfApprentices,
    ROUND(AVG(a.WinRate), 2) AS AverageApprenticeWinRate,
    COALESCE(SUM(a.Wallet), 0.00) AS TotalApprenticeCash
FROM INVESTOR m
INNER JOIN INVESTOR a ON m.InvestorID = a.MentorID
GROUP BY m.InvestorID, m.FirstName, m.LastName, m.WinRate, m.TotalBattles;

-- ------------------------------------------------------------------------------
-- View 5: vw_product_combat_performance
-- Deep quaternary relational view connecting weapon/item usage in combat to
-- corporate sponsor equity metrics.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_combat_performance AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.Type AS ProductType,
    p.PowerLevel,
    c.Name AS ManufacturerName,
    s.Symbol AS StockSymbol,
    s.BaseValue AS CurrentStockPrice,
    COUNT(ipfr.FightID) AS TimesUsedInBattle,
    COALESCE(SUM(ipfr.RewardAmount), 0.00) AS TotalCombatRewardsYielded
FROM PRODUCT p
INNER JOIN COMPANY c ON p.CompanyID = c.CompanyID
LEFT JOIN STOCK s ON c.CompanyID = s.CompanyID
LEFT JOIN INVESTOR_PRODUCT_FIGHT_REWARD ipfr ON p.ProductID = ipfr.ProductID
GROUP BY p.ProductID, p.Name, p.Type, p.PowerLevel, c.Name, s.Symbol, s.BaseValue;

-- ==============================================================================
-- SECTION 3: STORED PROCEDURES (ACID TRANSACTION MANAGEMENT)
-- ==============================================================================

DELIMITER $$

-- ------------------------------------------------------------------------------
-- Procedure: sp_execute_stock_trade
-- Handles atomic stock purchases and sales with row locking, balance checks,
-- and automated transaction record creation.
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_execute_stock_trade$$

CREATE PROCEDURE sp_execute_stock_trade(
    IN p_investor_id VARCHAR(10),
    IN p_stock_id VARCHAR(10),
    IN p_tx_type VARCHAR(10),       -- 'Buy' or 'Sell'
    IN p_quantity INT,
    IN p_price_per_share DECIMAL(10,2),
    OUT p_status_code INT,           -- 0 = Success, 1 = Invalid Inputs, 2 = Insufficient Balance/Holdings, 99 = Error
    OUT p_status_message VARCHAR(255),
    OUT p_transaction_id VARCHAR(15)
)
proc_label: BEGIN
    DECLARE v_current_wallet DECIMAL(15,2);
    DECLARE v_current_shares BIGINT DEFAULT 0;
    DECLARE v_total_trade_val DECIMAL(18,2);
    DECLARE v_new_tx_id VARCHAR(15);
    
    -- Error Handler: Rollback on any SQL Exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = 99;
        SET p_status_message = 'SQL Exception occurred. Transaction rolled back.';
        SET p_transaction_id = NULL;
    END;

    -- Input Validations
    IF p_quantity <= 0 OR p_price_per_share <= 0 THEN
        SET p_status_code = 1;
        SET p_status_message = 'Quantity and price must be strictly positive.';
        SET p_transaction_id = NULL;
        LEAVE proc_label;
    END IF;

    IF p_tx_type NOT IN ('Buy', 'Sell') THEN
        SET p_status_code = 1;
        SET p_status_message = 'TransactionType must be either "Buy" or "Sell".';
        SET p_transaction_id = NULL;
        LEAVE proc_label;
    END IF;

    SET v_total_trade_val = ROUND(p_quantity * p_price_per_share, 2);
    SET v_new_tx_id = CONCAT('TX', LPAD(FLOOR(RAND() * 89999 + 10000), 5, '0'));

    -- Begin Transaction
    START TRANSACTION;

    -- Validate and Lock Investor Row
    SELECT Wallet INTO v_current_wallet
    FROM INVESTOR
    WHERE InvestorID = p_investor_id
    FOR UPDATE;

    IF v_current_wallet IS NULL THEN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = CONCAT('Investor ', p_investor_id, ' does not exist.');
        SET p_transaction_id = NULL;
        LEAVE proc_label;
    END IF;

    -- Validate Stock exists
    IF NOT EXISTS (SELECT 1 FROM STOCK WHERE StockID = p_stock_id) THEN
        ROLLBACK;
        SET p_status_code = 1;
        SET p_status_message = CONCAT('Stock ', p_stock_id, ' does not exist.');
        SET p_transaction_id = NULL;
        LEAVE proc_label;
    END IF;

    -- ==================== BUY LOGIC ====================
    IF p_tx_type = 'Buy' THEN
        IF v_current_wallet < v_total_trade_val THEN
            ROLLBACK;
            SET p_status_code = 2;
            SET p_status_message = CONCAT('Insufficient wallet balance. Required: ', v_total_trade_val, ', Available: ', v_current_wallet);
            SET p_transaction_id = NULL;
            LEAVE proc_label;
        END IF;

        -- 1. Deduct Wallet
        UPDATE INVESTOR 
        SET Wallet = Wallet - v_total_trade_val 
        WHERE InvestorID = p_investor_id;

        -- 2. Upsert Portfolio
        INSERT INTO PORTFOLIO (InvestorID, StockID, Quantity, PurchasePrice, PurchaseDate)
        VALUES (p_investor_id, p_stock_id, p_quantity, p_price_per_share, CURDATE())
        ON DUPLICATE KEY UPDATE
            PurchasePrice = ROUND(((Quantity * PurchasePrice) + (p_quantity * p_price_per_share)) / (Quantity + p_quantity), 2),
            Quantity = Quantity + p_quantity,
            PurchaseDate = CURDATE();

    -- ==================== SELL LOGIC ====================
    ELSEIF p_tx_type = 'Sell' THEN
        SELECT Quantity INTO v_current_shares
        FROM PORTFOLIO
        WHERE InvestorID = p_investor_id AND StockID = p_stock_id
        FOR UPDATE;

        IF v_current_shares IS NULL OR v_current_shares < p_quantity THEN
            ROLLBACK;
            SET p_status_code = 2;
            SET p_status_message = CONCAT('Insufficient shares to sell. Owned: ', COALESCE(v_current_shares, 0), ', Attempted: ', p_quantity);
            SET p_transaction_id = NULL;
            LEAVE proc_label;
        END IF;

        -- 1. Credit Wallet
        UPDATE INVESTOR 
        SET Wallet = Wallet + v_total_trade_val 
        WHERE InvestorID = p_investor_id;

        -- 2. Update or Remove Portfolio row
        IF v_current_shares = p_quantity THEN
            DELETE FROM PORTFOLIO 
            WHERE InvestorID = p_investor_id AND StockID = p_stock_id;
        ELSE
            UPDATE PORTFOLIO 
            SET Quantity = Quantity - p_quantity 
            WHERE InvestorID = p_investor_id AND StockID = p_stock_id;
        END IF;
    END IF;

    -- 3. Insert Transaction Record
    INSERT INTO TRANSACTION_RECORD (
        TransactionID, InvestorID, StockID, TransactionType, Quantity, PricePerShare, TransactionDate, TotalValue
    ) VALUES (
        v_new_tx_id, p_investor_id, p_stock_id, p_tx_type, p_quantity, p_price_per_share, NOW(), v_total_trade_val
    );

    COMMIT;
    SET p_status_code = 0;
    SET p_status_message = 'Transaction executed successfully.';
    SET p_transaction_id = v_new_tx_id;
END proc_label$$

-- ------------------------------------------------------------------------------
-- Procedure: sp_record_battle_event
-- Inserts battle, generates news effect, and updates battle counts atomically.
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_battle_event$$

CREATE PROCEDURE sp_record_battle_event(
    IN p_fight_id VARCHAR(10),
    IN p_location VARCHAR(100),
    IN p_winner_id VARCHAR(10),
    IN p_loser_id VARCHAR(10),
    IN p_skills_used TEXT,
    IN p_products_used TEXT,
    IN p_news_id VARCHAR(10),
    IN p_winner_type VARCHAR(10),
    IN p_news_desc TEXT,
    IN p_stock_effect DECIMAL(5,2),
    IN p_impact_level VARCHAR(10),
    OUT p_status_code INT,
    OUT p_status_msg VARCHAR(255)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = 99;
        SET p_status_msg = 'Database exception while recording battle event. Rolled back.';
    END;

    -- Validate FightID uniqueness
    IF EXISTS (SELECT 1 FROM FIGHT WHERE FightID = p_fight_id) THEN
        SET p_status_code = 1;
        SET p_status_msg = CONCAT('FightID ', p_fight_id, ' already exists.');
        LEAVE proc_label;
    END IF;

    -- Validate NewsID uniqueness
    IF EXISTS (SELECT 1 FROM NEWS_EFFECT WHERE NewsID = p_news_id) THEN
        SET p_status_code = 1;
        SET p_status_msg = CONCAT('NewsID ', p_news_id, ' already exists.');
        LEAVE proc_label;
    END IF;

    -- Validate Combatants
    IF NOT EXISTS (SELECT 1 FROM INVESTOR WHERE InvestorID = p_winner_id) OR
       NOT EXISTS (SELECT 1 FROM INVESTOR WHERE InvestorID = p_loser_id) THEN
        SET p_status_code = 1;
        SET p_status_msg = 'One or both combatants do not exist in the INVESTOR table.';
        LEAVE proc_label;
    END IF;

    START TRANSACTION;

    -- 1. Insert Fight
    INSERT INTO FIGHT (FightID, Location, WinnerInvestorID, LoserInvestorID, SkillsUsed, ProductsUsed)
    VALUES (p_fight_id, p_location, p_winner_id, p_loser_id, p_skills_used, p_products_used);

    -- 2. Insert News Effect
    INSERT INTO NEWS_EFFECT (NewsID, FightID, WinnerType, Description, StockEffect, ImpactLevel, Timestamp)
    VALUES (p_news_id, p_fight_id, p_winner_type, p_news_desc, p_stock_effect, p_impact_level, NOW());

    -- 3. Update battle statistics for both combatants
    UPDATE INVESTOR 
    SET TotalBattles = TotalBattles + 1,
        WinRate = ROUND(((WinRate * (TotalBattles) / 100) + 1) / (TotalBattles + 1) * 100, 2)
    WHERE InvestorID = p_winner_id;

    UPDATE INVESTOR 
    SET TotalBattles = TotalBattles + 1,
        WinRate = ROUND(((WinRate * (TotalBattles) / 100)) / (TotalBattles + 1) * 100, 2)
    WHERE InvestorID = p_loser_id;

    COMMIT;
    SET p_status_code = 0;
    SET p_status_msg = 'Battle event and news effect registered successfully.';
END proc_label$$

DELIMITER ;

-- ==============================================================================
-- SECTION 4: DATABASE TRIGGERS
-- ==============================================================================

DELIMITER $$

-- ------------------------------------------------------------------------------
-- Trigger 1: trg_audit_marketcap_update
-- Automatically captures every corporate valuation change with audit trail.
-- ------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_marketcap_update$$

CREATE TRIGGER trg_audit_marketcap_update
AFTER UPDATE ON COMPANY
FOR EACH ROW
BEGIN
    IF OLD.MarketCap <> NEW.MarketCap THEN
        INSERT INTO AUDIT_COMPANY_MARKETCAP (
            CompanyID, OldMarketCap, NewMarketCap, ChangedAt, ChangedBy
        ) VALUES (
            NEW.CompanyID, OLD.MarketCap, NEW.MarketCap, NOW(), CURRENT_USER()
        );
    END IF;
END$$

-- ------------------------------------------------------------------------------
-- Trigger 2: trg_prevent_negative_wallet
-- Guarantees domain integrity at the database storage engine layer.
-- ------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_prevent_negative_wallet$$

CREATE TRIGGER trg_prevent_negative_wallet
BEFORE UPDATE ON INVESTOR
FOR EACH ROW
BEGIN
    IF NEW.Wallet < 0.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction rejected: Investor wallet balance cannot fall below zero.';
    END IF;
END$$

DELIMITER ;

