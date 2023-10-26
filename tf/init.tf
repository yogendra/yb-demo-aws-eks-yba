terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.22.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
locals {

  project-name              = "yrpoc"
  project-cidr              = "10.97.0.0/16"
  cluster_service_ipv4_cidr = "10.100.0.0/16"
  project-root-domain       = "poc.aws.apj.yugabyte.com"
  eks-version               = "1.27"
  project-domain            = "${local.project-name}.${local.project-root-domain}"
  yba-domain                = "yba.${local.project-domain}"
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  eks-worker-type          = "m6a.2xlarge"
  yugabyte_k8s_pull_secret = "${path.root}/private/yugabyte-k8s-pull-secret.yaml"
  owner-email              = "yrampuria@yugabyte.com"
  yba-version              = "v2.18.2"

  # azs           = ["ap-southeast-1a","ap-southeast-1b","ap-southeast-1c"]
  private-subnets = [for k, v in local.azs : cidrsubnet(local.project-cidr, 4, k)]
  public-subbets  = [for k, v in local.azs : cidrsubnet(local.project-cidr, 8, k + 48)]
  intra-subnets   = [for k, v in local.azs : cidrsubnet(local.project-cidr, 8, k + 52)]

  # public-cidrs  = [for index, az in(local.azs) : cidrsubnet(local.project-cidr, 4, index)]
  # private-cidrs = [for index, az in local.azs : cidrsubnet(local.project-cidr, 4, length(local.azs) + index)]
  tags = {
    yb_owner   = "yrampuria"
    yb_task    = "demo"
    yb_project = local.project-name
    yb_env     = "demo"
    yb_poc     = "poc1"
  }
  ebs_csi_service_account_namespace = "kube-system"
  ebs_csi_service_account_name = "ebs-csi-controller-sa"
}

data "aws_route53_zone" "project-hosted-zone" {
  private_zone = false
  name         = "${local.project-root-domain}."
}
