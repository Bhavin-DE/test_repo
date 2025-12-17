resource "google_bigquery_table" "raw_fees" {
  dataset_id = google_bigquery_dataset.layers["raw"].dataset_id
  table_id   = "fees"
  deletion_protection = false

  time_partitioning {
    type = "DAY"   # 👈 ingestion-time partitioning
  }

  schema = jsonencode([
    { name = "client_id",     type = "STRING" },
    { name = "client_nino",   type = "STRING"},
    { name = "adviser_id",    type = "INT64" },
    { name = "fee_date",      type = "DATE"},
    { name = "fee_amount",    type = "NUMERIC"}
  ])
}

resource "google_bigquery_table" "staging_fees" {
  dataset_id = google_bigquery_dataset.layers["staging"].dataset_id
  table_id   = "fees_staging"
  deletion_protection = false

  schema = jsonencode([
    { name = "client_id",     type = "STRING" },
    { name = "client_nino",   type = "STRING" },
    { name = "adviser_id",    type = "INT64" },
    { name = "fee_date",      type = "DATE" },
    { name = "raw_processed_timestamp", type = "TIMESTAMP" },
    { name = "fee_amount",    type = "NUMERIC", mode = "NULLABLE" },
    { name = "client_pk",    type = "STRING" },
    { name = "run_timestamp", type = "TIMESTAMP" }
  ])
}

resource "google_bigquery_table" "transformed_fees" {
  dataset_id = google_bigquery_dataset.layers["transformed"].dataset_id
  table_id   = "fees_transformed"
  deletion_protection = false

  schema = jsonencode([
    { name = "client_id",     type = "STRING" },
    { name = "client_nino",   type = "STRING" },
    { name = "adviser_id",    type = "INT64" },
    { name = "fee_date",      type = "DATE" },
    { name = "fee_amount",    type = "NUMERIC" },
    { name = "client_pk",    type = "STRING" },
    { name = "run_timestamp", type = "TIMESTAMP" }
  ])
}

resource "google_bigquery_table" "mart_fees" {
  dataset_id = google_bigquery_dataset.layers["mart"].dataset_id
  table_id   = "fees_mart"
  deletion_protection = false
  time_partitioning {
    type = "DAY"   # 👈 ingestion-time partitioning
    field = "fee_date"
  }

  schema = jsonencode([
    { name = "client_id",     type = "STRING" },
    { name = "client_nino",   type = "STRING" },
    { name = "adviser_id",    type = "INT64" },
    { name = "fee_date",      type = "DATE" },
    { name = "fee_amount",    type = "NUMERIC" },
    { name = "first_fee_date",      type = "DATE" },
    { name = "month_since_first_payment", type = "INT64"},
    { name = "client_fee_amount_cumulative",    type = "NUMERIC", mode = "NULLABLE" },
    { name = "adviser_fee_amount_cumulative",    type = "NUMERIC", mode = "NULLABLE" },
    { name = "run_timestamp", type = "TIMESTAMP" }
  ])
}