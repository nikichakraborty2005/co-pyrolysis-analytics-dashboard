-- ============================================================================
-- CO-PYROLYSIS ANALYTICS — VIEWS AND STORED PROCEDURES
-- Reusable database objects for Power BI and reporting
-- ============================================================================

USE CoPyrolysisAnalytics;
GO

-- ============================================================================
-- VIEW 1: vw_experiment_summary
-- Master view joining all tables — primary data source for Power BI
-- ============================================================================
CREATE OR ALTER VIEW vw_experiment_summary AS
SELECT 
    ep.run_id,
    ep.temperature,
    ep.heating_rate,
    ep.reaction_time,
    py.bio_oil_yield,
    py.biochar_yield,
    py.gas_yield,
    py.total_liquid_yield,
    pc.temp_category,
    pc.heating_rate_category,
    pc.reaction_time_category,
    -- Derived columns
    CASE 
        WHEN py.biochar_yield > 0 
        THEN ROUND(py.bio_oil_yield / py.biochar_yield, 2)
        ELSE NULL 
    END AS bio_oil_to_biochar_ratio,
    ROUND(py.bio_oil_yield + py.biochar_yield, 2) AS total_solid_liquid_yield,
    CASE 
        WHEN py.bio_oil_yield >= 15 THEN 'High'
        WHEN py.bio_oil_yield >= 10 THEN 'Medium'
        ELSE 'Low'
    END AS bio_oil_performance,
    CASE 
        WHEN py.biochar_yield >= 8 THEN 'High'
        WHEN py.biochar_yield >= 5 THEN 'Medium'
        ELSE 'Low'
    END AS biochar_performance
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
JOIN process_conditions pc ON ep.run_id = pc.run_id;
GO


-- ============================================================================
-- VIEW 2: vw_temperature_analysis
-- Pre-aggregated temperature-level analysis for trend charts
-- ============================================================================
CREATE OR ALTER VIEW vw_temperature_analysis AS
SELECT 
    temperature,
    CASE temperature
        WHEN 400 THEN 'Low (400°C)'
        WHEN 500 THEN 'Medium (500°C)'
        WHEN 600 THEN 'High (600°C)'
    END AS temp_label,
    COUNT(*) AS num_experiments,
    ROUND(AVG(bio_oil_yield), 2) AS avg_bio_oil,
    ROUND(AVG(biochar_yield), 2) AS avg_biochar,
    ROUND(AVG(gas_yield), 2) AS avg_gas,
    ROUND(MIN(bio_oil_yield), 2) AS min_bio_oil,
    ROUND(MAX(bio_oil_yield), 2) AS max_bio_oil,
    ROUND(MIN(biochar_yield), 2) AS min_biochar,
    ROUND(MAX(biochar_yield), 2) AS max_biochar,
    ROUND(STDEV(bio_oil_yield), 2) AS stddev_bio_oil,
    ROUND(STDEV(biochar_yield), 2) AS stddev_biochar
FROM vw_experiment_summary
GROUP BY temperature;
GO


-- ============================================================================
-- VIEW 3: vw_optimal_conditions
-- Identifies the best run for each product type
-- ============================================================================
CREATE OR ALTER VIEW vw_optimal_conditions AS
SELECT 
    'Bio-Oil' AS target_product,
    run_id,
    temperature,
    heating_rate,
    reaction_time,
    bio_oil_yield AS max_yield,
    biochar_yield AS secondary_yield,
    temp_category,
    heating_rate_category,
    reaction_time_category
FROM vw_experiment_summary
WHERE bio_oil_yield = (SELECT MAX(bio_oil_yield) FROM product_yields)

UNION ALL

SELECT 
    'Biochar',
    run_id,
    temperature,
    heating_rate,
    reaction_time,
    biochar_yield,
    bio_oil_yield,
    temp_category,
    heating_rate_category,
    reaction_time_category
