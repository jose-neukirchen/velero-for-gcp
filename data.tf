data "google_secret_manager_secret_version" "cluster_ca_certificate" {
  secret = "gke_cluster_ca_certificate"
}

data "google_secret_manager_secret_version" "cluster_endpoint_ip" {
  secret = "gke_cluster_endpoint_ip"
}

data "google_client_config" "default" {}

data "google_service_account_key" "mykey"{
  name = google_service_account_key.mykey.name
}