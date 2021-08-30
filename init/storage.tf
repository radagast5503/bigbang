resource "google_pubsub_topic" "image_dropbox" {
    name = "image-dropbox"
    labels = {
        team = "radagast5503"
    }
    project = google_project.main.project_id
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "gcs_binding" {
  topic   = google_pubsub_topic.image_dropbox.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_pubsub_topic_iam_binding" "project_binding" {
  topic   = google_pubsub_topic.image_dropbox.id
  role    = "roles/pubsub.publisher"
  members = [local.service_account_name]
}

//================================================

resource "google_storage_bucket" "terraform" {
    name = local.terraform_bucket_name
    project = google_project.main.project_id
    force_destroy = true
    storage_class = "STANDARD"
    labels = {
        team = "muebles-ra"
    }
}

resource "google_storage_bucket" "furniture" {
  name          = local.furniture_bucket_name
  project       = google_project.main.project_id
  force_destroy = true
  storage_class = "STANDARD"
  labels = {
    team = "radagast5503"
  }

  lifecycle_rule {
    condition {
      age = 4 # vida de muebles
    }

    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "service_account_storage_project_admin_on_furniture" {
  bucket = google_storage_bucket.furniture.name
  role   = "roles/storage.admin"
  member = local.service_account_name
}

resource "google_storage_bucket_iam_member" "service_account_storage_render_admin_on_furniture" {
  bucket = google_storage_bucket.furniture.name
  role   = "roles/storage.admin"
  member = var.render_service_account
}

resource "google_storage_notification" "notification" {
    bucket = google_storage_bucket.furniture.name
    payload_format = "JSON_API_V1"
    topic = google_pubsub_topic.image_dropbox.name
    event_types = ["OBJECT_FINALIZE"]
    custom_attributes = {
      "project" = google_project.main.project_id
    }
}
//=========================================================