FROM vw_experiment_summary
WHERE biochar_yield = (SELECT MAX(biochar_yield) FROM product_yields)

UNION ALL

SELECT 
    'Gas',
    run_id,
    temperature,
    heating_rate,
    reaction_time,
    gas_yield,
    bio_oil_yield,
    temp_category,
    heating_rate_category,
    reaction_time_category
FROM vw_experiment_summary
WHERE gas_yield = (SELECT MAX(gas_yield) FROM product_yields);
GO


-- ============================================================================
-- VIEW 4: vw_kpi_dashboard
-- Single-row view with all KPI metrics for Power BI cards
-- ============================================================================
CREATE OR ALTER VIEW vw_kpi_dashboard AS
SELECT 
    ROUND(MAX(py.bio_oil_yield), 2)                AS max_bio_oil_yield,
    ROUND(MAX(py.biochar_yield), 2)                AS max_biochar_yield,
    ROUND(AVG(py.bio_oil_yield), 2)                AS avg_bio_oil_yield,
    ROUND(AVG(py.biochar_yield), 2)                AS avg_biochar_yield,
    ROUND(AVG(py.gas_yield), 2)                    AS avg_gas_yield,
    COUNT(*)                                        AS total_experiments,
    ROUND(MAX(py.bio_oil_yield) - MIN(py.bio_oil_yield), 2) AS bio_oil_range,
    ROUND(MAX(py.biochar_yield) - MIN(py.biochar_yield), 2) AS biochar_range,
    ROUND(AVG(py.total_liquid_yield), 2)           AS avg_total_product,
    (SELECT TOP 1 temperature FROM experiment_parameters ep2
     JOIN product_yields py2 ON ep2.run_id = py2.run_id 
     ORDER BY py2.bio_oil_yield DESC)               AS optimal_temp_bio_oil,
    (SELECT TOP 1 heating_rate FROM experiment_parameters ep2
     JOIN product_yields py2 ON ep2.run_id = py2.run_id 
     ORDER BY py2.bio_oil_yield DESC)               AS optimal_hr_bio_oil,
    (SELECT TOP 1 reaction_time FROM experiment_parameters ep2
     JOIN product_yields py2 ON ep2.run_id = py2.run_id 
     ORDER BY py2.bio_oil_yield DESC)               AS optimal_rt_bio_oil
FROM product_yields py;
GO


-- ============================================================================
-- VIEW 5: vw_parameter_sensitivity
-- Shows which parameter has the greatest influence on bio-oil yield
-- ============================================================================
CREATE OR ALTER VIEW vw_parameter_sensitivity AS
SELECT 'Temperature' AS parameter_name,
    ROUND(MAX(avg_val) - MIN(avg_val), 2) AS sensitivity_range,
    ROUND(MIN(avg_val), 2) AS min_avg,
    ROUND(MAX(avg_val), 2) AS max_avg
FROM (SELECT AVG(bio_oil_yield) AS avg_val FROM vw_experiment_summary GROUP BY temperature) t
UNION ALL
SELECT 'Heating Rate',
    ROUND(MAX(avg_val) - MIN(avg_val), 2),
    ROUND(MIN(avg_val), 2),
    ROUND(MAX(avg_val), 2)
FROM (SELECT AVG(bio_oil_yield) AS avg_val FROM vw_experiment_summary GROUP BY heating_rate) t
UNION ALL
SELECT 'Reaction Time',
    ROUND(MAX(avg_val) - MIN(avg_val), 2),
    ROUND(MIN(avg_val), 2),
    ROUND(MAX(avg_val), 2)
FROM (SELECT AVG(bio_oil_yield) AS avg_val FROM vw_experiment_summary GROUP BY reaction_time) t;
GO


