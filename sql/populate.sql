-- ============================================
-- populate.sql
-- Comprehensive data population for mini_world_db
-- ============================================

USE mini_world_db;

-- ============================================
-- 1. SECTOR DATA
-- ============================================
INSERT INTO SECTOR (SectorID, Name, Description, RiskLevel, Created_Date) VALUES
('SEC001', 'Technology', 'Tech companies developing demon-slaying gadgets', 8, '2020-01-15'),
('SEC002', 'Finance', 'Financial institutions funding demon hunters', 5, '2019-03-22'),
('SEC003', 'Healthcare', 'Medical facilities treating injured slayers', 6, '2018-07-10'),
('SEC004', 'Defense', 'Weapon manufacturing and armor production', 9, '2017-11-05'),
('SEC005', 'Energy', 'Power generation for magic spells', 7, '2021-02-28');

-- ============================================
-- 2. INVESTOR DATA (with mentor relationships)
-- ============================================
INSERT INTO INVESTOR (InvestorID, FirstName, LastName, Type, MentorID, Wallet, JoinDate, TotalBattles, WinRate) VALUES
-- Senior Demon Slayers (no mentors)
('INV001', 'Tanjiro', 'Kamado', 'Demon slayer', NULL, 150000.00, '2018-04-01', 45, 88.89),
('INV002', 'Giyu', 'Tomioka', 'Demon slayer', NULL, 280000.00, '2015-01-10', 67, 92.54),
('INV003', 'Shinobu', 'Kocho', 'Demon slayer', NULL, 195000.00, '2016-08-15', 52, 86.54),
('INV004', 'Kyojuro', 'Rengoku', 'Demon slayer', NULL, 320000.00, '2014-03-20', 78, 94.87),

-- Junior Demon Slayers (with mentors)
('INV005', 'Zenitsu', 'Agatsuma', 'Demon slayer', 'INV001', 75000.00, '2019-06-12', 28, 75.00),
('INV006', 'Inosuke', 'Hashibira', 'Demon slayer', 'INV001', 82000.00, '2019-07-01', 31, 80.65),
('INV007', 'Kanao', 'Tsuyuri', 'Demon slayer', 'INV003', 105000.00, '2018-11-20', 39, 84.62),
('INV008', 'Genya', 'Shinazugawa', 'Demon slayer', 'INV002', 68000.00, '2020-02-14', 22, 72.73),

-- Upper Rank Demons (villains)
('INV009', 'Muzan', 'Kibutsuji', 'Demon', NULL, 500000.00, '2013-01-01', 95, 96.84),
('INV010', 'Kokushibo', 'Upper1', 'Demon', 'INV009', 420000.00, '2014-06-15', 72, 94.44),
('INV011', 'Doma', 'Upper2', 'Demon', 'INV009', 380000.00, '2015-09-20', 65, 92.31),
('INV012', 'Akaza', 'Upper3', 'Demon', 'INV009', 340000.00, '2016-04-10', 58, 89.66),
('INV013', 'Gyutaro', 'Upper6', 'Demon', 'INV009', 280000.00, '2017-12-25', 49, 85.71),

-- More Investors
('INV014', 'Mitsuri', 'Kanroji', 'Demon slayer', NULL, 165000.00, '2017-05-08', 44, 86.36),
('INV015', 'Tengen', 'Uzui', 'Demon slayer', NULL, 245000.00, '2015-11-30', 61, 90.16),
('INV016', 'Sanemi', 'Shinazugawa', 'Demon slayer', NULL, 210000.00, '2016-02-14', 55, 89.09),
('INV017', 'Muichiro', 'Tokito', 'Demon slayer', NULL, 135000.00, '2019-01-22', 36, 83.33),
('INV018', 'Gyomei', 'Himejima', 'Demon slayer', NULL, 290000.00, '2014-08-05', 70, 91.43),
('INV019', 'Nezuko', 'Kamado', 'Demon slayer', 'INV001', 95000.00, '2019-04-01', 25, 80.00),
('INV020', 'Obanai', 'Iguro', 'Demon slayer', NULL, 185000.00, '2016-10-12', 48, 87.50);

