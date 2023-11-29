variable "project_id" {
    description = "The ID of the project in which resources will be managed."
    type        = string
}
variable "region" {
    description = "The region in which resources will be managed."
    type        = string
    default     = "us-central1"
}
variable "bucket_name" {
    description = "The name of the GCS bucket."
    type        = string
}
variable "topic_name" {
    description = "The name of the Pub/Sub topic."
    type        = string
}
variable "dataset_id" {
    description = "The ID of the BigQuery dataset."
    type        = string
}
variable "table_id" {
    description = "The ID of the BigQuery table."
    type        = string
}

variable "service_account_email" {
    description = "The email address of the service account."
    type        = string
}

variable "service_account_display_name" {
    description = "The display name of the service account."
    type        = string
}


