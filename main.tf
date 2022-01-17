resource "helm_release" "velero" {
  name             = var.name
  repository       = var.repository
  chart            = var.name
  namespace        = var.name
  create_namespace = var.create_namespace

  values = [
    "${file("velero-values.yaml")}"
  ]

}