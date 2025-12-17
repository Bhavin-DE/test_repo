variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region for provider"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "BigQuery dataset location (e.g. US or EU)"
  type        = string
  default     = "US"
}

variable "delete_contents_on_destroy" {
  description = "If true, dataset contents are deleted when destroying the dataset (useful for dev)"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Common labels applied to all datasets"
  type        = map(string)
  default     = {
    "managed_by" = "terraform"
  }
}

variable "bucket_name" {
  description = "Globally unique bucket name"
  type        = string
}

variable "env" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_number" {
  type = string
}