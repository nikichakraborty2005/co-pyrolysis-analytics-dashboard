-- ============================================================================
-- CO-PYROLYSIS ANALYTICS — POWER BI OPTIMIZED QUERIES
-- Pre-built queries designed for specific Power BI visuals
-- ============================================================================
-- Each query is optimized for a specific Power BI visual component
-- Import these as separate queries in Power BI (Get Data → SQL Server)
-- ============================================================================

USE CoPyrolysisAnalytics;
GO

-- ============================================================================
-- POWER BI QUERY 1: KPI CARDS
-- Visual: Card / Multi-row Card
-- Purpose: Display key performance indicators at the top of the dashboard
-- Power BI Setup: Create 4 Card visuals, one for each KPI metric
-- ============================================================================
SELECT 
    MAX(bio_oil_yield)                              AS [Max Bio-Oil Yield (%)],
    MAX(biochar_yield)                              AS [Max Biochar Yield (%)],
    ROUND(AVG(bio_oil_yield), 1)                   AS [Avg Bio-Oil Yield (%)],
    ROUND(AVG(biochar_yield), 1)                   AS [Avg Biochar Yield (%)],
    ROUND(AVG(gas_yield), 1)                       AS [Avg Gas Yield (%)],
    COUNT(*)                                        AS [Total Experiments],
    ROUND(MAX(bio_oil_yield) - MIN(bio_oil_yield), 1) AS [Bio-Oil Range (%)],
    ROUND(MAX(biochar_yield) - MIN(biochar_yield), 1) AS [Biochar Range (%)]
FROM product_yields;
GO


-- ============================================================================
-- POWER BI QUERY 2: CLUSTERED BAR CHART — Yield by Temperature
-- Visual: Clustered Bar Chart
-- X-Axis: Temperature_Group | Y-Values: Avg_BioOil, Avg_Biochar
-- Purpose: Compare product yields across temperature levels
-- Color: Bio-Oil → #F59E0B (Amber), Biochar → #10B981 (Emerald)
-- ============================================================================
SELECT 
    CAST(ep.temperature AS VARCHAR) + '°C'          AS Temperature_Group,
    ep.temperature                                   AS Temperature_Sort,
    ROUND(AVG(py.bio_oil_yield), 2)                 AS Avg_BioOil_Yield,
    ROUND(AVG(py.biochar_yield), 2)                 AS Avg_Biochar_Yield,
    ROUND(AVG(py.gas_yield), 2)                     AS Avg_Gas_Yield,
    COUNT(*)                                         AS Num_Experiments
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.temperature
ORDER BY ep.temperature;
GO


-- ============================================================================
-- POWER BI QUERY 3: SCATTER PLOT — Temperature vs Bio-Oil Yield
-- Visual: Scatter Chart
-- X-Axis: Temperature | Y-Axis: Bio_Oil_Yield | Legend: Heating_Rate
-- Size: Biochar_Yield (optional bubble size)
-- Purpose: Visualize correlation between temperature and bio-oil yield
-- Add Trend Line via Analytics pane
-- ============================================================================
SELECT 
    ep.run_id                                       AS Run,
    ep.temperature                                  AS Temperature_C,
    ep.heating_rate                                 AS Heating_Rate,
    ep.reaction_time                                AS Reaction_Time,
    py.bio_oil_yield                                AS Bio_Oil_Yield,
    py.biochar_yield                                AS Biochar_Yield,
    py.gas_yield                                    AS Gas_Yield,
    CAST(ep.heating_rate AS VARCHAR) + '°C/min'     AS Heating_Rate_Label,
    CAST(ep.reaction_time AS VARCHAR) + ' min'      AS Reaction_Time_Label
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY ep.temperature, ep.heating_rate;
GO


