terraform {
#   backend "gcs" {
#     bucket = "radagast5503-terraform"
#     prefix = "env/dev"
#   }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.75.0"
    }
  }
}

provider "google" {
  region = "us-central1"
}

provider "google-beta" {
  region = "us-central1"
}