-- ============================================================================
-- STORED PROCEDURE 1: sp_GetYieldByParameter
-- Retrieves yield data filtered by a specific parameter and value
-- Usage: EXEC sp_GetYieldByParameter 'Temperature', 600
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetYieldByParameter
    @ParameterName VARCHAR(20),     -- 'Temperature', 'HeatingRate', 'ReactionTime'
    @ParameterValue INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @ParameterName = 'Temperature'
        SELECT * FROM vw_experiment_summary WHERE temperature = @ParameterValue;
    ELSE IF @ParameterName = 'HeatingRate'
        SELECT * FROM vw_experiment_summary WHERE heating_rate = @ParameterValue;
    ELSE IF @ParameterName = 'ReactionTime'
        SELECT * FROM vw_experiment_summary WHERE reaction_time = @ParameterValue;
    ELSE
        RAISERROR('Invalid parameter name. Use: Temperature, HeatingRate, or ReactionTime', 16, 1);
END;
GO


-- ============================================================================
-- STORED PROCEDURE 2: sp_GetOptimalConditions
-- Returns optimal conditions for a specified target product
-- Usage: EXEC sp_GetOptimalConditions 'Bio-Oil'
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GetOptimalConditions
    @TargetProduct VARCHAR(20)      -- 'Bio-Oil', 'Biochar', 'Gas'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        target_product,
        run_id,
        temperature AS optimal_temperature,
        heating_rate AS optimal_heating_rate,
        reaction_time AS optimal_reaction_time,
        max_yield,
        secondary_yield,
        temp_category,
        heating_rate_category,
        reaction_time_category
    FROM vw_optimal_conditions
    WHERE target_product = @TargetProduct;
    
    -- Also return parameter sensitivity
    SELECT * FROM vw_parameter_sensitivity;
END;
GO


-- ============================================================================
-- STORED PROCEDURE 3: sp_GenerateReport
-- Generates a comprehensive analysis report
-- Usage: EXEC sp_GenerateReport
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_GenerateReport
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== CO-PYROLYSIS ANALYTICS REPORT ===';
    PRINT '';
    
    -- Section 1: KPI Summary
    PRINT '--- KPI SUMMARY ---';
    SELECT * FROM vw_kpi_dashboard;
    
    -- Section 2: Temperature Analysis
    PRINT '--- TEMPERATURE ANALYSIS ---';
    SELECT * FROM vw_temperature_analysis ORDER BY temperature;
    
    -- Section 3: Optimal Conditions
    PRINT '--- OPTIMAL CONDITIONS ---';
    SELECT * FROM vw_optimal_conditions;
    
    -- Section 4: Parameter Sensitivity
    PRINT '--- PARAMETER SENSITIVITY ---';
    SELECT * FROM vw_parameter_sensitivity ORDER BY sensitivity_range DESC;
    
    -- Section 5: Full Data
    PRINT '--- COMPLETE EXPERIMENT DATA ---';
    SELECT * FROM vw_experiment_summary ORDER BY run_id;
    
    PRINT '';
    PRINT '=== REPORT COMPLETE ===';
END;
GO


-- ============================================================================
-- STORED PROCEDURE 4: sp_CompareConditions
-- Compares two experimental runs side by side
-- Usage: EXEC sp_CompareConditions 8, 15
-- ============================================================================
CREATE OR ALTER PROCEDURE sp_CompareConditions
    @RunId1 INT,
    @RunId2 INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        'Run ' + CAST(run_id AS VARCHAR) AS Experiment,
        temperature AS [Temp (°C)],
        heating_rate AS [Heating Rate (°C/min)],
        reaction_time AS [Reaction Time (min)],
        bio_oil_yield AS [Bio-Oil (%)],
        biochar_yield AS [Biochar (%)],
        gas_yield AS [Gas (%)],
        bio_oil_performance AS [Bio-Oil Rating],
        biochar_performance AS [Biochar Rating]
    FROM vw_experiment_summary
    WHERE run_id IN (@RunId1, @RunId2)
    ORDER BY run_id;
END;
GO

PRINT '✅ All views and stored procedures created successfully.';
GO
