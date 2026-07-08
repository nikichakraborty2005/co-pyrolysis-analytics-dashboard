-- ============================================================================
-- CO-PYROLYSIS ANALYTICS — ANALYTICAL QUERIES
-- 15+ Comprehensive SQL Queries for Data Analysis
-- ============================================================================
-- Database: CoPyrolysisAnalytics
-- Purpose: Extract insights on temperature, heating rate, and reaction time
--          effects on bio-oil, biochar, and gas yields
-- ============================================================================

USE CoPyrolysisAnalytics;
GO

-- ============================================================================
-- QUERY 1: SUMMARY STATISTICS
-- Overview of all yield metrics across all experiments
-- Purpose: Quick snapshot of data distribution for dashboard KPIs
-- ============================================================================
SELECT 
    'Bio-Oil Yield (%)'    AS Metric,
    COUNT(*)               AS Total_Runs,
    ROUND(AVG(bio_oil_yield), 2)   AS Average,
    ROUND(MIN(bio_oil_yield), 2)   AS Minimum,
    ROUND(MAX(bio_oil_yield), 2)   AS Maximum,
    ROUND(MAX(bio_oil_yield) - MIN(bio_oil_yield), 2) AS Range,
    ROUND(STDEV(bio_oil_yield), 2) AS Std_Deviation
FROM product_yields
UNION ALL
SELECT 
    'Biochar Yield (%)',
    COUNT(*),
    ROUND(AVG(biochar_yield), 2),
    ROUND(MIN(biochar_yield), 2),
    ROUND(MAX(biochar_yield), 2),
    ROUND(MAX(biochar_yield) - MIN(biochar_yield), 2),
    ROUND(STDEV(biochar_yield), 2)
FROM product_yields
UNION ALL
SELECT 
    'Gas Yield (%)',
    COUNT(*),
    ROUND(AVG(gas_yield), 2),
    ROUND(MIN(gas_yield), 2),
    ROUND(MAX(gas_yield), 2),
    ROUND(MAX(gas_yield) - MIN(gas_yield), 2),
    ROUND(STDEV(gas_yield), 2)
FROM product_yields;
GO


-- ============================================================================
-- QUERY 2: TEMPERATURE IMPACT ANALYSIS
-- Analyzes how temperature affects yields — the dominant process parameter
-- Finding: 600°C produces the highest bio-oil yield (avg 17.35%)
-- ============================================================================
SELECT 
    ep.temperature                              AS Temperature_C,
    COUNT(*)                                    AS Num_Runs,
    ROUND(AVG(py.bio_oil_yield), 2)            AS Avg_BioOil,
    ROUND(AVG(py.biochar_yield), 2)            AS Avg_Biochar,
    ROUND(AVG(py.gas_yield), 2)                AS Avg_Gas,
    ROUND(MAX(py.bio_oil_yield), 2)            AS Max_BioOil,
    ROUND(MAX(py.biochar_yield), 2)            AS Max_Biochar,
    RANK() OVER (ORDER BY AVG(py.bio_oil_yield) DESC) AS BioOil_Rank,
    RANK() OVER (ORDER BY AVG(py.biochar_yield) DESC) AS Biochar_Rank
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.temperature
ORDER BY ep.temperature;
GO


-- ============================================================================
-- QUERY 3: HEATING RATE IMPACT ANALYSIS
-- Analyzes heating rate effect on product yields
-- Finding: Low heating rate (10°C/min) favors bio-oil; High (50°C/min) favors biochar
-- ============================================================================
SELECT 
    ep.heating_rate                             AS Heating_Rate_C_per_min,
    COUNT(*)                                    AS Num_Runs,
    ROUND(AVG(py.bio_oil_yield), 2)            AS Avg_BioOil,
    ROUND(AVG(py.biochar_yield), 2)            AS Avg_Biochar,
    ROUND(AVG(py.gas_yield), 2)                AS Avg_Gas,
    ROUND(MAX(py.bio_oil_yield), 2)            AS Max_BioOil,
    ROUND(MAX(py.biochar_yield), 2)            AS Max_Biochar,
    RANK() OVER (ORDER BY AVG(py.bio_oil_yield) DESC) AS BioOil_Rank
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.heating_rate
ORDER BY ep.heating_rate;
GO


