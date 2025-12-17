-- Adviser Performance Which adviser has the highest total client LTV over the first 6 months of each client’s lifetime?

WITH
  six_months_ltv AS (
    SELECT adviser_id, client_id, adviser_fee_amount_cumulative AS ltv_6
    FROM `heroic-footing-446621-d9.mart.fees_mart`
    WHERE month_since_first_payment <= 5
    QUALIFY
      row_number()
        OVER (
          PARTITION BY adviser_id, client_id
          ORDER BY month_since_first_payment DESC
        )
      = 1
  )
SELECT
  adviser_id, sum(ltv_6) AS total_ltv6_all_clients
FROM six_months_ltv
GROUP BY 1
ORDER BY total_ltv6_all_clients DESC
