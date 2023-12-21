# Use monthly calendar table
WITH cal AS (
SELECT *
FROM `eb-project-392023.sandbox.calendar`),

# Initial subcriptions cte
subs AS (
SELECT 
  *,
  CASE WHEN joinmonth = c.month THEN 1 ELSE 0 END new_subs,
  DATE_TRUNC(date(Join_Date), month) AS joinmonth,
FROM `eb-project-392023.sandbox.netflix` n
LEFT JOIN `eb-project-392023.sandbox.calendar` c ON c.month BETWEEN joinmonth AND cancelmonth),

# Average revenue per subscription by month cte
arps AS (
SELECT 
  month,
  SUM(Monthly_Revenue) AS monthlyrevenue,
  SUM(new_subs) AS new_subs,
  COUNT(DISTINCT User_ID) AS total_subscriptions,
  ROUND(SUM(Monthly_Revenue) / COUNT(DISTINCT User_ID),2) AS arps
FROM subs
GROUP BY month
ORDER BY month),

# Create a churn calculation and cte
churn AS (
SELECT 
  cancelmonth AS churnmonth,
  COALESCE(COUNT(DISTINCT User_ID),0) AS churns,
FROM `eb-project-392023.sandbox.netflix` n
LEFT JOIN `eb-project-392023.sandbox.calendar` c ON c.month = cancelmonth
GROUP BY cancelmonth),

# join the arps and churn data into single query and calculate a churn rate
churn2 AS (
SELECT
  a.month AS month,
  a.total_subscriptions,
  a.new_subs,
  a.monthlyrevenue,
  a.arps,
  LAG(a.total_subscriptions) OVER (ORDER BY a.month) AS subs_last_month,
  churns,
  ROUND(SAFE_DIVIDE(churns,(a.total_subscriptions - churns)),2) AS churnrate
FROM arps a
LEFT JOIN churn c ON c.churnmonth = a.month
ORDER BY month)

SELECT
month,
monthlyrevenue,
total_subscriptions,
new_subs,
subs_last_month,
churns,
churnrate,
arps / (churns / subs_last_month) AS ltv
FROM churn2

