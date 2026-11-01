DROP DATABASE IF EXISTS mini_world_db;
CREATE DATABASE mini_world_db;
USE mini_world_db;

-- ============================================
-- 1. STRONG ENTITIES
-- ============================================

-- SECTOR
CREATE TABLE SECTOR (
    SectorID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Description TEXT,
    RiskLevel INT CHECK (RiskLevel BETWEEN 1 AND 10),
    Created_Date DATE
);

-- INVESTOR (Self-referencing mentor relationship)
CREATE TABLE INVESTOR (
    InvestorID VARCHAR(10) PRIMARY KEY,
    FirstName VARCHAR(30) NOT NULL,
    LastName VARCHAR(30) NOT NULL,
    Type VARCHAR(20) NOT NULL CHECK (Type IN ('Demon slayer', 'Demon')),
    MentorID VARCHAR(10),
    Wallet DECIMAL(15,2) DEFAULT 0.00,
    JoinDate DATE,
    TotalBattles INT DEFAULT 0,
    WinRate DECIMAL(5,2) DEFAULT 0.00,
    CONSTRAINT fk_investor_mentor
        FOREIGN KEY (MentorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- HASHIRA (Subclass of INVESTOR)
CREATE TABLE HASHIRA (
    InvestorID VARCHAR(10) PRIMARY KEY,
    BreathingTechnique VARCHAR(50),
    RankLevel INT CHECK (RankLevel BETWEEN 1 AND 10),
    Corps VARCHAR(30),
    CONSTRAINT fk_hashira_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- UPPER_RANK_DEMON (Subclass of INVESTOR)
CREATE TABLE UPPER_RANK_DEMON (
    InvestorID VARCHAR(10) PRIMARY KEY,
    BloodArt VARCHAR(50),
    RankLevel INT CHECK (RankLevel BETWEEN 1 AND 10),
    Corps VARCHAR(30),
    CONSTRAINT fk_upper_demon_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- COMPANY
CREATE TABLE COMPANY (
    CompanyID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    CEO VARCHAR(50),
    Founded DATE,
    Headquarters VARCHAR(100),
    MarketCap DECIMAL(18,2) DEFAULT 0.00,
    SharesOutstanding BIGINT DEFAULT 1000000,
    SectorID VARCHAR(10),
    CONSTRAINT fk_company_sector 
        FOREIGN KEY (SectorID)
        REFERENCES SECTOR(SectorID) 
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- PRODUCT
CREATE TABLE PRODUCT (
    ProductID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(20) CHECK (Type IN ('Weapon','Potion','Technique','Armor','Tool')),
    PowerLevel INT CHECK (PowerLevel BETWEEN 1 AND 100),
    CompanyID VARCHAR(10),
    Price DECIMAL(10,2),
    ReleaseDate DATE,
    CONSTRAINT fk_product_company 
        FOREIGN KEY (CompanyID)
        REFERENCES COMPANY(CompanyID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- STOCK
CREATE TABLE STOCK (
    StockID VARCHAR(10) PRIMARY KEY,
    Symbol VARCHAR(10) UNIQUE NOT NULL,
    Name VARCHAR(100) NOT NULL,
    BaseValue DECIMAL(10,2) NOT NULL,
    CompanyID VARCHAR(10),
    IPODate DATE,
    CONSTRAINT fk_stock_company
        FOREIGN KEY (CompanyID)
        REFERENCES COMPANY(CompanyID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- FIGHT
CREATE TABLE FIGHT (
    FightID VARCHAR(10) PRIMARY KEY,
    Location VARCHAR(100),
    WinnerInvestorID VARCHAR(10),
    LoserInvestorID VARCHAR(10),
    SkillsUsed TEXT,
    ProductsUsed TEXT,
    CONSTRAINT fk_fight_winner 
        FOREIGN KEY (WinnerInvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_fight_loser 
        FOREIGN KEY (LoserInvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- MAGIC_SPELL
CREATE TABLE MAGIC_SPELL (
    SpellID VARCHAR(10) PRIMARY KEY,
    InvestorID VARCHAR(10),
    Name VARCHAR(100) NOT NULL,
    EffectType VARCHAR(20) CHECK (EffectType IN ('Pump','Crash','Freeze','Volatility')),
    Duration INT,
    CooldownPeriod INT,
    Description TEXT,
    CONSTRAINT fk_spell_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- NEWS_EFFECT
CREATE TABLE NEWS_EFFECT (
    NewsID VARCHAR(10) PRIMARY KEY,
    FightID VARCHAR(10),
    WinnerType VARCHAR(10) CHECK (WinnerType IN ('Hero','Villain','Demon')),
    Description TEXT,
    StockEffect DECIMAL(5,2),
    ImpactLevel VARCHAR(10) CHECK (ImpactLevel IN ('Low','Medium','High','Critical')),
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_news_fight
        FOREIGN KEY (FightID)
        REFERENCES FIGHT(FightID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- TRANSACTION (Named TRANSACTION_RECORD to avoid reserved word)
CREATE TABLE TRANSACTION_RECORD (
    TransactionID VARCHAR(15) PRIMARY KEY,
    InvestorID VARCHAR(10),
    StockID VARCHAR(10),
    TransactionType VARCHAR(10) CHECK (TransactionType IN ('Buy','Sell')),
    Quantity INT CHECK (Quantity > 0),
    PricePerShare DECIMAL(10,2),
    TransactionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TotalValue DECIMAL(18,2),
    CONSTRAINT fk_trans_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_trans_stock
        FOREIGN KEY (StockID)
        REFERENCES STOCK(StockID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 2. WEAK ENTITIES
-- ============================================

-- INVESTOR_SKILLS
CREATE TABLE INVESTOR_SKILLS (
    InvestorID VARCHAR(10),
    Skill VARCHAR(50),
    SkillLevel INT CHECK (SkillLevel BETWEEN 1 AND 10),
    PRIMARY KEY (InvestorID, Skill),
    CONSTRAINT fk_skill_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- FIGHT_SCORE
CREATE TABLE FIGHT_SCORE (
    FightID VARCHAR(10),
    InvestorID VARCHAR(10),
    Score INT CHECK (Score BETWEEN 0 AND 100),
    Performance VARCHAR(20) CHECK (Performance IN ('Excellent','Good','Average','Poor')),
    Rewards DECIMAL(10,2) DEFAULT 0.00,
    EffectDescription TEXT,
    PRIMARY KEY (FightID, InvestorID),
    CONSTRAINT fk_fs_fight
        FOREIGN KEY (FightID)
        REFERENCES FIGHT(FightID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fs_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 3. MULTIVALUED ATTRIBUTES
-- ============================================

-- HASHIRA_BREATHING_TECHNIQUES
CREATE TABLE HASHIRA_BREATHING_TECHNIQUES (
    InvestorID VARCHAR(10),
    Technique VARCHAR(50),
    PRIMARY KEY (InvestorID, Technique),
    CONSTRAINT fk_hb_investor
        FOREIGN KEY (InvestorID)
        REFERENCES HASHIRA(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- COMPANY_PRODUCT_TYPE
CREATE TABLE COMPANY_PRODUCT_TYPE (
    CompanyID VARCHAR(10),
    ProductType VARCHAR(50),
    PRIMARY KEY (CompanyID, ProductType),
    CONSTRAINT fk_cpt_company
        FOREIGN KEY (CompanyID)
        REFERENCES COMPANY(CompanyID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 4. MANY-TO-MANY RELATIONSHIPS
-- ============================================

-- PORTFOLIO (Investor owns Stocks)
CREATE TABLE PORTFOLIO (
    InvestorID VARCHAR(10),
    StockID VARCHAR(10),
    Quantity BIGINT,
    PurchasePrice DECIMAL(10,2),
    PurchaseDate DATE,
    PRIMARY KEY (InvestorID, StockID),
    CONSTRAINT fk_port_inv
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_port_stock
        FOREIGN KEY (StockID)
        REFERENCES STOCK(StockID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- PROMOTES (Company promotes Investor)
CREATE TABLE PROMOTES (
    CompanyID VARCHAR(10),
    InvestorID VARCHAR(10),
    StartDate DATE,
    EndDate DATE,
    Role VARCHAR(50),
    PRIMARY KEY (CompanyID, InvestorID),
    CONSTRAINT fk_prom_company
        FOREIGN KEY (CompanyID)
        REFERENCES COMPANY(CompanyID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_prom_investor
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 5. TERNARY RELATIONSHIP
-- ============================================

-- CASTS_SPELL_ON (Investor casts Spell on Stock)
CREATE TABLE CASTS_SPELL_ON (
    CastID INT AUTO_INCREMENT PRIMARY KEY,
    InvestorID VARCHAR(10),
    SpellID VARCHAR(10),
    StockID VARCHAR(10),
    CastTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    EffectDuration INT,
    PowerConsumption INT,
    CONSTRAINT fk_cast_investor 
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cast_spell 
        FOREIGN KEY (SpellID)
        REFERENCES MAGIC_SPELL(SpellID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cast_stock 
        FOREIGN KEY (StockID)
        REFERENCES STOCK(StockID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 6. QUATERNARY RELATIONSHIP
-- ============================================

-- INVESTOR_PRODUCT_FIGHT_REWARD (Investor uses Product in Fight affecting Stock)
CREATE TABLE INVESTOR_PRODUCT_FIGHT_REWARD (
    InvestorID VARCHAR(10),
    ProductID VARCHAR(10),
    FightID VARCHAR(10),
    StockID VARCHAR(10),
    RewardAmount DECIMAL(10,2),
    EffectDescription TEXT,
    PRIMARY KEY (InvestorID, ProductID, FightID, StockID),
    CONSTRAINT fk_ipfr_investor 
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ipfr_product 
        FOREIGN KEY (ProductID)
        REFERENCES PRODUCT(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ipfr_fight 
        FOREIGN KEY (FightID)
        REFERENCES FIGHT(FightID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ipfr_stock 
        FOREIGN KEY (StockID)
        REFERENCES STOCK(StockID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- INVESTOR_FIGHT_SKILL_SCORE (Simplified - Investor uses Skill in Fight with Score)
CREATE TABLE INVESTOR_FIGHT_SKILL_SCORE (
    InvestorID VARCHAR(10),
    FightID VARCHAR(10),
    Skill VARCHAR(50),
    SkillScore INT CHECK (SkillScore BETWEEN 0 AND 100),
    PRIMARY KEY (InvestorID, FightID, Skill),
    CONSTRAINT fk_ifss_investor 
        FOREIGN KEY (InvestorID)
        REFERENCES INVESTOR(InvestorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ifss_fight 
        FOREIGN KEY (FightID)
        REFERENCES FIGHT(FightID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ifss_skill
        FOREIGN KEY (InvestorID, Skill)
        REFERENCES INVESTOR_SKILLS(InvestorID, Skill)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 7. AUDIT LOGGING INFRASTRUCTURE
-- ============================================
CREATE TABLE IF NOT EXISTS AUDIT_COMPANY_MARKETCAP (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    CompanyID VARCHAR(10) NOT NULL,
    OldMarketCap DECIMAL(18,2) NOT NULL,
    NewMarketCap DECIMAL(18,2) NOT NULL,
    ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ChangedBy VARCHAR(50) DEFAULT 'SYSTEM',
    CONSTRAINT fk_audit_company
        FOREIGN KEY (CompanyID)
        REFERENCES COMPANY(CompanyID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================
-- 8. PERFORMANCE INDEXES
-- ============================================
CREATE INDEX idx_investor_type ON INVESTOR(Type);
CREATE INDEX idx_investor_wallet ON INVESTOR(Wallet);
CREATE INDEX idx_company_sector ON COMPANY(SectorID);
CREATE INDEX idx_stock_company ON STOCK(CompanyID);
CREATE INDEX idx_product_company ON PRODUCT(CompanyID);
CREATE INDEX idx_fight_winner ON FIGHT(WinnerInvestorID);
CREATE INDEX idx_fight_loser ON FIGHT(LoserInvestorID);
CREATE INDEX idx_trans_inv_date ON TRANSACTION_RECORD(InvestorID, TransactionDate DESC);
CREATE INDEX idx_trans_stock ON TRANSACTION_RECORD(StockID);
CREATE INDEX idx_portfolio_stock ON PORTFOLIO(StockID);
CREATE INDEX idx_news_fight ON NEWS_EFFECT(FightID);
CREATE INDEX idx_spell_investor ON MAGIC_SPELL(InvestorID);

