# Advanced SQL Engineering & Query Optimization

This document breaks down the advanced SQL design patterns and queries implemented in the **Hashira Market DBMS**.

---

## 1. Key SQL Competencies Demonstrated

| Concept | SQL Technique | Location |
|---|---|---|
| **Analytical Window Functions** | `DENSE_RANK()`, `RANK()`, `PERCENT_RANK()`, `SUM() OVER(PARTITION BY...)` | `sql/advanced_queries.sql` (Q1, Q3, Q9) |
| **Common Table Expressions (CTEs)** | Multi-level `WITH` clauses for modular calculation pipelines | `sql/advanced_queries.sql` (Q2, Q9, Q12) |
| **Self-Referential Hierarchies** | `SELF-JOIN` on recursive Mentor-Apprentice relationships | `sql/advanced_queries.sql` (Q4) |
| **High-Arity Relationships** | Ternary (`CASTS_SPELL_ON`) and Quaternary (`INVESTOR_PRODUCT_FIGHT_REWARD`) traversals | `sql/advanced_queries.sql` (Q5, Q7) |
| **Conditional Matrix Pivoting** | `CASE WHEN` inside aggregate functions (`SUM`, `AVG`) | `sql/advanced_queries.sql` (Q6) |
| **ACID Stored Procedures** | Row-locking (`FOR UPDATE`), transaction rollback handlers, status outputs | `sql/views_and_procedures.sql` |
| **Database Triggers** | `AFTER UPDATE` auditing and `BEFORE UPDATE` domain invariants | `sql/views_and_procedures.sql` |
| **Index Design** | Composite and foreign key indexing on high-frequency paths | `sql/schema.sql` |

---

## 2. In-Depth Query Walkthroughs

### 2.1 Multi-Level CTE: Unrealized Portfolio ROI & Net Worth Calculation
```sql
WITH PortfolioBreakdown AS (
    SELECT 
        p.InvestorID,
        p.StockID,
        p.Quantity,
        p.PurchasePrice,
        s.BaseValue AS CurrentPrice,
        (p.Quantity * p.PurchasePrice) AS CostBasis,
        (p.Quantity * s.BaseValue) AS MarketValue,
        ((p.Quantity * s.BaseValue) - (p.Quantity * p.PurchasePrice)) AS UnrealizedGain
    FROM PORTFOLIO p
    JOIN STOCK s ON p.StockID = s.StockID
),
InvestorHoldingsAgg AS (
    SELECT 
        pb.InvestorID,
        COUNT(pb.StockID) AS PositionsHeld,
        SUM(pb.CostBasis) AS TotalInvested,
        SUM(pb.MarketValue) AS PortfolioValuation,
        SUM(pb.UnrealizedGain) AS TotalUnrealizedGain,
        ROUND((SUM(pb.UnrealizedGain) / NULLIF(SUM(pb.CostBasis), 0)) * 100, 2) AS YieldPct
    FROM PortfolioBreakdown pb
    GROUP BY pb.InvestorID
)
SELECT 
    i.InvestorID,
    CONCAT(i.FirstName, ' ', i.LastName) AS InvestorName,
    i.Wallet AS CashBalance,
    iha.TotalInvested,
    iha.PortfolioValuation,
    iha.YieldPct,
    ROUND(i.Wallet + iha.PortfolioValuation, 2) AS EstimatedNetWorth
FROM InvestorHoldingsAgg iha
JOIN INVESTOR i ON iha.InvestorID = i.InvestorID
ORDER BY EstimatedNetWorth DESC;
```
**Why this demonstrates skill:**
- Solves a financial accounting problem cleanly in pure SQL without Python post-processing.
- Handles division by zero safely using `NULLIF(SUM(pb.CostBasis), 0)`.
- Computes comprehensive investor net worth combining uninvested liquid cash (`Wallet`) with live equity valuation.

---

