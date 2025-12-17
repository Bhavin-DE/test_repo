resource "google_storage_bucket" "csv_bucket" {
  name          = var.bucket_name
  location      = var.location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  labels = {
    purpose = "csv-ingestion"
    layer   = "raw"
    env     = var.env
  }
}

#granting storage admin access to a serviceAccount
resource "google_storage_bucket_iam_member" "ingestor" {
  bucket = google_storage_bucket.csv_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:bp-gcs@${var.project_id}.iam.gserviceaccount.com"
}

#granting read access to DTS  serviceAccount
resource "google_storage_bucket_iam_member" "dts_bucket_access" {
  bucket = "source_extract"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${var.project_number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
}