-- ============================================
-- 3. HASHIRA DATA (subclass of INVESTOR)
-- ============================================
INSERT INTO HASHIRA (InvestorID, BreathingTechnique, RankLevel, Corps) VALUES
('INV002', 'Water Breathing', 10, 'Demon Slayer Corps'),
('INV003', 'Insect Breathing', 9, 'Demon Slayer Corps'),
('INV004', 'Flame Breathing', 10, 'Demon Slayer Corps'),
('INV014', 'Love Breathing', 8, 'Demon Slayer Corps'),
('INV015', 'Sound Breathing', 9, 'Demon Slayer Corps'),
('INV016', 'Wind Breathing', 10, 'Demon Slayer Corps'),
('INV017', 'Mist Breathing', 8, 'Demon Slayer Corps'),
('INV018', 'Stone Breathing', 10, 'Demon Slayer Corps'),
('INV020', 'Serpent Breathing', 9, 'Demon Slayer Corps');

-- ============================================
-- 4. UPPER_RANK_DEMON DATA (subclass of INVESTOR)
-- ============================================
INSERT INTO UPPER_RANK_DEMON (InvestorID, BloodArt, RankLevel, Corps) VALUES
('INV009', 'Biokinesis', 10, 'Twelve Kizuki'),
('INV010', 'Moon Breathing', 10, 'Twelve Kizuki'),
('INV011', 'Cryokinesis', 9, 'Twelve Kizuki'),
('INV012', 'Destructive Death', 9, 'Twelve Kizuki'),
('INV013', 'Blood Manipulation', 7, 'Twelve Kizuki');

-- ============================================
-- 5. COMPANY DATA
-- ============================================
INSERT INTO COMPANY (CompanyID, Name, CEO, Founded, Headquarters, MarketCap, SharesOutstanding, SectorID) VALUES
('CMP001', 'Nichirin Forge Inc', 'Hotaru Haganezuka', '2010-03-15', 'Swordsmith Village', 5500000000.00, 50000000, 'SEC004'),
('CMP002', 'Wisteria Pharmaceuticals', 'Tamayo Research', '2012-07-20', 'Hidden Lab District', 4200000000.00, 40000000, 'SEC003'),
('CMP003', 'Ubuyashiki Financial Group', 'Kagaya Ubuyashiki', '2008-01-10', 'Demon Slayer HQ', 8900000000.00, 75000000, 'SEC002'),
('CMP004', 'Kasugai Crow Communications', 'Crow Master', '2015-05-12', 'Sky Network Tower', 3100000000.00, 30000000, 'SEC001'),
('CMP005', 'Hashira Energy Systems', 'Renewable Team', '2018-09-25', 'Central Power Grid', 6700000000.00, 60000000, 'SEC005'),
('CMP006', 'Breath Tech Innovations', 'Urokodaki Sakonji', '2013-11-08', 'Mountain Research Facility', 7200000000.00, 65000000, 'SEC001'),
('CMP007', 'Demon Detection Corp', 'Sensor Division', '2016-02-18', 'Security Complex', 2800000000.00, 25000000, 'SEC001'),
('CMP008', 'Slayer Medical Holdings', 'Butterfly Mansion', '2011-06-30', 'Medical District', 5900000000.00, 55000000, 'SEC003'),
('CMP009', 'Sunlight Weaponry Ltd', 'Yoriichi Legacy', '2009-12-01', 'Ancient Forge', 9500000000.00, 80000000, 'SEC004'),
('CMP010', 'Blood Art Defense', 'Counter Demon Unit', '2017-04-22', 'Research Bunker', 4600000000.00, 45000000, 'SEC004');

