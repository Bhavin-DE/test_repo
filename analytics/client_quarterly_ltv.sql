--Client Lifetime Value (LTV) What are the lifetime value (LTV), i.e. the accumulated fees, at 1, 3 and 6 months for each client, measured from the client’s first fee date?

-- month 1 LTV
WITH
  one_month_ltv AS (
    SELECT client_id, client_fee_amount_cumulative AS ltv_1
    FROM `heroic-footing-446621-d9.mart.fees_mart`
    WHERE month_since_first_payment = 0
  ),

  -- month 3 LTV
  three_months_ltv AS (
    SELECT client_id, client_fee_amount_cumulative AS ltv_3
    FROM `heroic-footing-446621-d9.mart.fees_mart`
    WHERE month_since_first_payment <= 2
    QUALIFY
      row_number()
        OVER (PARTITION BY client_id ORDER BY month_since_first_payment DESC)
      = 1
  ),

  -- month 6 LTV
  six_months_ltv AS (
    SELECT client_id, client_fee_amount_cumulative AS ltv_6
    FROM `heroic-footing-446621-d9.mart.fees_mart`
    WHERE month_since_first_payment <= 5
    QUALIFY
      row_number()
        OVER (PARTITION BY client_id ORDER BY month_since_first_payment DESC)
      = 1
  )

-- Bring monthly LTVs together
SELECT
  one.client_id,
  one.ltv_1,
  three.ltv_3,
  six.ltv_6
FROM one_month_ltv AS one
LEFT JOIN three_months_ltv AS three
  ON one.client_id = three.client_id
LEFT JOIN six_months_ltv AS six
  ON one.client_id = six.client_id
