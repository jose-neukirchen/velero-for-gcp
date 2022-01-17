locals {
  clustername = replace(var.cluster_name, "-", "")
}

resource "google_storage_bucket" "this" {
  force_destroy               = var.force_destroy
  location                    = var.region
  name                        = "velero-${var.cluster_name}"
  uniform_bucket_level_access = var.uniform_bucket_level_access
  dynamic "versioning" {
    for_each = var.versioning
    content {
      enabled = lookup(
        var.versioning,
        true,
        false,
      )
    }
  }
  dynamic "retention_policy" {
    for_each = var.retention_policy
    content {
      is_locked        = lookup(retention_policy.value, "is_locked", null)
      retention_period = lookup(retention_policy.value, "retention_period", null)
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                        = lookup(lifecycle_rule.value.condition, "age", null)
        created_before             = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state                 = lookup(lifecycle_rule.value.condition, "with_state", lookup(lifecycle_rule.value.condition, "is_live", false) ? "LIVE" : null)
        matches_storage_class      = contains(keys(lifecycle_rule.value.condition), "matches_storage_class") ? split(",", lifecycle_rule.value.condition["matches_storage_class"]) : null
        num_newer_versions         = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        custom_time_before         = lookup(lifecycle_rule.value.condition, "custom_time_before", null)
        days_since_custom_time     = lookup(lifecycle_rule.value.condition, "days_since_custom_time", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value.condition, "days_since_noncurrent_time", null)
        noncurrent_time_before     = lookup(lifecycle_rule.value.condition, "noncurrent_time_before", null)
      }
    }
  }

  dynamic "logging" {
    for_each = var.logging
    content {
      log_bucket        = lookup(logging.value, "log_bucket", null)
      log_object_prefix = lookup(logging.value, "log_object_prefix", null)
    }
  }
}

resource "google_service_account" "this" {
  account_id   = "velero-${var.cluster_name}"
  display_name = "velero-${var.cluster_name}"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.this.name
  private_key_type = "JSON"
}

resource "google_project_iam_custom_role" "this" {
  permissions = [
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.zones.get",
    "storage.objects.list"
  ]
  role_id = "velero${local.clustername}"
  title   = "velero-${var.cluster_name}"
}

resource "google_project_iam_binding" "custom_role" {
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.this.role_id}"
  project = var.project_id
  members = [
    "serviceAccount:${google_service_account.this.email}"
  ]
}

resource "google_project_iam_binding" "object_admin" {
  role  = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.this.email}"
  ]
  project = var.project_id
  condition {
    expression = "resource.name.startsWith(\"projects/_/buckets/velero-${var.cluster_name}/objects/\")"
    title      = "bucket"
  }
}

resource "google_service_account_iam_binding" "this" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${google_service_account.this.email}"
  ]
}