-- ============================================================================
-- QUERY 4: REACTION TIME IMPACT ANALYSIS
-- Analyzes how reaction time affects product formation
-- Finding: 40 min reaction time shows higher bio-oil at elevated temperatures
-- ============================================================================
SELECT 
    ep.reaction_time                            AS Reaction_Time_min,
    COUNT(*)                                    AS Num_Runs,
    ROUND(AVG(py.bio_oil_yield), 2)            AS Avg_BioOil,
    ROUND(AVG(py.biochar_yield), 2)            AS Avg_Biochar,
    ROUND(AVG(py.gas_yield), 2)                AS Avg_Gas,
    ROUND(MAX(py.bio_oil_yield), 2)            AS Max_BioOil,
    RANK() OVER (ORDER BY AVG(py.bio_oil_yield) DESC) AS BioOil_Rank
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.reaction_time
ORDER BY ep.reaction_time;
GO


-- ============================================================================
-- QUERY 5: TOP 5 RUNS BY BIO-OIL YIELD
-- Identifies the best experimental conditions for bio-oil production
-- Key Result: Run 8 (600°C, 30°C/min, 25 min) = 21.5% bio-oil
-- ============================================================================
SELECT TOP 5
    ep.run_id,
    ep.temperature                              AS Temp_C,
    ep.heating_rate                             AS HR_C_per_min,
    ep.reaction_time                            AS RT_min,
    py.bio_oil_yield                            AS BioOil_Pct,
    py.biochar_yield                            AS Biochar_Pct,
    py.gas_yield                                AS Gas_Pct,
    RANK() OVER (ORDER BY py.bio_oil_yield DESC) AS Rank
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY py.bio_oil_yield DESC;
GO


-- ============================================================================
-- QUERY 6: TOP 5 RUNS BY BIOCHAR YIELD
-- Identifies optimal conditions for biochar production (supercapacitor application)
-- Key Result: Run 15 (500°C, 50°C/min, 25 min) = 14.5% biochar
-- ============================================================================
SELECT TOP 5
    ep.run_id,
    ep.temperature                              AS Temp_C,
    ep.heating_rate                             AS HR_C_per_min,
    ep.reaction_time                            AS RT_min,
    py.biochar_yield                            AS Biochar_Pct,
    py.bio_oil_yield                            AS BioOil_Pct,
    py.gas_yield                                AS Gas_Pct,
    RANK() OVER (ORDER BY py.biochar_yield DESC) AS Rank
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY py.biochar_yield DESC;
GO


-- ============================================================================
-- QUERY 7: ABOVE-AVERAGE BIO-OIL PERFORMERS
-- Filters runs where bio-oil yield exceeds the overall average
-- Useful for identifying favorable parameter combinations
-- ============================================================================
SELECT 
    ep.run_id,
    ep.temperature,
    ep.heating_rate,
    ep.reaction_time,
    py.bio_oil_yield,
    ROUND(py.bio_oil_yield - (SELECT AVG(bio_oil_yield) FROM product_yields), 2) AS Above_Avg_By,
    pc.temp_category,
    pc.heating_rate_category,
    pc.reaction_time_category
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
JOIN process_conditions pc ON ep.run_id = pc.run_id
WHERE py.bio_oil_yield > (SELECT AVG(bio_oil_yield) FROM product_yields)
ORDER BY py.bio_oil_yield DESC;
GO


