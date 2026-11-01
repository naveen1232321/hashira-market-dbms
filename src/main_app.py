#!/usr/bin/env python3
"""
main_app.py
Hashira Market: Demon Slayer Stock Trading Database CLI
Phase 4 - Data and Applications (DnA 2025)

Features:
  - 8 Comprehensive Read Queries (Basic + Analytical Window Functions + CTEs)
  - 4 ACID Write Operations (Multi-table INSERT, Atomic Stock Purchase, UPDATE, CASCADE DELETE)
  - Before/After state inspections for every write operation
  - Robust parameterization and error handling
"""

import sys
import os
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Add project root to sys.path to support execution from any directory
root_dir = Path(__file__).resolve().parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from src.db import get_connection, print_rows
from src.queries import (
    q1_list_all_investors,
    q2_list_companies_with_sector,
    q3_list_stocks_with_company,
    q4_recent_fights_with_news,
    q5_portfolio_for_investor,
    q6_power_tier_leaderboard,
    q7_portfolio_unrealized_roi,
    q8_mentor_mentee_synergy,
    w1_insert_fight_and_news,
    w2_buy_stock,
    w3_update_company_marketcap,
    w4_delete_fight
)

BANNER = r"""
========================================================================
⚔️  HASHIRA MARKET: DEMON SLAYER STOCK TRADING ENGINE  ⚔️
            Relational Database Management System (Phase 4)
========================================================================
"""

def show_main_menu():
    print("\n" + "="*50)
    print("  MAIN MENU - HASHIRA MARKET CLI")
    print("="*50)
    print("  R) Read Queries (8 distinct operations)")
    print("  W) Write Operations (4 operations with Before/After)")
    print("  X) Exit System")
    print("="*50)

def show_read_menu():
    print("\n--- READ QUERIES (R MENU) ---")
    print("  1. List all investors (types, wallets, win rates)")
    print("  2. List companies with sector & risk profiles")
    print("  3. List stocks with issuer company details")
    print("  4. Recent fights with generated market news")
    print("  5. View portfolio holdings for an investor")
    print("  6. Power tier leaderboard (Window Functions: DENSE_RANK)")
    print("  7. Portfolio ROI & Net Worth (Multi-level CTE)")
    print("  8. Mentor-Mentee synergy & wealth spread (Self-Join)")
    print("  B. Back to Main Menu")

def show_write_menu():
    print("\n--- WRITE OPERATIONS (W MENU) ---")
    print("  1. Insert new fight & create market news (Multi-table INSERT)")
    print("  2. Buy stock (Debit wallet + upsert portfolio + log transaction)")
    print("  3. Update company MarketCap (Triggers audit logging)")
    print("  4. Delete fight (Demonstrates ON DELETE CASCADE to news)")
    print("  B. Back to Main Menu")


def handle_read_queries(conn):
    while True:
        show_read_menu()
        choice = input("Select Read Query (1-8 or B): ").strip().upper()

        if choice == '1':
            q1_list_all_investors(conn)
        elif choice == '2':
            q2_list_companies_with_sector(conn)
        elif choice == '3':
            q3_list_stocks_with_company(conn)
        elif choice == '4':
            q4_recent_fights_with_news(conn)
        elif choice == '5':
            iid = input("Enter InvestorID (e.g. INV001): ").strip().upper()
            if iid:
                q5_portfolio_for_investor(conn, iid)
            else:
                print("InvestorID is required.")
        elif choice == '6':
            q6_power_tier_leaderboard(conn)
        elif choice == '7':
            q7_portfolio_unrealized_roi(conn)
        elif choice == '8':
            q8_mentor_mentee_synergy(conn)
        elif choice == 'B':
            break
        else:
            print("[!] Invalid option. Please select between 1 and 8, or B.")