-- ============================================================================
-- POWER BI QUERY 4: STACKED BAR CHART — Product Distribution by Run
-- Visual: Stacked Bar Chart
-- X-Axis: Run_Label | Y-Values: Bio_Oil, Biochar, Gas (stacked)
-- Purpose: Show complete product distribution for each experiment
-- Colors: Bio-Oil → #F59E0B, Biochar → #10B981, Gas → #6366F1
-- ============================================================================
SELECT 
    'Run ' + CAST(ep.run_id AS VARCHAR)             AS Run_Label,
    ep.run_id                                       AS Run_Sort,
    py.bio_oil_yield                                AS [Bio-Oil Yield (%)],
    py.biochar_yield                                AS [Biochar Yield (%)],
    py.gas_yield                                    AS [Gas Yield (%)],
    ep.temperature                                  AS Temperature,
    ep.heating_rate                                 AS Heating_Rate,
    ep.reaction_time                                AS Reaction_Time
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY ep.run_id;
GO


-- ============================================================================
-- POWER BI QUERY 5: DOUGHNUT CHART — Average Product Distribution
-- Visual: Donut Chart
-- Values: Avg_Percentage | Legend: Product_Type
-- Purpose: Overall product split across all experiments
-- ============================================================================
SELECT 'Bio-Oil' AS Product_Type, 
    ROUND(AVG(bio_oil_yield), 2) AS Avg_Yield,
    '#F59E0B' AS Color_Code,
    1 AS Sort_Order
FROM product_yields
UNION ALL
SELECT 'Biochar', 
    ROUND(AVG(biochar_yield), 2),
    '#10B981',
    2
FROM product_yields
UNION ALL
SELECT 'Gas', 
    ROUND(AVG(gas_yield), 2),
    '#6366F1',
    3
FROM product_yields
ORDER BY Sort_Order;
GO


-- ============================================================================
-- POWER BI QUERY 6: LINE CHART — Yield Trends by Temperature
-- Visual: Line Chart
-- X-Axis: Temperature | Y-Values: Bio-Oil, Biochar, Gas (3 lines)
-- Purpose: Show yield trends as temperature increases
-- Enable Markers and Data Labels
-- ============================================================================
SELECT 
    ep.temperature                                  AS Temperature,
    ROUND(AVG(py.bio_oil_yield), 2)                AS [Avg Bio-Oil (%)],
    ROUND(AVG(py.biochar_yield), 2)                AS [Avg Biochar (%)],
    ROUND(AVG(py.gas_yield), 2)                    AS [Avg Gas (%)],
    ROUND(AVG(py.total_liquid_yield), 2)           AS [Avg Total Product (%)]
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.temperature
ORDER BY ep.temperature;
GO


-- ============================================================================
-- POWER BI QUERY 7: MATRIX / HEATMAP — Temperature × Heating Rate
-- Visual: Matrix with Conditional Formatting
-- Rows: Temperature | Columns: Heating_Rate | Values: Avg Bio-Oil
-- Purpose: Identify optimal parameter combinations
-- Apply Background Color Scale: Red (low) → Yellow → Green (high)
-- ============================================================================
SELECT 
    CAST(ep.temperature AS VARCHAR) + '°C'          AS Temperature,
    ep.temperature                                   AS Temp_Sort,
    CAST(ep.heating_rate AS VARCHAR) + '°C/min'     AS Heating_Rate,
    ep.heating_rate                                  AS HR_Sort,
    ROUND(AVG(py.bio_oil_yield), 2)                 AS Avg_BioOil,
    ROUND(AVG(py.biochar_yield), 2)                 AS Avg_Biochar,
    COUNT(*)                                         AS Num_Runs
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
GROUP BY ep.temperature, ep.heating_rate
ORDER BY ep.temperature, ep.heating_rate;
GO


