/* Objective:
To identify the key drivers of customer churn and quantify revenue at risk by analyzing customer behavior,
service experience, and CLTV, in order to recommend targeted retention actions that protect high-value customers. */

select * from telco

select count(*), count(distinct customer_id)
from telco;

select customer_status, count(*)
from telco
group by customer_status;

-- Check Churn Percentage
select
count(customer_id) as total_customers,
round(count(case when customer_status = 'Churned' then customer_id end) * 100.0 / count(customer_id), 2) as churn_pct,
round(count(case when customer_status = 'Stayed' then customer_id end) *100.0 / count(customer_id), 2) as stay_pct,
round(count(case when customer_status = 'Joined' then customer_id end) *100.0 / count(customer_id), 2) as join_pct
from telco;

-- City-Level Churn Analysis
select city,
count(customer_id) as total_customers,
round(count(case when customer_status = 'Churned' then customer_id end) * 100.0 / count(customer_id), 2) as churn_pct,
round(count(case when customer_status = 'stayed' then customer_id end) *100.0 / count(customer_id), 2) as stay_pct,
round(count(case when customer_status = 'joined' then customer_id end) *100.0 / count(customer_id), 2) as join_pct
from telco
group by city
having count(customer_id) >= 100
order by total_customers desc;
#Los Angeles has the highest customer volume.
#San Diego shows an unusually high churn rate of nearly 65% which indicates a location-specific issue.

-- Contract Type Churn Break Down(San Diego)
select contract,
count(*) as customers,
round(avg(case when customer_status = 'Churned' then 1 else 0 end) * 100, 2) as churn_pct
from telco
where city = 'San Diego'
and customer_status in ('Churned', 'Stayed')
group by Contract
order by churn_pct desc;
# San Diego’s 65% city-level churn is driven almost entirely by Month-to-Month contracts.

-- Satisfaction Score by Contract(San Diego)
select
contract,
count(*) as customers,
round(avg(satisfaction_score), 2) as avg_satisfaction,
round(avg(case when customer_status = 'Churned' then satisfaction_score end), 2) as churned_satisfaction
from telco
where city = 'San Diego'
and customer_status in ('Churned', 'Stayed')
group by contract
order by avg_satisfaction;
# Churned customers across all contracts show very low satisfaction.

-- Churn Reasons by Contract (San Diego)
select
contract,
churn_category,
count(*) as churned_customers,
round(count(*) * 100.0 / sum(count(*)) over (partition by contract), 2) as pct_within_contract
from telco
where city = 'San Diego'
and churn_label = 'Yes'
group by contract, churn_category
order by contract, pct_within_contract desc;
# 83.54% month-on-month customers churn due to Competitors.

#Recommendations
# 1. Offer short-term discounts and upgrade bundles for low-satisfaction month-on-month users.
# 2. Focus on service and support.

-- Tenure vs Chunred Customers(San Diego)
select
case
when tenure_in_months <= 6 then '0–6 months'
when tenure_in_months between 7 and 12 then '7–12 months'
when tenure_in_months between 13 and 24 then '13–24 months'
else '24+ months'
end as tenure_bucket,
count(*) as churned_customers
from telco
where city = 'San Diego'
and churn_label = 'Yes'
group by tenure_bucket
order by churned_customers desc;
# Majority of customers churn within 6 months

-- Price Sensivity vs Service Quality(San Diego)
select
case when Monthly_Charge < 50 then 'Low Charge'
     when Monthly_Charge between 50 and 80 then 'Medium Charge'
else 'High Charge'
end as charge_bucket,
count(*) as churned_customers,
round(avg(Satisfaction_Score), 2) as avg_satisfaction
from telco
where city = "San Diego"
and Churn_Label = "Yes"
group by charge_bucket
order by churned_customers desc;
# Price alone is not the primary churn driver, because satisfaction is low across all charge bands.

-- Churn Rate by Internet Type(San Diego)
select
Internet_Type,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct
from telco
where city = 'San Diego'
and Customer_Status in ('Churned', 'Stayed')
group by Internet_Type
order by churn_pct desc;
# Fiber Optic(78%) is the primary service-level churn driver, far higher than all other services.

-- Premium Tech Support vs Fibre Optic Customers(San Diego)
select
Premium_Tech_Support,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct
from telco
where city = 'San Diego'
and internet_type = 'Fiber Optic'
and Customer_Status in ('Churned', 'Stayed')
group by Premium_Tech_Support
order by churn_pct desc;
/* Fiber Optic customers withoout Premium Tech Support have extremely high churn
which inidates service experience is primary lever. */