-- ============================================
-- 6. PRODUCT DATA
-- ============================================
INSERT INTO PRODUCT (ProductID, Name, Type, PowerLevel, CompanyID, Price, ReleaseDate) VALUES
('PRD001', 'Nichirin Blade - Water', 'Weapon', 85, 'CMP001', 15000.00, '2018-01-15'),
('PRD002', 'Nichirin Blade - Flame', 'Weapon', 90, 'CMP001', 18000.00, '2018-03-20'),
('PRD003', 'Wisteria Poison Extract', 'Potion', 75, 'CMP002', 5000.00, '2019-02-10'),
('PRD004', 'Regeneration Serum', 'Potion', 80, 'CMP002', 12000.00, '2019-06-15'),
('PRD005', 'Total Concentration Breathing Manual', 'Technique', 70, 'CMP006', 8000.00, '2017-09-05'),
('PRD006', 'Kasugai Crow GPS Tracker', 'Tool', 60, 'CMP004', 3000.00, '2020-01-20'),
('PRD007', 'Sun Protection Armor', 'Armor', 82, 'CMP009', 25000.00, '2018-11-12'),
('PRD008', 'Demon Detector Scanner', 'Tool', 65, 'CMP007', 7500.00, '2019-08-18'),
('PRD009', 'Blood Art Neutralizer', 'Potion', 78, 'CMP010', 9500.00, '2020-03-25'),
('PRD010', 'Breath Amplifier Device', 'Tool', 72, 'CMP006', 11000.00, '2019-12-08'),
('PRD011', 'Nichirin Blade - Thunder', 'Weapon', 88, 'CMP001', 17000.00, '2018-06-22'),
('PRD012', 'Wisteria Barrier Crystal', 'Tool', 68, 'CMP002', 6500.00, '2020-05-14'),
('PRD013', 'Hashira Training Program', 'Technique', 92, 'CMP006', 50000.00, '2017-04-30'),
('PRD014', 'Emergency Healing Kit', 'Potion', 70, 'CMP008', 4500.00, '2019-10-10'),
('PRD015', 'Demon Restraint Chains', 'Tool', 76, 'CMP009', 8800.00, '2018-08-05');

-- ============================================
-- 7. STOCK DATA
-- ============================================
INSERT INTO STOCK (StockID, Symbol, Name, BaseValue, CompanyID, IPODate) VALUES
('STK001', 'NCHFG', 'Nichirin Forge', 110.50, 'CMP001', '2010-06-01'),
('STK002', 'WSTPH', 'Wisteria Pharma', 84.75, 'CMP002', '2012-09-15'),
('STK003', 'UBYFN', 'Ubuyashiki Finance', 118.90, 'CMP003', '2008-03-20'),
('STK004', 'KSGCM', 'Kasugai Comm', 62.30, 'CMP004', '2015-07-10'),
('STK005', 'HSHEN', 'Hashira Energy', 89.40, 'CMP005', '2018-11-05'),
('STK006', 'BRTHC', 'Breath Tech', 96.20, 'CMP006', '2014-01-18'),
('STK007', 'DMDET', 'Demon Detection', 56.80, 'CMP007', '2016-04-22'),
('STK008', 'SLYMD', 'Slayer Medical', 78.65, 'CMP008', '2011-08-30'),
('STK009', 'SNWPN', 'Sunlight Weapon', 127.35, 'CMP009', '2010-02-12'),
('STK010', 'BLDDF', 'Blood Art Defense', 73.50, 'CMP010', '2017-06-25');

-- ============================================
-- 8. FIGHT DATA
-- ============================================
INSERT INTO FIGHT (FightID, Location, WinnerInvestorID, LoserInvestorID, SkillsUsed, ProductsUsed) VALUES
('F001', 'Mount Natagumo', 'INV001', 'INV013', 'Water Breathing: Dead Calm', 'PRD001, PRD003'),
('F002', 'Mugen Train', 'INV004', 'INV012', 'Flame Breathing: Ninth Form', 'PRD002, PRD014'),
('F003', 'Entertainment District', 'INV015', 'INV013', 'Sound Breathing: Fifth Form', 'PRD007, PRD011'),
('F004', 'Infinity Castle', 'INV002', 'INV012', 'Water Breathing: Eleventh Form', 'PRD001, PRD009'),
('F005', 'Swordsmith Village', 'INV017', 'INV011', 'Mist Breathing: Seventh Form', 'PRD010, PRD012'),
('F006', 'Final Battle Arena', 'INV018', 'INV010', 'Stone Breathing: Fifth Form', 'PRD013, PRD015'),
('F007', 'Butterfly Mansion', 'INV003', 'INV012', 'Insect Breathing: Dance', 'PRD003, PRD008'),
('F008', 'Lower Moon Battlefield', 'INV001', 'INV011', 'Hinokami Kagura', 'PRD002, PRD009'),
('F009', 'Upper Moon Showdown', 'INV016', 'INV010', 'Wind Breathing: Eighth Form', 'PRD011, PRD007'),
('F010', 'Dawn of Victory', 'INV004', 'INV009', 'Flame Breathing: Esoteric Art', 'PRD002, PRD013');