-- ============================================================================
-- POWER BI QUERY 8: DATA TABLE
-- Visual: Table
-- Purpose: Detailed experiment data table with conditional formatting
-- Format: Apply data bars on yield columns, conditional colors on performance
-- ============================================================================
SELECT 
    ep.run_id                                       AS [Run ID],
    CAST(ep.temperature AS VARCHAR) + '°C'          AS [Temperature],
    CAST(ep.heating_rate AS VARCHAR) + '°C/min'     AS [Heating Rate],
    CAST(ep.reaction_time AS VARCHAR) + ' min'      AS [Reaction Time],
    py.bio_oil_yield                                AS [Bio-Oil Yield (%)],
    py.biochar_yield                                AS [Biochar Yield (%)],
    py.gas_yield                                    AS [Gas Yield (%)],
    py.total_liquid_yield                           AS [Total Product (%)],
    CASE 
        WHEN py.bio_oil_yield >= 15 THEN '🟢 High'
        WHEN py.bio_oil_yield >= 10 THEN '🟡 Medium'
        ELSE '🔴 Low'
    END                                              AS [Bio-Oil Rating],
    RANK() OVER (ORDER BY py.bio_oil_yield DESC)    AS [Bio-Oil Rank]
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id
ORDER BY ep.run_id;
GO


-- ============================================================================
-- POWER BI QUERY 9: BUBBLE CHART — Multi-Parameter Analysis
-- Visual: Scatter Chart (with Size)
-- X-Axis: Temperature | Y-Axis: Bio-Oil | Size: Biochar | Color: Heating Rate
-- Purpose: Visualize 4 dimensions simultaneously
-- ============================================================================
SELECT 
    ep.run_id                                       AS Run,
    ep.temperature                                  AS [Temperature (°C)],
    py.bio_oil_yield                                AS [Bio-Oil Yield (%)],
    py.biochar_yield                                AS [Biochar Yield (%)],
    ep.heating_rate                                 AS [Heating Rate (°C/min)],
    ep.reaction_time                                AS [Reaction Time (min)],
    py.gas_yield                                    AS [Gas Yield (%)],
    -- Normalized values for radar chart (0-1 scale)
    ROUND(CAST(ep.temperature - 400 AS FLOAT) / 200, 2) AS Temp_Normalized,
    ROUND(CAST(ep.heating_rate - 10 AS FLOAT) / 40, 2) AS HR_Normalized,
    ROUND(CAST(ep.reaction_time - 10 AS FLOAT) / 30, 2) AS RT_Normalized
FROM experiment_parameters ep
JOIN product_yields py ON ep.run_id = py.run_id;
GO


-- ============================================================================
-- POWER BI QUERY 10: SLICER DATA
-- Visual: Slicer (Tile/Dropdown)
-- Purpose: Provide filter values for interactive slicers
-- Create 3 separate slicers: Temperature, Heating Rate, Reaction Time
-- ============================================================================

-- Temperature Slicer Values
SELECT DISTINCT temperature AS Temperature_C,
    CAST(temperature AS VARCHAR) + '°C' AS Temperature_Label
FROM experiment_parameters ORDER BY temperature;

-- Heating Rate Slicer Values  
SELECT DISTINCT heating_rate AS Heating_Rate,
    CAST(heating_rate AS VARCHAR) + '°C/min' AS Heating_Rate_Label
FROM experiment_parameters ORDER BY heating_rate;

-- Reaction Time Slicer Values
SELECT DISTINCT reaction_time AS Reaction_Time,
    CAST(reaction_time AS VARCHAR) + ' min' AS Reaction_Time_Label
FROM experiment_parameters ORDER BY reaction_time;
GO


-- ============================================================================
-- POWER BI QUERY 11: PARAMETER SENSITIVITY BAR CHART
-- Visual: Bar Chart
-- X-Axis: Parameter | Y-Value: Sensitivity_Range
-- Purpose: Show which parameter has the greatest impact on bio-oil yield
-- ============================================================================
SELECT * FROM vw_parameter_sensitivity
ORDER BY sensitivity_range DESC;
GO


PRINT '✅ All Power BI queries ready for import.';
GO
