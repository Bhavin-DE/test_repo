locals {
  datasets = toset(["raw", "staging", "transformed", "mart"])
}

resource "google_bigquery_dataset" "layers" {
  for_each = local.datasets

  dataset_id                 = each.value
  location                   = var.location
  delete_contents_on_destroy = var.delete_contents_on_destroy

  labels = merge(
    var.labels,
    {
      "layer" = each.value
    }
  )

}
