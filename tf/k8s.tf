# Deploy common services
# Create ingress dns record
resource "kubernetes_manifest" "gp3" {
  manifest = yamldecode(file("${path.module}/templates/gp3.yaml"))
}


data "http" "cert-manager" {
  method = "GET"
  url = "https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml"
}

resource "helm_release" "cert-manager" {
  name  = "cert-manager"
  version = "v1.13.1"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  create_namespace = true
  namespace = "cert-manager"
  skip_crds = false
  values = [
    file("${path.module}/templates/cert-manager-values.yaml")
  ]
}

resource "kubernetes_secret" "route53-credentials-secret" {
  metadata {
    name = "route53-credentials-secret"
    namespace = "cert-manager"
  }

  data = {
    access-key-id = aws_iam_access_key.sa-access-key.id
    secret-access-key = aws_iam_access_key.sa-access-key.secret
  }

  type = "Opaque"
  depends_on = [
    helm_release.cert-manager
  ]
}
resource "kubernetes_manifest" "letsencrypt-prod" {
  manifest = yamldecode(
    templatefile( "${path.module}/templates/letsencrypt-prod.yaml",{
      email = local.owner-email
      project-domain = local.project-domain
      aws-hosted-zone-id = data.aws_route53_zone.project-hosted-zone.id
      aws-region = data.aws_region.current.name
    })
  )
  depends_on = [
    kubernetes_secret.route53-credentials-secret
  ]
}



# resource "helm_release" "nginx-ingress" {
#   name  = "cert-manager"
#   version = "v1.13.1"

#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   create_namespace = true
#   namespace = "cert-manager"
#   skip_crds = false
#   values = [
#     file("${path.module}/templates/cert-manager-values.yaml")
#   ]
# }



