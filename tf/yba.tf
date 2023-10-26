
## YBA Namesapce
resource "kubernetes_namespace" "yba" {
  metadata {
    name = "yba"
  }
}

## YBA Pull Secret
resource "kubernetes_manifest" "yugabyte-k8s-pull-secret" {

  manifest = merge(
    yamldecode(file(local.yugabyte_k8s_pull_secret)), {
    metadata = {
      namespace = "yba"
      name = "yugabyte-k8s-pull-secret"
    }
  })
  depends_on = [
    kubernetes_namespace.yba
  ]
}

## YBA Install
resource "helm_release" "yba" {
  name    = "yba"
  version = local.yba-version

  repository       = "https://charts.yugabyte.com"
  chart            = "yugaware"
  create_namespace = true
  namespace        = "yba"
  values = [
    file("${path.module}/templates/yba-values.yaml")
  ]
  depends_on = [
    kubernetes_manifest.yugabyte-k8s-pull-secret
  ]
}

## YBA Ingress


## YBA Register User

## YBA Authenticated Provider