-- ============================================
-- 9. NEWS_EFFECT DATA
-- ============================================
INSERT INTO NEWS_EFFECT (NewsID, FightID, WinnerType, Description, StockEffect, ImpactLevel) VALUES
('NEWS001', 'F001', 'Hero', 'Tanjiro defeats Spider Demon - Nichirin Blade demand surges', 5.50, 'High'),
('NEWS002', 'F002', 'Hero', 'Rengoku sacrifices himself defeating Akaza - Flame techniques gain popularity', 8.20, 'Critical'),
('NEWS003', 'F003', 'Hero', 'Sound Hashira eliminates Upper 6 - Entertainment District secured', 6.75, 'High'),
('NEWS004', 'F004', 'Hero', 'Water Hashira dominates Akaza - Defensive stocks rally', 4.30, 'Medium'),
('NEWS005', 'F005', 'Hero', 'Mist Hashira defeats Upper 2 - Detection technology praised', 7.10, 'High'),
('NEWS006', 'F006', 'Hero', 'Stone Hashira crushes Upper 1 - Training programs sell out', 9.50, 'Critical'),
('NEWS007', 'F007', 'Hero', 'Insect Hashira poisons demon - Pharmaceutical stocks soar', 6.20, 'High'),
('NEWS008', 'F008', 'Hero', 'Kamado uses Sun Breathing - Ancient weapon interest spikes', 8.80, 'Critical'),
('NEWS009', 'F009', 'Hero', 'Wind Hashira slices Upper 1 - Blade orders increase', 5.90, 'High'),
('NEWS010', 'F010', 'Hero', 'Flame Hashira defeats Demon King - All demon-slaying stocks boom', 12.50, 'Critical');

-- ============================================
-- 10. MAGIC_SPELL DATA
-- ============================================
INSERT INTO MAGIC_SPELL (SpellID, InvestorID, Name, EffectType, Duration, CooldownPeriod, Description) VALUES
('SPL001', 'INV001', 'Water Surface Slash', 'Pump', 3, 24, 'Increases water-related stock values'),
('SPL002', 'INV002', 'Dead Calm Market', 'Freeze', 5, 48, 'Freezes stock volatility temporarily'),
('SPL003', 'INV003', 'Insect Swarm Volatility', 'Volatility', 2, 12, 'Creates rapid price fluctuations'),
('SPL004', 'INV004', 'Flame Surge', 'Pump', 4, 36, 'Dramatically increases stock prices'),
('SPL005', 'INV009', 'Blood Demon Crash', 'Crash', 6, 72, 'Causes severe market downturn'),
('SPL006', 'INV010', 'Crescent Moon Freeze', 'Freeze', 8, 96, 'Locks prices at current levels'),
('SPL007', 'INV011', 'Frozen Lotus Crash', 'Crash', 4, 48, 'Triggers sharp price decline'),
('SPL008', 'INV015', 'Sound Wave Pump', 'Pump', 3, 24, 'Amplifies positive market momentum'),
('SPL009', 'INV016', 'Wind Scythe Volatility', 'Volatility', 2, 18, 'Generates unpredictable swings'),
('SPL010', 'INV018', 'Stone Wall Freeze', 'Freeze', 10, 120, 'Maximum price stabilization');

-- ============================================
-- 11. TRANSACTION_RECORD DATA
-- ============================================
INSERT INTO TRANSACTION_RECORD (TransactionID, InvestorID, StockID, TransactionType, Quantity, PricePerShare, TotalValue) VALUES
('TX00001', 'INV001', 'STK001', 'Buy', 500, 108.50, 54250.00),
('TX00002', 'INV002', 'STK003', 'Buy', 800, 115.20, 92160.00),
('TX00003', 'INV003', 'STK002', 'Buy', 600, 82.40, 49440.00),
('TX00004', 'INV004', 'STK009', 'Buy', 400, 125.00, 50000.00),
('TX00005', 'INV005', 'STK001', 'Buy', 300, 110.50, 33150.00),
('TX00006', 'INV009', 'STK005', 'Buy', 1000, 87.30, 87300.00),
('TX00007', 'INV010', 'STK006', 'Buy', 750, 94.50, 70875.00),
('TX00008', 'INV001', 'STK001', 'Sell', 200, 112.75, 22550.00),
('TX00009', 'INV015', 'STK004', 'Buy', 900, 60.80, 54720.00),
('TX00010', 'INV011', 'STK010', 'Buy', 650, 71.20, 46280.00),
('TX00011', 'INV014', 'STK008', 'Buy', 550, 76.40, 42020.00),
('TX00012', 'INV016', 'STK007', 'Buy', 700, 55.30, 38710.00),
('TX00013', 'INV002', 'STK003', 'Sell', 300, 120.50, 36150.00),
('TX00014', 'INV018', 'STK009', 'Buy', 850, 128.90, 109565.00),
('TX00015', 'INV007', 'STK002', 'Buy', 400, 85.60, 34240.00);

