resource "random_id" "random_project_id_suffix" {
  byte_length = 2
}

locals {
  base_project_id = var.project_id == "" ? var.name : var.project_id
  temp_project_id = var.random_project_id ? format(
    "%s-%s",
    local.base_project_id,
    random_id.random_project_id_suffix.hex,
  ) : local.base_project_id
  activate_apis = ["compute.googleapis.com", "pubsub.googleapis.com", "storage-component.googleapis.com"
                  ,"secretmanager.googleapis.com"]
  service_account_name = format(
    "serviceAccount:%s",
    google_service_account.service_account.email,
  )

  terraform_bucket_name = "${local.temp_project_id}-terraform"
  furniture_bucket_name = "${local.temp_project_id}-furniture-repository"
}

resource "google_project" "main" {
  name                = "muebles-ra"
  project_id          = local.temp_project_id
  auto_create_network = false
  billing_account = var.billing_account_id
}

module "project_services" {
  source = "../project_services"

  project_id                  = google_project.main.project_id
  activate_apis               = local.activate_apis
  disable_services_on_destroy = true
  disable_dependent_services  = true
}

module "vpc" {
  source = "terraform-google-modules/network/google"

  project_id   = google_project.main.project_id
  network_name = "main-vpc"
  routing_mode = "GLOBAL"
  mtu          = 1500

  subnets = [
    {
      subnet_name   = "principal"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "us-central1"
    },
    {
      subnet_name   = "secondary"
      subnet_ip     = "10.10.20.0/24"
      subnet_region = "us-central1"
      description   = "This subnet has a description"
    }
  ]

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]

  depends_on = [module.project_services]
}

resource "google_service_account" "service_account" {
  account_id   = "muebles-ra-sa"
  display_name = "muebles-ra Project service account"
  project      = google_project.main.project_id
}


resource "google_service_account_key" "service_account_project_key" {
  service_account_id = google_service_account.service_account.name
}

resource "google_secret_manager_secret" "service_account_key_secret" {
  secret_id = "muebles-ra-sa-private-key"

  labels = {
    team = "muebles-ra"
  }
  project      = google_project.main.project_id
  replication {
    automatic = true
  }
  depends_on = [module.project_services]
}

resource "google_secret_manager_secret_version" "service_account_key_secret_manager_version" {
  secret = google_secret_manager_secret.service_account_key_secret.id
  secret_data = google_service_account_key.service_account_project_key.private_key
}

resource "google_project_iam_member" "service_account_membership_project" {
  project = google_project.main.project_id
  role    = "roles/owner" //change to multiple, or create a new role
  member  = local.service_account_name
}

resource "google_project_iam_member" "service_account_membership_render" {
  project = google_project.main.project_id
  role    = "roles/owner" //change to multiple, or create a new role
  member  = var.render_service_account
}

resource "google_compute_subnetwork_iam_member" "service_account_role_to_vpc_principal" {
  subnetwork = "principal"
  role       = "roles/compute.networkUser"
  region     = "us-central1"
  project    = google_project.main.project_id
  member     = local.service_account_name
  depends_on = [module.vpc]
}

resource "google_compute_subnetwork_iam_member" "service_account_role_to_vpc_secondary" {
  subnetwork = "secondary"
  role       = "roles/compute.networkUser"
  region     = "us-central1"
  project    = google_project.main.project_id
  member     = local.service_account_name
  depends_on = [module.vpc]
}

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