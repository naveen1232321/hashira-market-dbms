"""
queries.py
SQL queries repository and business logic implementations for Hashira Market DBMS.
All operations execute parameterized raw SQL queries adhering to ACID principles.
"""
from datetime import date, datetime
from decimal import Decimal
from src.db import print_rows

# ==============================================================================
# READ QUERIES (8 Distinct Operations)
# ==============================================================================

def q1_list_all_investors(conn):
    """Query 1: List all investors with their type, wallet balance, and win rates."""
    sql = """
        SELECT 
            InvestorID, 
            CONCAT(FirstName, ' ', LastName) AS FullName, 
            Type, 
            Wallet, 
            JoinDate, 
            TotalBattles, 
            WinRate
        FROM INVESTOR
        ORDER BY InvestorID;
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    print_rows(rows, "All Investors (Demon Slayers & Demons)")
    return rows

def q2_list_companies_with_sector(conn):
    """Query 2: List companies with their industry sector and risk information."""
    sql = """
        SELECT 
            c.CompanyID, 
            c.Name AS CompanyName, 
            c.CEO, 
            c.MarketCap, 
            s.Name AS SectorName, 
            s.RiskLevel
        FROM COMPANY c
        LEFT JOIN SECTOR s ON c.SectorID = s.SectorID
        ORDER BY c.MarketCap DESC;
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    print_rows(rows, "Companies & Sector Risk Profiles")
    return rows

def q3_list_stocks_with_company(conn):
    """Query 3: List all stocks with company details and current valuations."""
    sql = """
        SELECT 
            s.StockID, 
            s.Symbol, 
            s.Name AS StockName, 
            s.BaseValue, 
            c.Name AS CompanyName, 
            c.MarketCap
        FROM STOCK s
        LEFT JOIN COMPANY c ON s.CompanyID = c.CompanyID
        ORDER BY s.Symbol;
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    print_rows(rows, "Listed Stocks & Parent Companies")
    return rows

def q4_recent_fights_with_news(conn, limit=15):
    """Query 4: Recent fights joined with combatants and resulting market news effects."""
    sql = """
        SELECT 
            f.FightID, 
            f.Location, 
            CONCAT(i1.FirstName, ' ', i1.LastName) AS WinnerName,
            CONCAT(i2.FirstName, ' ', i2.LastName) AS LoserName,
            ne.NewsID, 
            ne.Description AS MarketNews, 
            ne.StockEffect AS EffectPct, 
            ne.ImpactLevel
        FROM FIGHT f
        LEFT JOIN INVESTOR i1 ON f.WinnerInvestorID = i1.InvestorID
        LEFT JOIN INVESTOR i2 ON f.LoserInvestorID = i2.InvestorID
        LEFT JOIN NEWS_EFFECT ne ON f.FightID = ne.FightID
        ORDER BY f.FightID DESC
        LIMIT %s;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (limit,))
        rows = cur.fetchall()
    print_rows(rows, f"Recent {limit} Battles & Generated Market News")
    return rows

def q5_portfolio_for_investor(conn, investor_id):
    """Query 5: View full stock portfolio holdings for a specific investor."""
    sql_check = "SELECT InvestorID, FirstName, LastName, Wallet FROM INVESTOR WHERE InvestorID = %s;"
    with conn.cursor() as cur:
        cur.execute(sql_check, (investor_id,))
        investor = cur.fetchone()
        if not investor:
            print(f"\n[WARNING] Investor '{investor_id}' was not found in the database.\n")
            return None

    sql = """
        SELECT 
            p.InvestorID, 
            CONCAT(i.FirstName, ' ', i.LastName) AS InvestorName,
            p.StockID, 
            s.Symbol, 
            s.Name AS StockName,
            p.Quantity, 
            p.PurchasePrice, 
            s.BaseValue AS CurrentMarketPrice,
            ROUND(p.Quantity * p.PurchasePrice, 2) AS CostBasis,
            ROUND(p.Quantity * s.BaseValue, 2) AS CurrentValue,
            p.PurchaseDate
        FROM PORTFOLIO p
        JOIN INVESTOR i ON p.InvestorID = i.InvestorID
        JOIN STOCK s ON p.StockID = s.StockID
        WHERE p.InvestorID = %s
        ORDER BY p.StockID;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (investor_id,))
        rows = cur.fetchall()
    print_rows(rows, f"Portfolio Holdings for {investor['FirstName']} {investor['LastName']} ({investor_id})")
    return rows

def q6_power_tier_leaderboard(conn):
    """Query 6: Analytical Window Functions (DENSE_RANK, PERCENT_RANK, Running Wealth)."""
    sql = """
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
            i.Wallet AS LiquidCash
        FROM INVESTOR i
        WHERE i.TotalBattles > 0
        ORDER BY i.Type, FactionCombatRank;
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    print_rows(rows, "Combatant Power Tier Leaderboard (Window Functions)")
    return rows

