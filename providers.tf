terraform {
  required_providers {
    helm = {
      version = "2.3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.83"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "helm" {
  kubernetes {
    host = "https://${data.google_secret_manager_secret_version.cluster_endpoint_ip.secret_data}"

    cluster_ca_certificate = base64decode(data.google_secret_manager_secret_version.cluster_ca_certificate.secret_data)
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubernetes" {
  host = "https://${data.google_secret_manager_secret_version.cluster_endpoint_ip.secret_data}"

  cluster_ca_certificate = base64decode(data.google_secret_manager_secret_version.cluster_ca_certificate.secret_data)
  token                  = data.google_client_config.default.access_token
}