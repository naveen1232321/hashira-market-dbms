-- ==============================================================================
-- Hashira Market DBMS - Advanced SQL Analytics Showcase
-- File: advanced_queries.sql
-- Description: Production-grade SQL queries demonstrating mastery in:
--              - Analytical Window Functions (RANK, DENSE_RANK, ROW_NUMBER, Running Totals)
--              - Multi-Level Common Table Expressions (CTEs)
--              - Complex Multi-Table & Self-Joins
--              - Quaternary & Ternary Relationship Traversal
--              - Conditional Aggregation & Matrix Pivoting
--              - Correlated Subqueries & Set Operators
-- ==============================================================================

USE mini_world_db;

-- ==============================================================================
-- QUERY 1: POWER TIER LEADERBOARD (Analytical Window Functions)
-- Concept: DENSE_RANK() & PERCENT_RANK() partitioned by faction with running totals
-- Business Value: Ranks Demon Slayers and Demons independently by combat efficiency
--                 and win rates, calculating their percentile standing within faction.
-- ==============================================================================
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
    i.Wallet AS LiquidCash,
    SUM(i.Wallet) OVER (
        PARTITION BY i.Type 
        ORDER BY i.WinRate DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeFactionWealth
FROM INVESTOR i
WHERE i.TotalBattles > 0
ORDER BY i.Type, FactionCombatRank;


-- ==============================================================================
-- QUERY 2: UNREALIZED PORTFOLIO GAIN/LOSS ANALYSIS (Multi-level CTE)
-- Concept: Common Table Expressions (WITH clause) calculating equity metrics
-- Business Value: Real-time portfolio valuation comparing cost basis vs live value,
--                 detecting high-performing investors and unrealized ROI %.
-- ==============================================================================
WITH PortfolioBreakdown AS (
    SELECT 
        p.InvestorID,
        p.StockID,
        p.Quantity,
        p.PurchasePrice,
        s.BaseValue AS CurrentPrice,
        (p.Quantity * p.PurchasePrice) AS TotalCostBasis,
        (p.Quantity * s.BaseValue) AS CurrentMarketValue,
        ((p.Quantity * s.BaseValue) - (p.Quantity * p.PurchasePrice)) AS UnrealizedGainLoss
    FROM PORTFOLIO p
    JOIN STOCK s ON p.StockID = s.StockID
),
InvestorPortfolioAggregates AS (
    SELECT 
        pb.InvestorID,
        COUNT(pb.StockID) AS PositionsCount,
        SUM(pb.TotalCostBasis) AS TotalInvested,
        SUM(pb.CurrentMarketValue) AS TotalPortfolioValuation,
        SUM(pb.UnrealizedGainLoss) AS TotalNetGainLoss,
        ROUND((SUM(pb.UnrealizedGainLoss) / NULLIF(SUM(pb.TotalCostBasis), 0)) * 100, 2) AS OverallYieldPct
    FROM PortfolioBreakdown pb
    GROUP BY pb.InvestorID
)
SELECT 
    i.InvestorID,
    CONCAT(i.FirstName, ' ', i.LastName) AS InvestorName,
    i.Type AS InvestorType,
    i.Wallet AS LiquidBalance,
    ipa.PositionsCount,
    ipa.TotalInvested,
    ipa.TotalPortfolioValuation,
    ipa.TotalNetGainLoss,
    ipa.OverallYieldPct,
    ROUND(i.Wallet + ipa.TotalPortfolioValuation, 2) AS TotalNetWorth,
    CASE 
        WHEN ipa.OverallYieldPct >= 10.0 THEN '🟢 High Outperformer'
        WHEN ipa.OverallYieldPct > 0.0  THEN '🟡 Modest Gain'
        WHEN ipa.OverallYieldPct = 0.0  THEN '⚪ Neutral'
        ELSE '🔴 Underperformer'
    END AS PortfolioHealthStatus
FROM InvestorPortfolioAggregates ipa
JOIN INVESTOR i ON ipa.InvestorID = i.InvestorID
ORDER BY TotalNetWorth DESC;


-- ==============================================================================
-- QUERY 3: SECTOR CAPITAL CONCENTRATION & PARETO SHARE (Window Aggregations)
-- Concept: Windowed SUM() OVER () for macroeconomic market share calculations
-- Business Value: Measures economic dominance of each industry sector and individual
--                 company contribution to overall market liquidity.
-- ==============================================================================
SELECT 
    c.CompanyID,
    c.Name AS CompanyName,
    s.Name AS SectorName,
    s.RiskLevel,
    c.MarketCap,
    SUM(c.MarketCap) OVER (PARTITION BY s.SectorID) AS SectorTotalCap,
    ROUND(
        (c.MarketCap / SUM(c.MarketCap) OVER (PARTITION BY s.SectorID)) * 100, 2
    ) AS ShareWithinSectorPct,
    ROUND(
        (c.MarketCap / SUM(c.MarketCap) OVER ()) * 100, 2
    ) AS ShareOfEntireEconomyPct,
    DENSE_RANK() OVER (ORDER BY c.MarketCap DESC) AS OverallEconomicRank
FROM COMPANY c
JOIN SECTOR s ON c.SectorID = s.SectorID
ORDER BY c.MarketCap DESC;


-- ==============================================================================
-- QUERY 4: MENTOR-MENTEE SYNERGY & WIN RATE SPREAD (Self-Join)
-- Concept: Self-referential join on INVESTOR table evaluating generational talent
-- Business Value: Analyzes whether apprentices are outperforming their mentors,
--                 calculating the win rate differential and combined wealth.
-- ==============================================================================
SELECT 
    m.InvestorID AS MentorID,
    CONCAT(m.FirstName, ' ', m.LastName) AS MentorName,
    m.WinRate AS MentorWinRate,
    m.TotalBattles AS MentorBattles,
    a.InvestorID AS ApprenticeID,
    CONCAT(a.FirstName, ' ', a.LastName) AS ApprenticeName,
    a.WinRate AS ApprenticeWinRate,
    a.TotalBattles AS ApprenticeBattles,
    ROUND(a.WinRate - m.WinRate, 2) AS WinRateDifferential,
    CASE 
        WHEN a.WinRate > m.WinRate THEN '🔥 Apprentice Outperformed Mentor'
        WHEN a.WinRate = m.WinRate THEN '⚖️ Parity'
        ELSE '🛡️ Mentor Retains Superiority'
    END AS MentorshipDynamic,
    ROUND(m.Wallet + a.Wallet, 2) AS CombinedDynastyWealth
FROM INVESTOR a
INNER JOIN INVESTOR m ON a.MentorID = m.InvestorID
ORDER BY WinRateDifferential DESC;


-- ==============================================================================
-- QUERY 5: BATTLE COMBAT IMPACT ON CORPORATE SPONSORS (Quaternary Traversal)
-- Concept: Deep multi-entity traversal across INVESTOR_PRODUCT_FIGHT_REWARD,
--          PRODUCT, COMPANY, STOCK, and FIGHT.
-- Business Value: Quantifies how weapon & potion usage in mortal combat directly
--                 generates reward revenue and moves corporate sponsor equity.
-- ==============================================================================
SELECT 
    p.Name AS ProductName,
    p.Type AS ProductType,
    c.Name AS Manufacturer,
    s.Symbol AS StockTicker,
    COUNT(DISTINCT r.FightID) AS CombatEngagements,
    COUNT(DISTINCT r.InvestorID) AS DistinctSlayersEquipped,
    SUM(r.RewardAmount) AS TotalCombatRewardsYielded,
    ROUND(AVG(r.RewardAmount), 2) AS AverageRewardPerBattle,
    s.BaseValue AS CurrentStockPrice
FROM INVESTOR_PRODUCT_FIGHT_REWARD r
JOIN PRODUCT p ON r.ProductID = p.ProductID
JOIN COMPANY c ON p.CompanyID = c.CompanyID
LEFT JOIN STOCK s ON r.StockID = s.StockID
GROUP BY p.ProductID, p.Name, p.Type, c.Name, s.Symbol, s.BaseValue
ORDER BY TotalCombatRewardsYielded DESC;


-- ==============================================================================
-- QUERY 6: INVESTOR RISK-CAPITAL ALLOCATION MATRIX (Conditional Pivot)
-- Concept: CASE WHEN aggregation pivoting risk exposure into tabular matrix
-- Business Value: Classifies each investor's portfolio allocation into Conservative
--                 (Risk 1-5), Moderate (Risk 6-7), and High Speculation (Risk 8-10).
-- ==============================================================================
SELECT 
    i.InvestorID,
    CONCAT(i.FirstName, ' ', i.LastName) AS InvestorName,
    i.Type AS Faction,
    COALESCE(SUM(CASE WHEN sec.RiskLevel <= 5 THEN p.Quantity * stk.BaseValue ELSE 0 END), 0) AS LowRiskCapital,
    COALESCE(SUM(CASE WHEN sec.RiskLevel BETWEEN 6 AND 7 THEN p.Quantity * stk.BaseValue ELSE 0 END), 0) AS MediumRiskCapital,
    COALESCE(SUM(CASE WHEN sec.RiskLevel >= 8 THEN p.Quantity * stk.BaseValue ELSE 0 END), 0) AS HighRiskSpeculationCapital,
    COALESCE(SUM(p.Quantity * stk.BaseValue), 0) AS TotalStockAssets,
    ROUND(
        CASE 
            WHEN SUM(p.Quantity * stk.BaseValue) > 0 
            THEN (SUM(CASE WHEN sec.RiskLevel >= 8 THEN p.Quantity * stk.BaseValue ELSE 0 END) / SUM(p.Quantity * stk.BaseValue)) * 100
            ELSE 0 
        END, 1
    ) AS HighRiskExposurePct
FROM INVESTOR i
LEFT JOIN PORTFOLIO p ON i.InvestorID = p.InvestorID
LEFT JOIN STOCK stk ON p.StockID = stk.StockID
LEFT JOIN COMPANY c ON stk.CompanyID = c.CompanyID
LEFT JOIN SECTOR sec ON c.SectorID = sec.SectorID
GROUP BY i.InvestorID, i.FirstName, i.LastName, i.Type
HAVING TotalStockAssets > 0
ORDER BY HighRiskExposurePct DESC;


-- ==============================================================================
-- QUERY 7: MAGIC SPELL MARKET MANIPULATION EFFICIENCY (Ternary Analysis)
-- Concept: Traversal of ternary relationship CASTS_SPELL_ON joined with MAGIC_SPELL
-- Business Value: Evaluates how magic spells manipulated stock values relative to
--                 the energy / power consumed.
-- ==============================================================================
SELECT 
    ms.SpellID,
    ms.Name AS SpellName,
    ms.EffectType,
    CONCAT(i.FirstName, ' ', i.LastName) AS CasterName,
    stk.Symbol AS TargetStockSymbol,
    c.Name AS AffectedCompany,
    cso.EffectDuration AS DurationDays,
    cso.PowerConsumption,
    ROUND((cso.EffectDuration * 100.0) / NULLIF(cso.PowerConsumption, 0), 2) AS PowerEfficiencyRatio
FROM CASTS_SPELL_ON cso
JOIN MAGIC_SPELL ms ON cso.SpellID = ms.SpellID
JOIN INVESTOR i ON cso.InvestorID = i.InvestorID
JOIN STOCK stk ON cso.StockID = stk.StockID
JOIN COMPANY c ON stk.CompanyID = c.CompanyID
ORDER BY PowerEfficiencyRatio DESC;


-- ==============================================================================
-- QUERY 8: HASHIRA COMBAT TECHNIQUE SUPREMACY (Weak Entity & Subclass Join)
-- Concept: Joins HASHIRA, HASHIRA_BREATHING_TECHNIQUES, and FIGHT_SCORE
-- Business Value: Analyzes which breathing style forms produced the highest combat
--                 scores and financial rewards in official battles.
-- ==============================================================================
SELECT 
    h.BreathingTechnique AS PrimaryStyle,
    COUNT(DISTINCT h.InvestorID) AS HashiraCount,
    COUNT(fs.FightID) AS CombatAppearances,
    ROUND(AVG(fs.Score), 2) AS AverageCombatScore,
    ROUND(MAX(fs.Score), 2) AS PeakCombatScore,
    SUM(fs.Rewards) AS TotalBattleRewardsEarned
FROM HASHIRA h
JOIN INVESTOR i ON h.InvestorID = i.InvestorID
LEFT JOIN FIGHT_SCORE fs ON h.InvestorID = fs.InvestorID
GROUP BY h.BreathingTechnique
ORDER BY AverageCombatScore DESC;


-- ==============================================================================
-- QUERY 9: CUMULATIVE TRADE VOLUME & OUTLIER DETECTION (Window Functions)
-- Concept: Running totals and comparisons against investor historical averages
-- Business Value: Audit trail identifying transaction surges and unusual order sizes.
-- ==============================================================================
WITH TradeAnalytics AS (
    SELECT 
        tr.TransactionID,
        tr.InvestorID,
        CONCAT(i.FirstName, ' ', i.LastName) AS InvestorName,
        tr.StockID,
        s.Symbol,
        tr.TransactionType,
        tr.Quantity,
        tr.PricePerShare,
        tr.TotalValue,
        tr.TransactionDate,
        AVG(tr.TotalValue) OVER (PARTITION BY tr.InvestorID) AS InvestorAvgTradeVal,
        SUM(tr.TotalValue) OVER (
            PARTITION BY tr.InvestorID 
            ORDER BY tr.TransactionDate 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeCapitalCommitted
    FROM TRANSACTION_RECORD tr
    JOIN INVESTOR i ON tr.InvestorID = i.InvestorID
    JOIN STOCK s ON tr.StockID = s.StockID
)
SELECT 
    ta.TransactionID,
    ta.InvestorName,
    ta.Symbol,
    ta.TransactionType,
    ta.Quantity,
    ta.TotalValue,
    ROUND(ta.CumulativeCapitalCommitted, 2) AS RunningTotalSpend,
    ROUND(ta.InvestorAvgTradeVal, 2) AS HistoricalAverageTrade,
    CASE 
        WHEN ta.TotalValue > (ta.InvestorAvgTradeVal * 1.5) THEN '🚨 High-Value Outlier'
        ELSE 'Standard Execution'
    END AS TradeClassification
FROM TradeAnalytics ta
ORDER BY ta.TotalValue DESC;


-- ==============================================================================
-- QUERY 10: MARKET CATALYST CORRELATION (Battle Outcome vs News Sentiment)
-- Concept: Correlates battle severity with financial news and stock swings
-- Business Value: Measures news volatility generated by battle impact levels.
-- ==============================================================================
SELECT 
    ne.ImpactLevel,
    ne.WinnerType,
    COUNT(ne.NewsID) AS TotalNewsEvents,
    ROUND(AVG(ne.StockEffect), 2) AS AvgStockEffectPct,
    ROUND(MIN(ne.StockEffect), 2) AS MinStockEffectPct,
    ROUND(MAX(ne.StockEffect), 2) AS MaxStockEffectPct,
    GROUP_CONCAT(DISTINCT f.Location ORDER BY f.Location SEPARATOR ', ') AS BattleLocations
FROM NEWS_EFFECT ne
JOIN FIGHT f ON ne.FightID = f.FightID
GROUP BY ne.ImpactLevel, ne.WinnerType
ORDER BY AvgStockEffectPct DESC;


-- ==============================================================================
-- QUERY 11: UNMATCHED LIQUIDITY & MARKET GAPS (LEFT JOIN with IS NULL)
-- Concept: Outer join pattern detecting idle economic assets
-- Business Value: Discovers companies without registered products or listed stocks.
-- ==============================================================================
SELECT 
    c.CompanyID,
    c.Name AS CompanyName,
    s.Name AS SectorName,
    c.MarketCap,
    CASE 
        WHEN stk.StockID IS NULL THEN '⚠️ No Public Stock Issued'
        ELSE 'Active Stock'
    END AS StockStatus,
    CASE 
        WHEN prd.ProductID IS NULL THEN '⚠️ Zero Product Lines'
        ELSE 'Active Products'
    END AS ProductStatus
FROM COMPANY c
JOIN SECTOR s ON c.SectorID = s.SectorID
LEFT JOIN STOCK stk ON c.CompanyID = stk.CompanyID
LEFT JOIN PRODUCT prd ON c.CompanyID = prd.CompanyID
WHERE stk.StockID IS NULL OR prd.ProductID IS NULL
GROUP BY c.CompanyID, c.Name, s.Name, c.MarketCap, stk.StockID, prd.ProductID;


-- ==============================================================================
-- QUERY 12: ULTIMATE NET WORTH LEADERBOARD (Comprehensive Multi-Table CTE)
-- Concept: Unifies liquid cash, stock portfolio value, and combat earnings
-- Business Value: Crown the undisputed financial titan in the Demon Slayer universe.
-- ==============================================================================
WITH InvestorStockHoldings AS (
    SELECT 
        p.InvestorID,
        COALESCE(SUM(p.Quantity * s.BaseValue), 0.00) AS StockPortfolioValue
    FROM PORTFOLIO p
    JOIN STOCK s ON p.StockID = s.StockID
    GROUP BY p.InvestorID
),
InvestorCombatRewards AS (
    SELECT 
        fs.InvestorID,
        COALESCE(SUM(fs.Rewards), 0.00) AS TotalBattleRewardsWon
    FROM FIGHT_SCORE fs
    GROUP BY fs.InvestorID
)
SELECT 
    i.InvestorID,
    CONCAT(i.FirstName, ' ', i.LastName) AS InvestorName,
    i.Type AS Faction,
    i.Wallet AS LiquidCash,
    COALESCE(ish.StockPortfolioValue, 0.00) AS EquityHoldingsValue,
    COALESCE(icr.TotalBattleRewardsWon, 0.00) AS TotalCombatEarnings,
    ROUND(i.Wallet + COALESCE(ish.StockPortfolioValue, 0.00), 2) AS TotalNetWorth,
    DENSE_RANK() OVER (ORDER BY (i.Wallet + COALESCE(ish.StockPortfolioValue, 0.00)) DESC) AS OverallWealthRank
FROM INVESTOR i
LEFT JOIN InvestorStockHoldings ish ON i.InvestorID = ish.InvestorID
LEFT JOIN InvestorCombatRewards icr ON i.InvestorID = icr.InvestorID
ORDER BY TotalNetWorth DESC;