def q7_portfolio_unrealized_roi(conn):
    """Query 7: Multi-Level CTE calculating portfolio ROI, yield %, and total net worth."""
    sql = """
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
            i.Type AS Faction,
            i.Wallet AS CashBalance,
            iha.PositionsHeld,
            iha.TotalInvested,
            iha.PortfolioValuation,
            iha.TotalUnrealizedGain,
            iha.YieldPct,
            ROUND(i.Wallet + iha.PortfolioValuation, 2) AS EstimatedNetWorth
        FROM InvestorHoldingsAgg iha
        JOIN INVESTOR i ON iha.InvestorID = i.InvestorID
        ORDER BY EstimatedNetWorth DESC;
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    print_rows(rows, "Investor Net Worth & Portfolio Yield (CTE Analytics)")
    return rows

def q8_mentor_mentee_synergy(conn):
    """Query 8: Self-join evaluating mentor-apprentice combat and wealth dynamics."""
    sql = """
        SELECT 
            m.InvestorID AS MentorID,
            CONCAT(m.FirstName, ' ', m.LastName) AS MentorName,
            m.WinRate AS MentorWinRate,
            a.InvestorID AS ApprenticeID,
            CONCAT(a.FirstName, ' ', a.LastName) AS ApprenticeName,
            a.WinRate AS ApprenticeWinRate,
            ROUND(a.WinRate - m.WinRate, 2) AS WinRateDifferential,
            CASE 
                WHEN a.WinRate > m.WinRate THEN '🔥 Apprentice Outperformed'
                WHEN a.WinRate = m.WinRate THEN '⚖️ Parity'
                ELSE '🛡️ Mentor Superiority'
            END AS DynamicStatus,
            ROUND(m.Wallet + a.Wallet, 2) AS CombinedDynastyCash
        FROM INVESTOR a
        INNER JOIN INVESTOR m ON a.MentorID = m.InvestorID
        ORDER BY WinRateDifferential DESC;
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    print_rows(rows, "Mentor-Apprentice Synergy & Wealth Spread (Self-Join)")
    return rows


# ==============================================================================
# WRITE OPERATIONS (4 Core Operations with Before/After Verification)
# ==============================================================================