-- Fiber Optic Churn by All Cities
select
city,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct
from telco
where internet_type = 'Fiber Optic'
and Customer_Status in ('Churned', 'Stayed')
group by city
having count(*) >= 30
order by churn_pct desc;
/* Initial city-level Fiber churn showed extreme values,but most were driven by very small customer bases.
After applying a minimum sample threshold, San Diego clearly emerged as a statistical outlier.
Further segmentation showed that lack of Tech Support significantly increases Fiber churn,
with the strongest effect in San Diego. */

-- Does Early-tenure Fibre Optic Customers without premium_tech_support churn?
select
city,
premium_tech_support,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct
from telco
where tenure_in_months <= 6
and internet_type = 'Fiber Optic'
and customer_status in ('Churned', 'Stayed')
group by city, premium_tech_support
having count(*) >= 30
order by churn_pct desc;
# San Diego is uniquely broken operationally for early Fiber onboarding without support.

-- Satisfaction and Experience
select
case
when satisfaction_score <= 2 then 'Low Satisfaction (1–2)'
when satisfaction_score = 3 then 'Neutral (3)'
else 'High Satisfaction (4–5)'
end as satisfaction_segment,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct,
round(sum(total_revenue), 2) as revenue
from telco
where customer_status in ('Churned', 'Stayed')
group by satisfaction_segment
order by churn_pct desc;
# Every customer with satisfation <= 2 has churned, but they account for 2.89 Million Dollars in lost revenue
# Zero churn among satisfaction >= 4, if drops below 3 then churn becomes inevitable

# Joined Customers Churn Risk Profile
select
case
when satisfaction_score <= 3
     and contract = 'Month-to-Month'
     and premium_tech_support = 'No'
     and internet_type = 'Fiber Optic'
then 'High Risk'
else 'Low / Medium Risk'
end as risk_segment,
count(*) as joined_customers,
round(avg(monthly_charge), 2) as avg_monthly_charge,
round(sum(total_revenue), 2) as revenue_exposed
from telco
where customer_status = 'Joined'
group by risk_segment;
# Joined customers already display near-churn behavior
/* High-risk joined customers are:
1. Month-to-Month
2. Fiber Optic
3. No Tech Support
4. Low satisfaction  */

-- Engagement and Referrals
select
case when no_of_referrals > 0 then 'Referred'
else 'Not Referred'
end as referral_status,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct,
round(sum(total_revenue), 2) as revenue,
round(
  sum(total_revenue) * 100.0
  / sum(sum(total_revenue)) over (), 2
) as revenue_pct
from telco
where customer_status in ('Churned', 'Stayed')
group by referral_status;
# Referrals cut churn risk by almost half 36.1% to 19.9%
# Referred genererate 54% more revenue than non-referred indicating reffered customers are more valuable

-- CLTV Prioritization
select
customer_status,
count(*) as customers,
round(avg(cltv), 2) as avg_cltv,
round(sum(total_revenue), 2) as revenue
from telco
where customer_status in ('Churned', 'Stayed')
group by customer_status;
# Avg CLTV is not massive between churned and stayed customers
# Revenue loss is disproportionately high which indicates churn is happening before full CLTV is realized

-- CLTV Segmentation + Churn Rate
select
case
when cltv < 3000 then 'Low CLTV'
when cltv between 3000 and 6000 then 'Medium CLTV'
else 'High CLTV'
end as cltv_segment,
count(*) as customers,
round(avg(case when churn_label = 'Yes' then 1 else 0 end) * 100, 2) as churn_pct,
round(sum(total_revenue), 2) as revenue
from telco
where customer_status in ('Churned', 'Stayed')
group by cltv_segment
order by churn_pct desc;
# High-CLTV customers churn least(8.9%) and reveue($2.63M)
# Medium-CLTV Segment contributes high revenue loss($16.78M) with churn rate(27.65%)
# Low-CLTV segment has high churn rate((39.50%) but less revenue impact($1.81M)

-- Churn Reason for Medium CLTV
select
churn_category,
count(*) as churned_customers,
round(sum(total_revenue), 2) as revenue_lost,
round(
    sum(total_revenue) * 100.0 /
    sum(sum(total_revenue)) over (), 2
) as revenue_loss_pct
from telco
where churn_label = 'Yes'
and cltv between 3000 and 6000
group by churn_category
order by revenue_lost desc;
# Nearly half of Medium-CLTV revenue loss is due to competitor switching
# Price is not the primary issue which confirms customers are willing to pay but leave due to better priced alternatives