### 2.2 Analytical Window Functions: Faction Power Tiers & Percentiles
```sql
SELECT 
    i.InvestorID,
    CONCAT(i.FirstName, ' ', i.LastName) AS CombatantName,
    i.Type AS Faction,
    i.TotalBattles,
    i.WinRate,
    DENSE_RANK() OVER (
        PARTITION BY i.Type 
        ORDER BY i.WinRate DESC, i.TotalBattles DESC
    ) AS FactionCombatRank,
    ROUND(
        PERCENT_RANK() OVER (
            PARTITION BY i.Type 
            ORDER BY i.WinRate ASC
        ) * 100, 1
    ) AS FactionPercentile,
    SUM(i.Wallet) OVER (
        PARTITION BY i.Type 
        ORDER BY i.WinRate DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeFactionWealth
FROM INVESTOR i
WHERE i.TotalBattles > 0
ORDER BY i.Type, FactionCombatRank;
```
**Why this demonstrates skill:**
- Applies `PARTITION BY` to rank combatants inside their respective factions (`Demon Slayer` vs `Demon`).
- Leverages frame specifications (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`) to compute running cumulative wealth.

---

### 2.3 Stored Procedure: Atomic Stock Trading Engine (`sp_execute_stock_trade`)
```sql
-- Excerpt from sql/views_and_procedures.sql
START TRANSACTION;

-- Lock Investor Row to prevent race conditions
SELECT Wallet INTO v_current_wallet
FROM INVESTOR
WHERE InvestorID = p_investor_id
FOR UPDATE;

-- Validate Wallet Balance
IF v_current_wallet < v_total_trade_val THEN
    ROLLBACK;
    SET p_status_code = 2;
    SET p_status_message = 'Insufficient wallet balance.';
    LEAVE proc_label;
END IF;

-- 1. Deduct Wallet
UPDATE INVESTOR SET Wallet = Wallet - v_total_trade_val WHERE InvestorID = p_investor_id;

-- 2. Upsert Portfolio with Weighted Average Purchase Price
INSERT INTO PORTFOLIO (InvestorID, StockID, Quantity, PurchasePrice, PurchaseDate)
VALUES (p_investor_id, p_stock_id, p_quantity, p_price_per_share, CURDATE())
ON DUPLICATE KEY UPDATE
    PurchasePrice = ROUND(((Quantity * PurchasePrice) + (p_quantity * p_price_per_share)) / (Quantity + p_quantity), 2),
    Quantity = Quantity + p_quantity,
    PurchaseDate = CURDATE();

COMMIT;
```
**Why this demonstrates skill:**
- Demonstrates enterprise transaction isolation: uses pessimistic row-level locking (`FOR UPDATE`) to guard against double-spending concurrency bugs.
- Implements financial math: calculates dynamic weighted average cost per share on portfolio additions (`ON DUPLICATE KEY UPDATE`).

---

## 3. Performance Indexing Strategy
```sql
CREATE INDEX idx_investor_type ON INVESTOR(Type);
CREATE INDEX idx_investor_wallet ON INVESTOR(Wallet);
CREATE INDEX idx_company_sector ON COMPANY(SectorID);
CREATE INDEX idx_stock_company ON STOCK(CompanyID);
CREATE INDEX idx_fight_winner ON FIGHT(WinnerInvestorID);
CREATE INDEX idx_fight_loser ON FIGHT(LoserInvestorID);
CREATE INDEX idx_trans_inv_date ON TRANSACTION_RECORD(InvestorID, TransactionDate DESC);
CREATE INDEX idx_portfolio_stock ON PORTFOLIO(StockID);
```
- **Composite Index `idx_trans_inv_date`**: Accelerates the frequent pattern of fetching recent transactions for a given investor ordered chronologically descending without requiring a filesort.
- **Foreign Key Indexes**: Eliminates full-table scans during heavy multi-table JOINs across the quaternary and ternary entities.