-- ============================================
-- 12. PORTFOLIO DATA
-- ============================================
INSERT INTO PORTFOLIO (InvestorID, StockID, Quantity, PurchasePrice, PurchaseDate) VALUES
('INV001', 'STK001', 300, 110.50, '2023-01-15'),
('INV001', 'STK002', 250, 84.75, '2023-03-20'),
('INV002', 'STK003', 500, 118.90, '2023-02-10'),
('INV002', 'STK009', 400, 125.00, '2023-04-05'),
('INV003', 'STK002', 600, 82.40, '2023-01-25'),
('INV003', 'STK008', 350, 78.65, '2023-05-12'),
('INV004', 'STK009', 400, 125.00, '2023-02-18'),
('INV004', 'STK001', 450, 108.50, '2023-03-08'),
('INV005', 'STK001', 300, 110.50, '2023-06-20'),
('INV006', 'STK004', 500, 62.30, '2023-04-15'),
('INV007', 'STK002', 400, 85.60, '2023-07-10'),
('INV009', 'STK005', 1000, 87.30, '2023-01-08'),
('INV009', 'STK010', 800, 73.50, '2023-02-22'),
('INV010', 'STK006', 750, 94.50, '2023-03-14'),
('INV011', 'STK010', 650, 71.20, '2023-04-28'),
('INV014', 'STK008', 550, 76.40, '2023-05-30'),
('INV015', 'STK004', 900, 60.80, '2023-06-15'),
('INV016', 'STK007', 700, 55.30, '2023-07-20'),
('INV018', 'STK009', 850, 128.90, '2023-08-05');

-- ============================================
-- 13. INVESTOR_SKILLS DATA (Weak Entity)
-- ============================================
INSERT INTO INVESTOR_SKILLS (InvestorID, Skill, SkillLevel) VALUES
('INV001', 'Water Breathing', 9),
('INV001', 'Hinokami Kagura', 8),
('INV001', 'Swordsmanship', 9),
('INV002', 'Water Breathing', 10),
('INV002', 'Dead Calm', 10),
('INV003', 'Insect Breathing', 9),
('INV003', 'Poison Mastery', 10),
('INV004', 'Flame Breathing', 10),
('INV004', 'Ninth Form', 10),
('INV005', 'Thunder Breathing', 8),
('INV006', 'Beast Breathing', 8),
('INV009', 'Blood Manipulation', 10),
('INV009', 'Regeneration', 10),
('INV010', 'Moon Breathing', 10),
('INV011', 'Ice Manipulation', 9),
('INV012', 'Destructive Death', 9),
('INV014', 'Love Breathing', 8),
('INV015', 'Sound Breathing', 9),
('INV016', 'Wind Breathing', 10),
('INV017', 'Mist Breathing', 8),
('INV018', 'Stone Breathing', 10);

-- ============================================
-- 14. FIGHT_SCORE DATA (Weak Entity)
-- ============================================
INSERT INTO FIGHT_SCORE (FightID, InvestorID, Score, Performance, Rewards, EffectDescription) VALUES
('F001', 'INV001', 85, 'Excellent', 15000.00, 'Successfully defeated Spider Demon'),
('F001', 'INV013', 45, 'Poor', 0.00, 'Defeated by Water Hashira technique'),
('F002', 'INV004', 92, 'Excellent', 25000.00, 'Heroic sacrifice defeating Upper 3'),
('F002', 'INV012', 78, 'Good', 0.00, 'Strong fight but ultimately defeated'),
('F003', 'INV015', 88, 'Excellent', 20000.00, 'Eliminated Upper 6 with Sound Breathing'),
('F003', 'INV013', 52, 'Average', 0.00, 'Lost in Entertainment District battle'),
('F004', 'INV002', 90, 'Excellent', 22000.00, 'Dominated with Eleventh Form'),
('F004', 'INV012', 65, 'Average', 0.00, 'Could not overcome Water techniques'),
('F005', 'INV017', 87, 'Excellent', 18000.00, 'Defeated Upper 2 with Mist techniques'),
('F005', 'INV011', 58, 'Average', 0.00, 'Lost despite ice blood art'),
('F006', 'INV018', 95, 'Excellent', 30000.00, 'Crushed Upper 1 with overwhelming power'),
('F006', 'INV010', 72, 'Good', 0.00, 'Strong but overpowered by Stone Hashira'),
('F007', 'INV003', 86, 'Excellent', 17000.00, 'Poison mastery proved effective'),
('F007', 'INV012', 60, 'Average', 0.00, 'Defeated by Insect techniques'),
('F008', 'INV001', 91, 'Excellent', 23000.00, 'Sun Breathing demonstration'),
('F008', 'INV011', 55, 'Average', 0.00, 'Could not withstand Sun techniques'),
('F009', 'INV016', 89, 'Excellent', 21000.00, 'Wind techniques sliced through defense'),
('F009', 'INV010', 68, 'Good', 0.00, 'Fought well but ultimately lost'),
('F010', 'INV004', 98, 'Excellent', 50000.00, 'Legendary defeat of Demon King'),
('F010', 'INV009', 82, 'Good', 0.00, 'Final defeat of ultimate evil');