-- Revenue Lost by CLTV Segment
select
case
when cltv < 3000 then 'Low CLTV'
when cltv between 3000 and 6000 then 'Medium CLTV'
else 'High CLTV'
end as cltv_segment,
count(*) as churned_customers,
round(sum(total_revenue), 2) as revenue_lost
from telco
where churn_label = 'Yes'
group by cltv_segment
order by revenue_lost desc;
# Revenue lost by churned customers only for Medium CLTV is very high compared to other segments

-- Top Churn Categories by Revenue Loss
select
Churn_Category,
round(sum(total_revenue), 2)  as revenue_lost,
round(
     sum(total_revenue) * 100 
     / sum(sum(total_revenue)) over (), 2
     ) as revenue_loss_pct
from telco
where churn_label = 'Yes'
group by churn_category
order by revenue_lost desc;
# Nearly 46% of churned revenue is lost to competitors
# This indicates churn is driven by competitive switching rather than pricing or billing issues

-- Total revenue and risk % of revenue
select
round(sum(total_revenue), 2) as total_revenue,
round(sum(case when churn_label = 'Yes' then total_revenue end), 2) as revenue_churn_customers,
round(sum(case when churn_label = 'Yes' then total_revenue end) * 100.0 / sum(total_revenue), 2) as revenue_pct_at_risk
from telco;
# 17.24% revenue is at risk

/* ============================================================
   FINAL FINDINGS, INSIGHTS & RECOMMENDED ACTIONS
   Telco Customer Churn Analysis
   ============================================================

1. Overall Churn & Revenue Risk
   - 17.24% of total revenue is at risk due to churn.
   - Revenue loss is disproportionately high compared to churn volume.
   - Customers are churning before full CLTV is realized.

   Action:
   - Prioritize early retention and revenue protection over churn volume reduction.

------------------------------------------------------------

2. Geographic Concentration – San Diego
   - San Diego is a statistical churn outlier even after minimum sample filtering.
   - ~65% churn driven by operational and service issues, not market-wide behavior.

   Action:
   - Apply city-specific service and retention interventions.

------------------------------------------------------------

3. Contract Structure Impact
   - Month-to-Month contracts drive the majority of churn.
   - Long-term contracts exhibit significantly lower churn.
   - Churned customers show consistently low satisfaction across all contracts.

   Action:
   - Introduce short-term incentives and proactive engagement for Month-to-Month users.

------------------------------------------------------------

4. Service Experience as Primary Driver
   - Fiber Optic customers show extreme churn (~78%) in San Diego.
   - Lack of Premium Tech Support dramatically increases Fiber churn.
   - Price bands have weak explanatory power.

   Action:
   - Bundle Premium Tech Support with Fiber Optic onboarding.
   - Treat Fiber churn as a service quality issue, not a pricing issue.

------------------------------------------------------------

5. Early-Tenure Failure (0–6 Months)
   - Majority of churn occurs within the first 6 months.
   - Early Fiber customers without Tech Support are the highest-risk group.
   - San Diego shows uniquely severe early-tenure churn.

   Action:
   - Implement a 90-day onboarding protection and support program.

------------------------------------------------------------

6. Satisfaction as a Leading Indicator
   - 100% churn for customers with satisfaction <= 2.
   - Zero churn for satisfaction >= 4.
   - Satisfaction below neutral (3) signals inevitable churn.

   Action:
   - Trigger immediate intervention when satisfaction <= 3.

------------------------------------------------------------

7. Joined Customers – Future Churn Risk
   - Newly joined customers already exhibit churn-prone characteristics.
   - High-risk profile includes:
     1. Month-to-Month contract
     2. Fiber Optic service
     3. No Premium Tech Support
     4. Low satisfaction

   Action:
   - Flag and intervene within the first billing cycle.

------------------------------------------------------------

8. Referrals & Engagement
   - Referred customers churn nearly 50% less than non-referred customers.
   - Referred customers generate ~54% more revenue.

   Action:
   - Expand referral programs as a retention and revenue strategy.

------------------------------------------------------------

9. CLTV-Based Prioritization
   - Medium-CLTV customers contribute the highest revenue loss.
   - High-CLTV customers churn the least and are the most stable.
   - Low-CLTV customers churn frequently but have limited revenue impact.

   Action:
   - Focus retention spend on Medium-CLTV customers for maximum ROI.

------------------------------------------------------------

10. Churn Reason Validation
    - ~46% of churned revenue is lost to competitors.
    - Pricing is not the primary churn driver.
    - Customers switch due to better perceived value elsewhere.

    Action:
    - Compete on service quality and experience rather than blanket discounts.

------------------------------------------------------------

FINAL CONCLUSION
- Churn is driven by early-tenure service failures, poor Fiber onboarding,
  and delayed response to declining satisfaction.
- Targeted operational fixes can protect a disproportionate share of revenue
  with focused interventions.

============================================================ */

