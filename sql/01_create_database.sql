-- ============================================================================
-- CO-PYROLYSIS ANALYTICS DATABASE
-- Catalytic Co-Pyrolysis of Biomass & Plastic Wastes
-- Research: IIT Roorkee | Prof. Prasenjit Mondal
-- ============================================================================
-- Author: Nikita Chakraborty
-- Description: Database schema and data insertion for co-pyrolysis experiments
--              using Box-Behnken Design (BBD) with Response Surface Methodology
-- Feedstock: Red Oak (Biomass) + LDPE (Plastic Waste)
-- Catalyst: Spent Li-ion Battery Cathode Powder (Ni, Co, Mn)
-- ============================================================================

-- Create Database
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CoPyrolysisAnalytics')
    DROP DATABASE CoPyrolysisAnalytics;
GO

CREATE DATABASE CoPyrolysisAnalytics;
GO

USE CoPyrolysisAnalytics;
GO

-- ============================================================================
-- TABLE 1: Experiment Parameters
-- Stores the independent variables (process parameters) for each run
-- ============================================================================
CREATE TABLE experiment_parameters (
    run_id              INT             PRIMARY KEY,
    temperature         INT             NOT NULL,       -- Temperature in °C (400, 500, 600)
    heating_rate        INT             NOT NULL,       -- Heating rate in °C/min (10, 30, 50)
    reaction_time       INT             NOT NULL,       -- Reaction time in minutes (10, 25, 40)
    experiment_date     DATE            DEFAULT GETDATE(),
    CONSTRAINT CK_Temperature CHECK (temperature BETWEEN 400 AND 600),
    CONSTRAINT CK_HeatingRate CHECK (heating_rate BETWEEN 10 AND 50),
    CONSTRAINT CK_ReactionTime CHECK (reaction_time BETWEEN 10 AND 40)
);
GO

-- ============================================================================
-- TABLE 2: Product Yields
-- Stores the dependent variables (response) — yields of bio-oil, biochar, gas
-- ============================================================================
CREATE TABLE product_yields (
    yield_id            INT             IDENTITY(1,1) PRIMARY KEY,
    run_id              INT             NOT NULL,
    bio_oil_yield       DECIMAL(5,2)    NOT NULL,       -- Bio-oil yield in %
    biochar_yield       DECIMAL(5,2)    NOT NULL,       -- Biochar yield in %
    gas_yield           DECIMAL(5,2)    NOT NULL,       -- Gas yield in % (= 100 - bio_oil - biochar)
    total_liquid_yield  DECIMAL(5,2)    NOT NULL,       -- Total liquid = bio_oil + biochar
    CONSTRAINT FK_Yields_Parameters FOREIGN KEY (run_id) 
        REFERENCES experiment_parameters(run_id),
    CONSTRAINT CK_BioOil CHECK (bio_oil_yield >= 0),
    CONSTRAINT CK_Biochar CHECK (biochar_yield >= 0),
    CONSTRAINT CK_Gas CHECK (gas_yield >= 0)
);
GO

-- ============================================================================
-- TABLE 3: Process Conditions (Categorized)
-- Stores categorical classifications of process parameters
-- ============================================================================
CREATE TABLE process_conditions (
    run_id                  INT             PRIMARY KEY,
    temp_category           VARCHAR(10)     NOT NULL,       -- Low (400), Medium (500), High (600)
    heating_rate_category   VARCHAR(10)     NOT NULL,       -- Low (10), Medium (30), High (50)
    reaction_time_category  VARCHAR(10)     NOT NULL,       -- Short (10), Medium (25), Long (40)
    CONSTRAINT FK_Conditions_Parameters FOREIGN KEY (run_id)
        REFERENCES experiment_parameters(run_id),
    CONSTRAINT CK_TempCat CHECK (temp_category IN ('Low', 'Medium', 'High')),
    CONSTRAINT CK_HRCat CHECK (heating_rate_category IN ('Low', 'Medium', 'High')),
    CONSTRAINT CK_RTCat CHECK (reaction_time_category IN ('Short', 'Medium', 'Long'))
);
GO

-- ============================================================================
-- TABLE 4: Optimal Conditions
-- Stores identified optimal process conditions for each target product
-- ============================================================================
CREATE TABLE optimal_conditions (
    condition_id        INT             IDENTITY(1,1) PRIMARY KEY,
    target_product      VARCHAR(20)     NOT NULL,       -- 'Bio-Oil', 'Biochar', 'Gas'
    optimal_temp        INT             NOT NULL,
    optimal_heating_rate INT            NOT NULL,
    optimal_reaction_time INT           NOT NULL,
    max_yield           DECIMAL(5,2)    NOT NULL,
    run_id_reference    INT             NOT NULL,
    notes               VARCHAR(200)    NULL,
    CONSTRAINT FK_Optimal_Parameters FOREIGN KEY (run_id_reference)
        REFERENCES experiment_parameters(run_id)
);
GO