-- ============================================================================
-- QUERY 8: PRODUCT DISTRIBUTION BY TEMPERATURE GROUP
-- Shows how product mix changes across temperature levels
-- Finding: Higher temperature shifts distribution toward bio-oil and gas
-- ============================================================================
SELECT 
    pc.temp_category,
    ep.temperature,
    ROUND(AVG(py.bio_oil_yield), 2)     AS Avg_BioOil_Pct,
    ROUND(AVG(py.biochar_yield), 2)     AS Avg_Biochar_Pct,
    ROUND(AVG(py.gas_yield), 2)         AS Avg_Gas_Pct,
    ROUND(AVG(py.bio_oil_yield) / 
        (AVG(py.bio_oil_yield) + AVG(py.biochar_yield) + AVG(py.gas_yield)) * 100, 2) 
        AS BioOil_Distribution_Pct,
    ROUND(AVG(py.biochar_yield) / 
        (AVG(py.bio_oil_yield) + AVG(py.biochar_yield) + AVG(py.gas_yield)) * 100, 2) 
        AS Biochar_Distribution_Pct
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
JOIN process_conditions pc ON ep.run_id = pc.run_id
GROUP BY pc.temp_category, ep.temperature
ORDER BY ep.temperature;
GO


-- ============================================================================
-- QUERY 9: COMBINED EFFECT — TEMPERATURE × HEATING RATE ON BIO-OIL
-- Cross-tabulation (pivot) showing interaction between two parameters
-- Reveals synergistic effects between temperature and heating rate
-- ============================================================================
SELECT 
    ep.temperature AS Temperature_C,
    ROUND(AVG(CASE WHEN ep.heating_rate = 10 THEN py.bio_oil_yield END), 2) AS [HR_10_C/min],
    ROUND(AVG(CASE WHEN ep.heating_rate = 30 THEN py.bio_oil_yield END), 2) AS [HR_30_C/min],
    ROUND(AVG(CASE WHEN ep.heating_rate = 50 THEN py.bio_oil_yield END), 2) AS [HR_50_C/min],
    ROUND(AVG(py.bio_oil_yield), 2) AS Overall_Avg
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.temperature
ORDER BY ep.temperature;
GO


-- ============================================================================
-- QUERY 10: OPTIMAL CONDITIONS USING WINDOW FUNCTIONS
-- Identifies best run for each parameter combination using advanced analytics
-- Uses ROW_NUMBER() to rank within temperature groups
-- ============================================================================
SELECT * FROM (
    SELECT 
        ep.run_id,
        ep.temperature,
        ep.heating_rate,
        ep.reaction_time,
        py.bio_oil_yield,
        py.biochar_yield,
        ROW_NUMBER() OVER (
            PARTITION BY ep.temperature 
            ORDER BY py.bio_oil_yield DESC
        ) AS Rank_Within_Temp,
        ROUND(py.bio_oil_yield - AVG(py.bio_oil_yield) OVER (PARTITION BY ep.temperature), 2) 
            AS Deviation_From_Temp_Avg
    FROM experiment_parameters ep
    JOIN product_yields py ON ep.run_id = py.run_id
) ranked
WHERE Rank_Within_Temp = 1
ORDER BY temperature;
GO