def handle_write_operations(conn):
    while True:
        show_write_menu()
        choice = input("Select Write Operation (1-4 or B): ").strip().upper()

        if choice == '1':
            print("\n--- Write Op 1: Insert Fight & Market News ---")
            fid = input("New FightID (e.g. F020): ").strip()
            loc = input("Location (e.g. Mount Natagumo Arena): ").strip()
            winner = input("WinnerInvestorID (e.g. INV001): ").strip()
            loser = input("LoserInvestorID (e.g. INV005): ").strip()
            skills = input("SkillsUsed (optional): ").strip() or None
            products = input("ProductsUsed (optional): ").strip() or None
            news_id = input("NewsID (e.g. NEWS020): ").strip()
            winner_type = input("WinnerType (Hero/Villain/Demon) [default Hero]: ").strip() or "Hero"
            desc = input("News Description: ").strip() or "Battle outcome shook investor sentiment."
            try:
                effect = float(input("Stock Effect % (e.g. 5.50): ").strip() or "0.0")
            except ValueError:
                effect = 0.0
            impact = input("Impact Level (Low/Medium/High/Critical) [default Medium]: ").strip() or "Medium"

            w1_insert_fight_and_news(conn, fid, loc, winner, loser, skills, products, news_id, winner_type, desc, effect, impact)

        elif choice == '2':
            print("\n--- Write Op 2: Buy Stock ---")
            inv = input("InvestorID (e.g. INV001): ").strip()
            stock = input("StockID (e.g. STK005): ").strip()
            try:
                qty = int(input("Quantity to purchase: ").strip())
                price = float(input("Price per share: ").strip())
                if qty <= 0 or price <= 0:
                    print("[!] Quantity and price must be greater than zero.")
                    continue
                w2_buy_stock(conn, inv, stock, qty, price)
            except ValueError:
                print("[!] Invalid numeric inputs.")

        elif choice == '3':
            print("\n--- Write Op 3: Update Company MarketCap ---")
            cid = input("CompanyID (e.g. CMP001): ").strip()
            try:
                new_cap = float(input("New MarketCap value (e.g. 6000000000.00): ").strip())
                w3_update_company_marketcap(conn, cid, new_cap)
            except ValueError:
                print("[!] Invalid numeric input for MarketCap.")

        elif choice == '4':
            print("\n--- Write Op 4: Delete Fight (with Cascade) ---")
            fid = input("FightID to delete (e.g. F020): ").strip()
            confirm = input(f"Type 'DELETE' to confirm removal of {fid}: ").strip()
            if confirm == "DELETE":
                w4_delete_fight(conn, fid)
            else:
                print("[*] Deletion aborted.")

        elif choice == 'B':
            break
        else:
            print("[!] Invalid option. Please select between 1 and 4, or B.")


def main():
    print(BANNER)
    print("Initiating connection to MySQL database...")

    conn = get_connection()
    if not conn:
        print("\nCould not automatically connect with default/environment credentials.")
        prompt_choice = input("Would you like to manually enter MySQL credentials? (y/n): ").strip().lower()
        if prompt_choice == 'y':
            from getpass import getpass
            from src.config import DatabaseConfig
            host = input(f"Host [{DatabaseConfig.HOST}]: ").strip() or DatabaseConfig.HOST
            port_str = input(f"Port [{DatabaseConfig.PORT}]: ").strip() or str(DatabaseConfig.PORT)
            user = input(f"User [{DatabaseConfig.USER}]: ").strip() or DatabaseConfig.USER
            password = getpass("Password: ")
            database = input(f"Database [{DatabaseConfig.DATABASE}]: ").strip() or DatabaseConfig.DATABASE
            try:
                port = int(port_str)
            except ValueError:
                port = 3306
            conn = get_connection(host=host, port=port, user=user, password=password, database=database)

    if not conn:
        print("\n[!] Could not establish database connection. Application exiting.")
        print("    Ensure your MySQL service is active and the database is created.")
        sys.exit(1)

    print("✓ Successfully connected to Mini World database.")

    try:
        while True:
            show_main_menu()
            choice = input("Enter choice (R, W, X): ").strip().upper()

            if choice == 'R':
                handle_read_queries(conn)
            elif choice == 'W':
                handle_write_operations(conn)
            elif choice == 'X':
                print("\n👋 Exiting Hashira Market DBMS. Happy Trading!\n")
                break
            else:
                print("[!] Invalid choice. Please enter R, W, or X.")
    finally:
        conn.close()
        print("✓ Database connection gracefully closed.")


if __name__ == "__main__":
    main()
