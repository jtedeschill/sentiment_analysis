terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
  backend "gcs" {
    bucket = "tenex-terraform-state-bucket"
    prefix = "terraform/state"
  }
}
locals {
  project = var.project_id
}

data "google_compute_default_service_account" "default" {
  project = local.project
}

output "default_account" {
  value = data.google_compute_default_service_account.default.email
}


resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_service_account" "default" {
  account_id   = "classify-emails"
  display_name = "Test Service Account"

}


data "google_project" "project" {
}

resource "google_project_iam_member" "viewer" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "editor" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_bigquery_table" "table" {
  deletion_protection = false
  table_id            = var.table_id
  dataset_id          = var.dataset_id

  schema = <<EOF
[
  {
    "name": "task_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID of the task."
  },
  {
    "name": "account_id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID of the account."
  },
  {
    "name": "description",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The description of the task."
  },
  {
    "name": "subject",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The description of the task."
  },
  {
    "name": "openai_response",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_total_tokens",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_completion_tokens",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_prompt_tokens",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_model",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_system_fingerprint",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_created",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_object",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "openai_id",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}


resource "google_pubsub_schema" "push_schema" {
  project = var.project_id
  name    = "push-schema"
  type    = "AVRO"
  # get from file 
  definition = <<EOF
 {
    "type": "record",
    "name": "Task",
    "fields": [
      {"name": "task_id", "type": "string"},
      {"name": "account_id", "type": "string"},
      {"name": "description", "type": "string"},
      {"name": "subject", "type": "string"},
      {"name": "openai_response", "type": "string"},
      {"name": "openai_total_tokens", "type": "int"},
      {"name": "openai_completion_tokens", "type": "int"},
      {"name": "openai_prompt_tokens", "type": "int"},
      {"name": "openai_model", "type": "string"},
      {"name": "openai_system_fingerprint", "type": "string"},
      {"name": "openai_created", "type": "string"},
      {"name": "openai_object", "type": "string"},
      {"name": "openai_id", "type": "string"}
    ]
}
EOF
}


resource "google_pubsub_topic" "default" {
  name = "classify-emails-topic"
  depends_on = [ google_pubsub_schema.push_schema ]
  schema_settings {
    schema = "projects/${var.project_id}/schemas/${google_pubsub_schema.push_schema.name}"
    encoding = "JSON"
  }
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.bucket_prefix.hex}-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}



resource "google_pubsub_subscription" "default" {
  name  = "push-to-bigquery"
  topic = google_pubsub_topic.default.name
  

  bigquery_config {
    table = "${local.project}.${google_bigquery_table.table.dataset_id}.${google_bigquery_table.table.table_id}"
    use_topic_schema = true  
  }


  

  depends_on = [google_project_iam_member.viewer, google_project_iam_member.editor]
}


# {
#   "type": "record",
#   "name": "Task",
#   "fields": [
#     {"name": "task_id", "type": "string"},
#     {"name": "account_id", "type": "string"},
#     {"name": "who_id", "type": "string"},
#     {"name": "what_type", "type": "string"},
#     {"name": "what_id", "type": "string"},
#     {"name": "activity_date", "type": "string"},
#     {"name": "completion_date", "type": "string"},
#     {"name": "subject", "type": "string"},
#     {"name": "owner_name", "type": "string"},
#     {"name": "owner_role", "type": "string"},
#     {"name": "task_subtype", "type": "string"},
#     {"name": "call_duration_s", "type": "int"},
#     {"name": "call_disposition", "type": "string"},
#     {"name": "created_date", "type": "string"},
#     {"name": "description", "type": "string"},
#     {"name" : "openai_response", "type" : "string"},
#     {"name" : "openai_total_tokens", "type" : "int"},
#     {"name" : "openai_completion_tokens", "type" : "int"},
#     {"name" : "openai_prompt_tokens", "type" : "int"},
#     {"name" : "openai_model", "type" : "string"},
#     {"name" : "openai_system_fingerprint", "type" : "string"},
#     {"name" : "openai_created", "type" : "string"},
#     {"name" : "openai_object", "type" : "string"},
#     {"name" : "openai_id", "type" : "string"}
#   ]
# }

# data "archive_file" "default" {
#   type        = "zip"
#   output_path = "/tmp/source.zip"
#   source_dir  = "cloud_function/"
# }

# resource "google_storage_bucket_object" "default" {
#   name   = "source.zip"
#   bucket = google_storage_bucket.default.name
#   source = data.archive_file.default.output_path # Path to the zipped function source code
#   depends_on = [ 
#     data.archive_file.default,
#     google_storage_bucket.default
#     ]
# }

# resource "google_cloudfunctions2_function" "default" {
#   name        = "classify-email-gcf"
#   location    = "us-central1"
#   description = "Classify emails using genAI from OpenAI"
#   depends_on = [
#     google_service_account.default,

#     ]


#   build_config {
#     runtime     = "python310"
#     entry_point = "main" # Set the entry point
#     environment_variables = {
#       BUILD_CONFIG_TEST = "build_test"
#     }
#     source {
#       storage_source {
#         bucket = google_storage_bucket.default.name
#         object = google_storage_bucket_object.default.name
#       }
#     }
#   }

#   service_config {
#     max_instance_count = 3
#     min_instance_count = 1
#     available_memory   = "512M"
#     timeout_seconds    = 60
#     environment_variables = {
#       SERVICE_CONFIG_TEST = "config_test"
#     }
#     # ingress_settings               = "ALLOW_INTERNAL_ONLY"
#     all_traffic_on_latest_revision = true
#     service_account_email = google_service_account.default.email
#   }

#   event_trigger {
#     trigger_region = "us-central1"
#     event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic   = google_pubsub_topic.default.id
#     retry_policy   = "RETRY_POLICY_RETRY"
#   }


# }

# resource "google_cloud_run_service_iam_member" "member" {
#   location = google_cloudfunctions2_function.default.location
#   service  = google_cloudfunctions2_function.default.name
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }

# output "function_uri" {
#   value = google_cloudfunctions2_function.default.service_config[0].uri
# }
