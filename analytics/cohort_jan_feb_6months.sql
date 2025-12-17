-- Cohort LTV What is the 6-month LTV for the January and February cohorts of the current year? A cohort is defined by the month in which a client first paid a fee.

WITH
  cohort_clients AS (
    SELECT
      client_id,
      EXTRACT(year FROM min(fee_date)) AS cohort_year,
      EXTRACT(month FROM min(fee_date)) AS cohort_month
    FROM `heroic-footing-446621-d9.mart.fees_mart`
    GROUP BY 1
    HAVING EXTRACT(month FROM min(fee_date)) IN (1, 2)
  ),
  cohort_ltv AS (
    SELECT
      cc.cohort_year, cc.cohort_month, fm.client_fee_amount_cumulative AS ltv_6
    FROM `heroic-footing-446621-d9.mart.fees_mart` AS fm
    INNER JOIN cohort_clients AS cc
      ON fm.client_id = cc.client_id AND month_since_first_payment <= 5
    QUALIFY
      row_number()
        OVER (PARTITION BY fm.client_id ORDER BY month_since_first_payment DESC)
      = 1
  )
SELECT
  cohort_year,
  cohort_month,
  sum(ltv_6) AS total_cohort_6mths_ltv,
  round(avg(ltv_6), 2) AS avg_cohort_6mths_ltv
FROM cohort_ltv
GROUP BY 1, 2