def w1_insert_fight_and_news(conn, fight_id, location, winner_id, loser_id, 
                             skills_used=None, products_used=None, news_id=None, 
                             winner_type="Hero", news_desc=None, stock_effect=0.0, impact_level="Medium"):
    """
    Write Op 1: Insert new fight and create corresponding news effect.
    Demonstrates transaction atomicity and multi-table INSERT.
    """
    winner_type = winner_type.strip().capitalize()
    if winner_type not in ['Hero', 'Villain', 'Demon']:
        winner_type = 'Hero'

    # 1. Inspect Before State
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM FIGHT WHERE FightID = %s;", (fight_id,))
        before_fight = cur.fetchall()
        cur.execute("SELECT * FROM NEWS_EFFECT WHERE NewsID = %s;", (news_id,))
        before_news = cur.fetchall()
    
    print_rows(before_fight, f"FIGHT Before Insertion ({fight_id})")
    print_rows(before_news, f"NEWS_EFFECT Before Insertion ({news_id})")

    # 2. Execute Insert Transaction
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO FIGHT (FightID, Location, WinnerInvestorID, LoserInvestorID, SkillsUsed, ProductsUsed)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (fight_id, location, winner_id, loser_id, skills_used, products_used))
            
            cur.execute("""
                INSERT INTO NEWS_EFFECT (NewsID, FightID, WinnerType, Description, StockEffect, ImpactLevel)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (news_id, fight_id, winner_type, news_desc, stock_effect, impact_level))
        
        conn.commit()
        print(f"✓ Successfully inserted fight '{fight_id}' and news '{news_id}'.")
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] w1_insert_fight_and_news failed: {e}")
        return False

    # 3. Inspect After State
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM FIGHT WHERE FightID = %s;", (fight_id,))
        after_fight = cur.fetchall()
        cur.execute("SELECT * FROM NEWS_EFFECT WHERE NewsID = %s;", (news_id,))
        after_news = cur.fetchall()

    print_rows(after_fight, f"FIGHT After Insertion ({fight_id})")
    print_rows(after_news, f"NEWS_EFFECT After Insertion ({news_id})")
    return True

def w2_buy_stock(conn, investor_id, stock_id, quantity, price_per_share):
    """
    Write Op 2: Execute stock purchase.
    Inserts transaction record, debits wallet, and upserts portfolio holdings.
    """
    total_val = round(quantity * price_per_share, 2)
    tx_id = f"TX{int(datetime.now().timestamp())}"

    # 1. Inspect Before State
    with conn.cursor() as cur:
        cur.execute("SELECT InvestorID, FirstName, LastName, Wallet FROM INVESTOR WHERE InvestorID = %s;", (investor_id,))
        before_wallet = cur.fetchall()
        cur.execute("SELECT * FROM PORTFOLIO WHERE InvestorID = %s AND StockID = %s;", (investor_id, stock_id))
        before_portfolio = cur.fetchall()

    print_rows(before_wallet, f"Investor Wallet Before Purchase ({investor_id})")
    print_rows(before_portfolio, f"Portfolio Holdings Before Purchase ({investor_id}, {stock_id})")

    # 2. Execute Transaction
    try:
        with conn.cursor() as cur:
            # Insert Transaction Record
            cur.execute("""
                INSERT INTO TRANSACTION_RECORD 
                (TransactionID, InvestorID, StockID, TransactionType, Quantity, PricePerShare, TotalValue)
                VALUES (%s, %s, %s, 'Buy', %s, %s, %s);
            """, (tx_id, investor_id, stock_id, quantity, price_per_share, total_val))
            
            # Debit Wallet
            cur.execute("""
                UPDATE INVESTOR SET Wallet = Wallet - %s WHERE InvestorID = %s;
            """, (total_val, investor_id))
            
            # Upsert Portfolio
            cur.execute("""
                SELECT Quantity FROM PORTFOLIO WHERE InvestorID = %s AND StockID = %s FOR UPDATE;
            """, (investor_id, stock_id))
            existing = cur.fetchone()

            if existing:
                new_qty = existing['Quantity'] + quantity
                cur.execute("""
                    UPDATE PORTFOLIO 
                    SET Quantity = %s, PurchasePrice = %s, PurchaseDate = %s
                    WHERE InvestorID = %s AND StockID = %s;
                """, (new_qty, price_per_share, date.today(), investor_id, stock_id))
            else:
                cur.execute("""
                    INSERT INTO PORTFOLIO (InvestorID, StockID, Quantity, PurchasePrice, PurchaseDate)
                    VALUES (%s, %s, %s, %s, %s);
                """, (investor_id, stock_id, quantity, price_per_share, date.today()))
        
        conn.commit()
        print(f"✓ Purchase completed! TransactionID: {tx_id}, Cost: {total_val}")
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] w2_buy_stock failed: {e}")
        return False

    # 3. Inspect After State
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM TRANSACTION_RECORD WHERE TransactionID = %s;", (tx_id,))
        after_tx = cur.fetchall()
        cur.execute("SELECT InvestorID, FirstName, LastName, Wallet FROM INVESTOR WHERE InvestorID = %s;", (investor_id,))
        after_wallet = cur.fetchall()
        cur.execute("SELECT * FROM PORTFOLIO WHERE InvestorID = %s AND StockID = %s;", (investor_id, stock_id))
        after_portfolio = cur.fetchall()

    print_rows(after_tx, f"New Transaction Record ({tx_id})")
    print_rows(after_wallet, f"Investor Wallet After Purchase ({investor_id})")
    print_rows(after_portfolio, f"Portfolio Holdings After Purchase ({investor_id}, {stock_id})")
    return True

def w3_update_company_marketcap(conn, company_id, new_market_cap):
    """
    Write Op 3: Update company market capitalization.
    Triggers automated audit logging if triggers are active.
    """
    # 1. Inspect Before State
    with conn.cursor() as cur:
        cur.execute("SELECT CompanyID, Name, CEO, MarketCap FROM COMPANY WHERE CompanyID = %s;", (company_id,))
        before_comp = cur.fetchall()
    print_rows(before_comp, f"Company Before MarketCap Update ({company_id})")

    # 2. Execute Update
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE COMPANY SET MarketCap = %s WHERE CompanyID = %s;", (new_market_cap, company_id))
        conn.commit()
        print(f"✓ MarketCap for {company_id} updated to {new_market_cap:,.2f}.")
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] w3_update_company_marketcap failed: {e}")
        return False

    # 3. Inspect After State
    with conn.cursor() as cur:
        cur.execute("SELECT CompanyID, Name, CEO, MarketCap FROM COMPANY WHERE CompanyID = %s;", (company_id,))
        after_comp = cur.fetchall()
    print_rows(after_comp, f"Company After MarketCap Update ({company_id})")
    return True

def w4_delete_fight(conn, fight_id):
    """
    Write Op 4: Delete a fight record.
    Demonstrates ON DELETE CASCADE removing associated NEWS_EFFECT records.
    """
    # 1. Inspect Before State
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM FIGHT WHERE FightID = %s;", (fight_id,))
        before_fight = cur.fetchall()
        cur.execute("SELECT * FROM NEWS_EFFECT WHERE FightID = %s;", (fight_id,))
        before_news = cur.fetchall()

    print_rows(before_fight, f"FIGHT Before Deletion ({fight_id})")
    print_rows(before_news, f"NEWS_EFFECT Records Associated with ({fight_id}) Before Deletion")

    # 2. Execute Delete
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM FIGHT WHERE FightID = %s;", (fight_id,))
        conn.commit()
        print(f"✓ Deleted fight '{fight_id}' and all cascaded news effects.")
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] w4_delete_fight failed: {e}")
        return False

    # 3. Inspect After State
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM FIGHT WHERE FightID = %s;", (fight_id,))
        after_fight = cur.fetchall()
        cur.execute("SELECT * FROM NEWS_EFFECT WHERE FightID = %s;", (fight_id,))
        after_news = cur.fetchall()

    print_rows(after_fight, f"FIGHT After Deletion ({fight_id} - should be empty)")
    print_rows(after_news, f"NEWS_EFFECT After Cascade Deletion ({fight_id} - should be empty)")
    return True

