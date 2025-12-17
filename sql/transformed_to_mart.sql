assert (
  (
    select date(max(run_timestamp))
    from `heroic-footing-446621-d9.transformed.fees_transformed`
  ) = current_date()
) as "Transformed fees table is stale";

truncate table `heroic-footing-446621-d9.mart.fees_mart`;

insert into `heroic-footing-446621-d9.mart.fees_mart`
  with first_payment_date AS (
    SELECT
      client_id,
      client_nino,
      adviser_id,
      fee_date,
      fee_amount,
      min(fee_date)
        OVER (PARTITION BY client_id ORDER BY fee_date) AS first_fee_date
    FROM `heroic-footing-446621-d9.transformed.fees_transformed`
  ),

  ltv_month AS (
    SELECT
      client_id,
      client_nino,
      adviser_id,
      fee_date,
      fee_amount,
      first_fee_date,
      date_diff(fee_date, first_fee_date, month) AS month_since_first_payment
    FROM first_payment_date
  ),
  cumulrative_fee AS (
    SELECT
      client_id,
      client_nino,
      adviser_id,
      fee_date,
      fee_amount,
      first_fee_date,
      month_since_first_payment,
      sum(fee_amount)
        OVER (PARTITION BY client_id ORDER BY month_since_first_payment)
        AS client_fee_amount_cumulative,
      sum(fee_amount)
        OVER (PARTITION BY adviser_id, client_id ORDER BY fee_date)
        AS adviser_fee_amount_cumulative
    FROM ltv_month
  )

SELECT *, current_timestamp() AS run_timestamp
FROM cumulrative_fee;

  assert (
  (
    select count(1)
    from `heroic-footing-446621-d9.transformed.fees_transformed`
  ) > 0
) as "Mart fees table has 0 records";
