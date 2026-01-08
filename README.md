# Telco Customer Churn & Revenue Risk Analysis

## Objective
Identify key churn drivers and quantify revenue at risk by analyzing customer behavior,
service experience, and CLTV to recommend high-impact retention strategies.

## Dataset
- 7,043 telecom customers
- Customer demographics, contract details, service usage, satisfaction, revenue, and CLTV

## Tools Used
- SQL (PostgreSQL/MySQL compatible)
- Power BI
- DAX

## Key Insights
- Overall churn rate: 26.54%
- Revenue at risk due to churn: 17.24% ($3.68M)
- San Diego identified as a churn outlier (~65%)
- Fiber Optic customers without Premium Tech Support churn at the highest rate
- Medium-CLTV customers contribute the highest revenue loss
- Referred customers churn ~50% less than non-referred

## What-If Analysis
- 5% churn reduction → $184K revenue saved
- 10% Medium-CLTV retention → $282K revenue protected

## Dashboard Pages
1. Executive Overview
2. Churn Deep-Dive Analysis
3. Revenue & Retention Strategy
4. What-If Analysis (Scenario Simulation)

## Business Recommendations
- Improve early-tenure onboarding (first 90 days)
- Bundle Premium Tech Support with Fiber Optic plans
- Prioritize Medium-CLTV customers for retention
- Expand referral programs to reduce churn

## Files
- `/Telco Churn Analysis.sql/` → All analysis queries
- `/Telco Dashbaord/` → Dashboard screenshots
- `README.md` → Project documentation
