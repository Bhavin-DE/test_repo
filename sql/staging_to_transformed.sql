assert (
  (
    select date(max(run_timestamp))
    from `heroic-footing-446621-d9.staging.fees_staging`
  ) = current_date()
) as "Staging fees table is stale";

merge `heroic-footing-446621-d9.transformed.fees_transformed` as t
using `heroic-footing-446621-d9.staging.fees_staging` as s
on t.client_pk = s.client_pk
when matched then
  update set
    adviser_id = s.adviser_id,
    fee_amount = s.fee_amount,
    run_timestamp = s.run_timestamp
when not matched then
    insert(client_id, client_nino, adviser_id, fee_date, fee_amount, client_pk, run_timestamp)
    values(s.client_id, s.client_nino, s.adviser_id, s.fee_date, s.fee_amount, s.client_pk, s.run_timestamp)