-- ============================================================================
-- QUERY 11: RUNNING AVERAGES AND CUMULATIVE ANALYSIS
-- Calculates running average bio-oil yield ordered by run_id
-- Useful for trend identification across experimental sequence
-- ============================================================================
SELECT 
    ep.run_id,
    ep.temperature,
    py.bio_oil_yield,
    py.biochar_yield,
    ROUND(AVG(py.bio_oil_yield) OVER (
        ORDER BY ep.run_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS Running_Avg_BioOil,
    ROUND(SUM(py.bio_oil_yield) OVER (
        ORDER BY ep.run_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS Cumulative_BioOil,
    ROUND(AVG(py.biochar_yield) OVER (
        ORDER BY ep.run_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS Running_Avg_Biochar
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY ep.run_id;
GO


-- ============================================================================
-- QUERY 12: PARAMETER SENSITIVITY RANKING
-- Measures the range (max - min of avg) for each parameter to determine
-- which parameter has the most significant impact on bio-oil yield
-- Finding: Temperature has highest sensitivity (largest range)
-- ============================================================================
SELECT 'Temperature' AS Parameter,
    ROUND(MAX(avg_yield) - MIN(avg_yield), 2) AS Sensitivity_Range,
    ROUND(MAX(avg_yield), 2) AS Max_Avg_Yield,
    ROUND(MIN(avg_yield), 2) AS Min_Avg_Yield,
    RANK() OVER (ORDER BY MAX(avg_yield) - MIN(avg_yield) DESC) AS Sensitivity_Rank
FROM (
    SELECT ep.temperature AS param_value, AVG(py.bio_oil_yield) AS avg_yield
    FROM experiment_parameters ep JOIN product_yields py ON ep.run_id = py.run_id
    GROUP BY ep.temperature
) t
UNION ALL
SELECT 'Heating Rate',
    ROUND(MAX(avg_yield) - MIN(avg_yield), 2),
    ROUND(MAX(avg_yield), 2),
    ROUND(MIN(avg_yield), 2),
    RANK() OVER (ORDER BY MAX(avg_yield) - MIN(avg_yield) DESC)
FROM (
    SELECT ep.heating_rate AS param_value, AVG(py.bio_oil_yield) AS avg_yield
    FROM experiment_parameters ep JOIN product_yields py ON ep.run_id = py.run_id
    GROUP BY ep.heating_rate
) t
UNION ALL
SELECT 'Reaction Time',
    ROUND(MAX(avg_yield) - MIN(avg_yield), 2),
    ROUND(MAX(avg_yield), 2),
    ROUND(MIN(avg_yield), 2),
    RANK() OVER (ORDER BY MAX(avg_yield) - MIN(avg_yield) DESC)
FROM (
    SELECT ep.reaction_time AS param_value, AVG(py.bio_oil_yield) AS avg_yield
    FROM experiment_parameters ep JOIN product_yields py ON ep.run_id = py.run_id
    GROUP BY ep.reaction_time
) t
ORDER BY Sensitivity_Range DESC;
GO


-- ============================================================================
-- QUERY 13: YIELD EFFICIENCY RATIO
-- Calculates the bio-oil to biochar ratio for each run
-- High ratio = favorable for biofuel; Low ratio = favorable for biochar applications
-- ============================================================================
SELECT 
    ep.run_id,
    ep.temperature,
    ep.heating_rate,
    ep.reaction_time,
    py.bio_oil_yield,
    py.biochar_yield,
    CASE 
        WHEN py.biochar_yield > 0 
        THEN ROUND(py.bio_oil_yield / py.biochar_yield, 2) 
        ELSE NULL 
    END AS BioOil_to_Biochar_Ratio,
    ROUND(py.total_liquid_yield, 2) AS Total_Solid_Liquid,
    CASE 
        WHEN py.bio_oil_yield / NULLIF(py.biochar_yield, 0) > 2 THEN 'Biofuel Favorable'
        WHEN py.bio_oil_yield / NULLIF(py.biochar_yield, 0) BETWEEN 1 AND 2 THEN 'Balanced'
        ELSE 'Biochar Favorable'
    END AS Process_Classification
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY BioOil_to_Biochar_Ratio DESC;
GO


-- ============================================================================
-- QUERY 14: TEMPERATURE BINS PERFORMANCE COMPARISON
-- Detailed performance metrics per temperature category
-- Includes percentile rankings and efficiency scores
-- ============================================================================
SELECT 
    pc.temp_category,
    ep.temperature,
    COUNT(*) AS Experiments,
    ROUND(AVG(py.bio_oil_yield), 2) AS Avg_BioOil,
    ROUND(AVG(py.biochar_yield), 2) AS Avg_Biochar,
    ROUND(AVG(py.gas_yield), 2) AS Avg_Gas,
    ROUND(AVG(py.total_liquid_yield), 2) AS Avg_Total_Product,
    ROUND(STDEV(py.bio_oil_yield), 2) AS StdDev_BioOil,
    ROUND(
        AVG(py.bio_oil_yield) / NULLIF(STDEV(py.bio_oil_yield), 0), 2
    ) AS Consistency_Score,  -- Higher = more consistent yields
    CASE 
        WHEN AVG(py.bio_oil_yield) = MAX(AVG(py.bio_oil_yield)) OVER () 
        THEN '★ BEST' 
        ELSE '' 
    END AS BioOil_Status
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
JOIN process_conditions pc ON ep.run_id = pc.run_id
GROUP BY pc.temp_category, ep.temperature
ORDER BY ep.temperature;
GO


-- ============================================================================
-- QUERY 15: COMPREHENSIVE DASHBOARD SUMMARY VIEW
-- Single query providing all KPI metrics for a Power BI dashboard
-- This is the master query for executive summary
-- ============================================================================
SELECT 
    -- KPI Metrics
    (SELECT ROUND(MAX(bio_oil_yield), 2) FROM product_yields) AS Max_BioOil_Yield,
    (SELECT ROUND(MAX(biochar_yield), 2) FROM product_yields) AS Max_Biochar_Yield,
    (SELECT ROUND(AVG(bio_oil_yield), 2) FROM product_yields) AS Avg_BioOil_Yield,
    (SELECT ROUND(AVG(biochar_yield), 2) FROM product_yields) AS Avg_Biochar_Yield,
    (SELECT ROUND(AVG(gas_yield), 2) FROM product_yields) AS Avg_Gas_Yield,
    (SELECT COUNT(*) FROM experiment_parameters) AS Total_Experiments,
    
    -- Optimal Conditions for Bio-Oil
    (SELECT TOP 1 ep.temperature FROM experiment_parameters ep 
     JOIN product_yields py ON ep.run_id = py.run_id 
     ORDER BY py.bio_oil_yield DESC) AS Optimal_Temp_BioOil,
    (SELECT TOP 1 ep.heating_rate FROM experiment_parameters ep 
     JOIN product_yields py ON ep.run_id = py.run_id 
     ORDER BY py.bio_oil_yield DESC) AS Optimal_HR_BioOil,
    (SELECT TOP 1 ep.reaction_time FROM experiment_parameters ep 
     JOIN product_yields py ON ep.run_id = py.run_id 
     ORDER BY py.bio_oil_yield DESC) AS Optimal_RT_BioOil,
    
    -- Yield Range
    (SELECT ROUND(MAX(bio_oil_yield) - MIN(bio_oil_yield), 2) FROM product_yields) AS BioOil_Range,
    (SELECT ROUND(MAX(biochar_yield) - MIN(biochar_yield), 2) FROM product_yields) AS Biochar_Range;
GO


-- ============================================================================
-- QUERY 16: PERCENTILE ANALYSIS OF BIO-OIL YIELD
-- Categorizes each run into performance quartiles
-- ============================================================================
SELECT 
    ep.run_id,
    ep.temperature,
    ep.heating_rate,
    ep.reaction_time,
    py.bio_oil_yield,
    NTILE(4) OVER (ORDER BY py.bio_oil_yield DESC) AS Performance_Quartile,
    CASE NTILE(4) OVER (ORDER BY py.bio_oil_yield DESC)
        WHEN 1 THEN 'Top 25% — Excellent'
        WHEN 2 THEN 'Above Average'
        WHEN 3 THEN 'Below Average'
        WHEN 4 THEN 'Bottom 25% — Poor'
    END AS Performance_Category,
    PERCENT_RANK() OVER (ORDER BY py.bio_oil_yield) AS Percentile_Rank
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY py.bio_oil_yield DESC;
GO


-- ============================================================================
-- QUERY 17: CORRELATION MATRIX APPROXIMATION
-- Shows average bio-oil yield for each temperature × reaction time combination
-- Helps identify interaction effects between parameters
-- ============================================================================
SELECT 
    ep.temperature AS Temperature_C,
    ROUND(AVG(CASE WHEN ep.reaction_time = 10 THEN py.bio_oil_yield END), 2) AS [RT_10min],
    ROUND(AVG(CASE WHEN ep.reaction_time = 25 THEN py.bio_oil_yield END), 2) AS [RT_25min],
    ROUND(AVG(CASE WHEN ep.reaction_time = 40 THEN py.bio_oil_yield END), 2) AS [RT_40min]
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.temperature
ORDER BY ep.temperature;
GO

PRINT '✅ All 17 analytical queries executed successfully.';
GO
