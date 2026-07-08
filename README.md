# 🔬 Co-Pyrolysis Analytics Dashboard

A SQL Server and Power BI project that analyzes the catalytic co-pyrolysis of biomass and plastic waste using interactive dashboards, SQL analysis, and DAX measures to identify optimal operating conditions and visualize product yield trends.

---

## 📌 Project Overview

This project focuses on analyzing experimental co-pyrolysis data to understand how process parameters such as **temperature**, **heating rate**, and **reaction time** influence the production of **Bio-Oil**, **Biochar**, and **Gas**.

The project demonstrates an end-to-end analytics workflow, including:

- Data preparation using SQL Server
- Analytical SQL queries
- Views and stored procedures
- Power BI dashboard development
- DAX calculations
- Interactive visualizations

---

## 🛠️ Technologies Used

- SQL Server
- Microsoft Power BI
- DAX
- Microsoft Excel

---

## 📊 Dashboard Preview

![Dashboard](screenshots/dashboard.png)

---

## ✨ Dashboard Features

- KPI Cards
  - Maximum Bio-Oil Yield
  - Maximum Biochar Yield
  - Total Experiments
  - Optimal Temperature

- Interactive Slicers
  - Temperature
  - Heating Rate
  - Reaction Time

- Visualizations
  - Temperature Impact on Product Yields
  - Heating Rate Impact on Product Yields
  - Reaction Time Impact on Product Yields
  - Temperature vs Bio-Oil Scatter Plot
  - Product Distribution by Experiment Run
  - Average Product Distribution (Donut Chart)

- Experiment Data Table

- Key Research Insights

---

## 📂 Repository Structure

```text
co-pyrolysis-analytics-dashboard
│
├── data
│   └── pyrolysis_data.csv
│
├── sql
│   ├── 01_create_database.sql
│   ├── 02_analytical_queries.sql
│   ├── 03_views_and_procedures.sql
│   └── 04_powerbi_queries.sql
│
├── powerbi
│   └── CoPyrolysisAnalytics.pbix
│
├── screenshots
│   └── dashboard.png
│
└── README.md
```

---

## 📈 SQL Analysis

The SQL scripts include:

- Database creation
- Data analysis queries
- Summary statistics
- Temperature-wise analysis
- Heating rate analysis
- Product yield comparison
- SQL Views
- Stored Procedures
- SQL queries optimized for Power BI

---

## 📊 Power BI Dashboard

The Power BI dashboard includes:

- Interactive filtering
- Dynamic KPI Cards
- Comparative charts
- Scatter Plot Analysis
- Product Distribution Analysis
- Experimental Data Table
- Research Insights

---

## 🔍 Key Insights

- Maximum Bio-Oil Yield was achieved at **600°C**.
- Higher temperatures increased gas production.
- Moderate heating rates favored Bio-Oil production.
- Reaction time significantly influenced product distribution.
- The dashboard analyzes **15 experimental runs** using SQL Server and Power BI.

---

## 🚀 How to Use

1. Download the repository.
2. Open the SQL scripts in SQL Server Management Studio.
3. Execute the scripts in sequence.
4. Open the Power BI (.pbix) file.
5. Refresh the data if required.
6. Explore the interactive dashboard.

---

## 👩‍💻 Author

**Nikita Chakraborty**

Chemical Engineering Undergraduate | MANIT Bhopal

Interested in Data Analytics, SQL, Power BI, and Data Visualization.
