
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
    templatefile("${path.module}/templates/yba-values.yaml",{
      project-domain = local.project-domain
    })
  ]
  depends_on = [
    kubernetes_manifest.yugabyte-k8s-pull-secret
  ]
}

## YBA Ingress
resource "kubernetes_manifest" "yba-ingress" {

  manifest = merge(
    yamldecode(
      templatefile(
        "${path.module}/templates/yba-ingress.template.yaml", {
          project-domain = local.project-domain
        }
      )
    ), {
    metadata = {
      namespace = "yba"
      name = "yba-ingress"
    }
  })
  depends_on = [
    kubernetes_namespace.yba
  ]
}

provider "yba" {
  alias = "unauthenticated"
  host      = "yba.${local.project-domain}"

}

resource "yba_customer_resource" "superadmin" {
  provider   = yba.unauthenticated
  code       = "admin"
  email      = local.yba-username
  name       = "Super Admin"
}
provider "yba" {
  host      = "yba.${local.project-domain}"
  api_token = yba_customer_resource.superadmin.api_token
}