-- ============================================================================
-- TABLE 5: Research Metadata
-- Stores project and research context information
-- ============================================================================
CREATE TABLE research_metadata (
    metadata_id         INT             IDENTITY(1,1) PRIMARY KEY,
    project_title       VARCHAR(200)    NOT NULL,
    institution         VARCHAR(100)    NOT NULL,
    department          VARCHAR(100)    NOT NULL,
    supervisor          VARCHAR(100)    NOT NULL,
    researcher          VARCHAR(100)    NOT NULL,
    feedstock_biomass   VARCHAR(50)     NOT NULL,
    feedstock_plastic   VARCHAR(50)     NOT NULL,
    catalyst            VARCHAR(100)    NOT NULL,
    design_method       VARCHAR(50)     NOT NULL,
    publication_status  VARCHAR(20)     NOT NULL
);
GO

-- ============================================================================
-- INSERT DATA: Experiment Parameters
-- 15 runs based on Box-Behnken Design (3 factors, 3 levels)
-- ============================================================================
INSERT INTO experiment_parameters (run_id, temperature, heating_rate, reaction_time)
VALUES
    (1,  600, 50, 10),
    (3,  600, 10, 40),
    (4,  500, 30, 25),
    (5,  400, 50, 40),
    (6,  600, 50, 40),
    (7,  400, 50, 10),
    (8,  600, 30, 25),
    (10, 500, 30, 40),
    (12, 400, 10, 10),
    (13, 500, 30, 25),
    (15, 500, 50, 25),
    (16, 500, 10, 25),
    (17, 500, 30, 10),
    (19, 400, 30, 25),
    (20, 400, 10, 40);
GO

-- ============================================================================
-- INSERT DATA: Product Yields
-- Gas Yield = 100 - Bio_Oil_Yield - Biochar_Yield
-- Total Liquid Yield = Bio_Oil_Yield + Biochar_Yield
-- ============================================================================
INSERT INTO product_yields (run_id, bio_oil_yield, biochar_yield, gas_yield, total_liquid_yield)
VALUES
    (1,  13.20, 5.20,  81.60, 18.40),
    (3,  17.50, 4.50,  78.00, 22.00),
    (4,  11.75, 5.20,  83.05, 16.95),
    (5,  4.50,  0.10,  95.40, 4.60),
    (6,  17.20, 4.80,  78.00, 22.00),
    (7,  5.50,  9.20,  85.30, 14.70),
    (8,  21.50, 6.90,  71.60, 28.40),
    (10, 17.10, 6.83,  76.07, 23.93),
    (12, 16.60, 3.20,  80.20, 19.80),
    (13, 10.50, 6.10,  83.40, 16.60),
    (15, 4.50,  14.50, 81.00, 19.00),
    (16, 17.25, 5.25,  77.50, 22.50),
    (17, 7.50,  8.00,  84.50, 15.50),
    (19, 3.50,  7.80,  88.70, 11.30),
    (20, 2.50,  4.10,  93.40, 6.60);
GO

-- ============================================================================
-- INSERT DATA: Process Conditions (Categorized)
-- ============================================================================
INSERT INTO process_conditions (run_id, temp_category, heating_rate_category, reaction_time_category)
VALUES
    (1,  'High',   'High',   'Short'),
    (3,  'High',   'Low',    'Long'),
    (4,  'Medium', 'Medium', 'Medium'),
    (5,  'Low',    'High',   'Long'),
    (6,  'High',   'High',   'Long'),
    (7,  'Low',    'High',   'Short'),
    (8,  'High',   'Medium', 'Medium'),
    (10, 'Medium', 'Medium', 'Long'),
    (12, 'Low',    'Low',    'Short'),
    (13, 'Medium', 'Medium', 'Medium'),
    (15, 'Medium', 'High',   'Medium'),
    (16, 'Medium', 'Low',    'Medium'),
    (17, 'Medium', 'Medium', 'Short'),
    (19, 'Low',    'Medium', 'Medium'),
    (20, 'Low',    'Low',    'Long');
GO

-- ============================================================================
-- INSERT DATA: Optimal Conditions
-- ============================================================================
INSERT INTO optimal_conditions (target_product, optimal_temp, optimal_heating_rate, optimal_reaction_time, max_yield, run_id_reference, notes)
VALUES
    ('Bio-Oil',  600, 30, 25, 21.50, 8,  'Maximum bio-oil yield achieved at high temperature with moderate heating rate'),
    ('Biochar',  500, 50, 25, 14.50, 15, 'Maximum biochar yield at medium temperature with high heating rate'),
    ('Gas',      400, 50, 40, 95.40, 5,  'Maximum gas yield at low temperature — indicates incomplete pyrolysis');
GO

-- ============================================================================
-- INSERT DATA: Research Metadata
-- ============================================================================
INSERT INTO research_metadata (project_title, institution, department, supervisor, researcher, 
    feedstock_biomass, feedstock_plastic, catalyst, design_method, publication_status)
VALUES (
    'Catalytic Co-Pyrolysis of Biomass and Plastic Wastes: Biofuel Production and Biochar Valorization through Energy Storage Applications',
    'Indian Institute of Technology Roorkee',
    'Department of Chemical Engineering',
    'Prof. Prasenjit Mondal',
    'Nikita Chakraborty',
    'Red Oak',
    'LDPE (Low-Density Polyethylene)',
    'Spent Li-ion Battery Cathode Powder (Ni, Co, Mn)',
    'Box-Behnken Design (BBD) with RSM',
    'Published'
);
GO

PRINT '✅ Database CoPyrolysisAnalytics created successfully with all tables and data.';
GO