-- ============================================
-- 15. HASHIRA_BREATHING_TECHNIQUES (Multivalued)
-- ============================================
INSERT INTO HASHIRA_BREATHING_TECHNIQUES (InvestorID, Technique) VALUES
('INV002', 'Water Surface Slash'),
('INV002', 'Waterfall Basin'),
('INV002', 'Striking Tide'),
('INV002', 'Dead Calm'),
('INV003', 'Butterfly Dance'),
('INV003', 'Dance of the Bee Sting'),
('INV003', 'Dance of the Dragonfly'),
('INV004', 'Unknowing Fire'),
('INV004', 'Rising Scorching Sun'),
('INV004', 'Blooming Flame Undulation'),
('INV004', 'Ninth Form Rengoku'),
('INV014', 'First Form Shivers'),
('INV014', 'Fifth Form Swaying'),
('INV015', 'Roar'),
('INV015', 'String Performance'),
('INV016', 'Dust Whirlwind'),
('INV016', 'Idaten Typhoon'),
('INV017', 'Low Clouds'),
('INV017', 'Obscuring Clouds'),
('INV018', 'Stone Skin'),
('INV018', 'Stone Breathing Fifth Form'),
('INV020', 'Serpent Breathing First Form');

-- ============================================
-- 16. COMPANY_PRODUCT_TYPE (Multivalued)
-- ============================================
INSERT INTO COMPANY_PRODUCT_TYPE (CompanyID, ProductType) VALUES
('CMP001', 'Weapon'),
('CMP001', 'Armor'),
('CMP002', 'Potion'),
('CMP002', 'Tool'),
('CMP003', 'Financial Services'),
('CMP004', 'Tool'),
('CMP004', 'Communication Devices'),
('CMP005', 'Energy Solutions'),
('CMP006', 'Technique'),
('CMP006', 'Tool'),
('CMP007', 'Tool'),
('CMP007', 'Detection Systems'),
('CMP008', 'Potion'),
('CMP008', 'Medical Services'),
('CMP009', 'Weapon'),
('CMP009', 'Armor'),
('CMP010', 'Potion'),
('CMP010', 'Defense Systems');

-- ============================================
-- 17. PROMOTES (Many-to-Many)
-- ============================================
INSERT INTO PROMOTES (CompanyID, InvestorID, StartDate, EndDate, Role) VALUES
('CMP001', 'INV001', '2023-01-15', '2023-12-31', 'Brand Ambassador'),
('CMP001', 'INV004', '2023-02-01', '2024-01-31', 'Product Tester'),
('CMP002', 'INV003', '2023-03-10', NULL, 'Chief Medical Advisor'),
('CMP006', 'INV002', '2023-01-20', NULL, 'Technique Instructor'),
('CMP009', 'INV018', '2023-04-15', '2024-04-15', 'Weapon Consultant'),
('CMP004', 'INV015', '2023-05-01', NULL, 'Communications Director'),
('CMP008', 'INV003', '2023-06-20', NULL, 'Medical Research Lead'),
('CMP005', 'INV016', '2023-02-28', '2023-11-30', 'Energy Advisor'),
('CMP010', 'INV014', '2023-07-10', NULL, 'Defense Strategist');

