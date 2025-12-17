-- Checking if raw has any partition from today
-- Reading latest partiton from raw source, removing duplicates (if whole record is duplicate) and adding metadata fields
-- Load type - truncate+insert
-- Also creating pk

assert (
  (
    select max(_partitiondate)
    from `heroic-footing-446621-d9.raw.fees`
  ) = current_date()
) as "RAW fees table is stale";

truncate table `heroic-footing-446621-d9.staging.fees_staging`;

insert into `heroic-footing-446621-d9.staging.fees_staging`
with src as (
  select
    distinct client_id,
    client_nino,
    adviser_id,
    fee_date,
    fee_amount,
    _partitiontime as raw_processed_timestamp
from `heroic-footing-446621-d9.raw.fees`
where
    _partitiontime = (select max(_partitiontime ) from `heroic-footing-446621-d9.raw.fees`)
    and client_id is not null and fee_date is not null
),

src_agg AS (
    select
      client_id,
      client_nino,
      adviser_id,
      fee_date,
      raw_processed_timestamp,
      sum(fee_amount) AS fee_amount
    from src
    group by client_id, client_nino, adviser_id, fee_date,raw_processed_timestamp
  ),
  
  src_pk AS (
    select
    *,
    concat(client_id||cast(fee_date as string)) as client_pk,
    current_timestamp() as run_timestamp,
    from src_agg
  )

  select * from src_pk
