variable "gcp_credentials_file" {
    description = "The path to the GCP credentials file."
    type        = string
    default     = "~/.gcp/credentials.json"
  
}

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
    default = "classify-emails"
}
variable "topic_name" {
    description = "The name of the Pub/Sub topic."
    type        = string
    default = "classify-emails-topic"
}
variable "dataset_id" {
    description = "The ID of the BigQuery dataset."
    type        = string
    default = "Hired"
}
variable "table_id" {
    description = "The ID of the BigQuery table."
    type        = string
    default = "classified_emails"
}

variable "service_account_email" {
    description = "The email address of the service account."
    type        = string
}