-- ============================================
-- 18. CASTS_SPELL_ON (Ternary Relationship)
-- ============================================
INSERT INTO CASTS_SPELL_ON (InvestorID, SpellID, StockID, EffectDuration, PowerConsumption) VALUES
('INV001', 'SPL001', 'STK001', 3, 25),
('INV002', 'SPL002', 'STK003', 5, 40),
('INV003', 'SPL003', 'STK002', 2, 20),
('INV004', 'SPL004', 'STK009', 4, 35),
('INV009', 'SPL005', 'STK005', 6, 60),
('INV010', 'SPL006', 'STK006', 8, 80),
('INV011', 'SPL007', 'STK010', 4, 45),
('INV015', 'SPL008', 'STK004', 3, 30),
('INV016', 'SPL009', 'STK007', 2, 22),
('INV018', 'SPL010', 'STK009', 10, 100),
('INV001', 'SPL001', 'STK002', 3, 28),
('INV004', 'SPL004', 'STK001', 4, 38);

-- ============================================
-- 19. INVESTOR_PRODUCT_FIGHT_REWARD (Quaternary)
-- ============================================
INSERT INTO INVESTOR_PRODUCT_FIGHT_REWARD (InvestorID, ProductID, FightID, StockID, RewardAmount, EffectDescription) VALUES
('INV001', 'PRD001', 'F001', 'STK001', 5000.00, 'Nichirin Blade usage increased stock value by 5%'),
('INV001', 'PRD003', 'F001', 'STK002', 3000.00, 'Wisteria poison effectiveness boosted pharma stocks'),
('INV004', 'PRD002', 'F002', 'STK001', 8000.00, 'Flame blade performance drove weapon sales'),
('INV004', 'PRD014', 'F002', 'STK008', 4000.00, 'Medical supplies critical in battle'),
('INV015', 'PRD007', 'F003', 'STK009', 6000.00, 'Sun protection armor proved invaluable'),
('INV015', 'PRD011', 'F003', 'STK001', 5500.00, 'Thunder blade created market buzz'),
('INV002', 'PRD001', 'F004', 'STK001', 7000.00, 'Water blade mastery showcased'),
('INV002', 'PRD009', 'F004', 'STK010', 4500.00, 'Blood art neutralizer effective'),
('INV017', 'PRD010', 'F005', 'STK006', 5000.00, 'Breath amplifier enhanced performance'),
('INV017', 'PRD012', 'F005', 'STK002', 3500.00, 'Wisteria barrier protected well'),
('INV018', 'PRD013', 'F006', 'STK006', 10000.00, 'Training program excellence demonstrated'),
('INV018', 'PRD015', 'F006', 'STK009', 7500.00, 'Restraint chains proved essential'),
('INV003', 'PRD003', 'F007', 'STK002', 6000.00, 'Poison extract devastatingly effective'),
('INV003', 'PRD008', 'F007', 'STK007', 4000.00, 'Detection scanner aided strategy'),
('INV001', 'PRD002', 'F008', 'STK009', 9000.00, 'Flame techniques with sunlight weapon'),
('INV001', 'PRD009', 'F008', 'STK010', 5000.00, 'Neutralizer critical for victory');

-- ============================================
-- 20. INVESTOR_FIGHT_SKILL_SCORE (Quaternary)
-- ============================================
INSERT INTO INVESTOR_FIGHT_SKILL_SCORE (InvestorID, FightID, Skill, SkillScore) VALUES
('INV001', 'F001', 'Water Breathing', 90),
('INV001', 'F001', 'Swordsmanship', 88),
('INV004', 'F002', 'Flame Breathing', 95),
('INV004', 'F002', 'Ninth Form', 98),
('INV015', 'F003', 'Sound Breathing', 92),
('INV002', 'F004', 'Water Breathing', 94),
('INV002', 'F004', 'Dead Calm', 96),
('INV017', 'F005', 'Mist Breathing', 89),
('INV018', 'F006', 'Stone Breathing', 97),
('INV003', 'F007', 'Insect Breathing', 91),
('INV003', 'F007', 'Poison Mastery', 93),
('INV001', 'F008', 'Hinokami Kagura', 92),
('INV001', 'F008', 'Water Breathing', 88),
('INV016', 'F009', 'Wind Breathing', 94),
('INV004', 'F010', 'Flame Breathing', 99),
('INV009', 'F010', 'Blood Manipulation', 85),
('INV009', 'F010', 'Regeneration', 87);

-- ============================================
-- DATA POPULATION COMPLETE
-- ============================================
