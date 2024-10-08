
resource "aws_iam_policy" "ebs_csi_controller" {
  name_prefix = "ebs-csi-controller"
  description = "EKS ebs-csi-controller policy for cluster ${local.project-name}-eks"
  policy      = file("${path.module}/templates/eks-ebs-csi-controller-iam-policy.json")
}


module "ebs_csi_controller_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.30.0"
  create_role                   = true
  role_name                     = "${local.project-name}-eks-ebs-csi-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.ebs_csi_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.ebs_csi_service_account_namespace}:${local.ebs_csi_service_account_name}"]
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "${local.project-name}-eks"
  cluster_version = local.eks-version

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.project-name}-eks-ebs-csi-controller"
      most_recent              = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
  }

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  control_plane_subnet_ids  = module.vpc.intra_subnets
  cluster_ip_family         = "ipv4"
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    use_custom_launch_template = false

    min_size     = 0
    max_size     = 3
    desired_size = 1

    disk_size                  = 50
    instance_types             = [local.eks-worker-type]
    iam_role_attach_cni_policy = true

    capacity_type   = "SPOT"
    use_name_prefix = true
    tags = merge(local.tags, {
      yb_aws_service       = "eks"
      yb_aws_resource_type = "worker"
    })
  }

  eks_managed_node_groups = { for idx, az in local.azs :
    "${local.project-name}-${idx}" => {
      name = "${local.project-name}-${idx}"
      availability_zones = [az]
      subnet_ids         = [module.vpc.private_subnets[idx]]
    }
  }


  tags = merge(local.tags, {
    Name                 = "${local.project-name}-eks"
    yb_aws_service       = "eks"
    yb_aws_resource_type = "eks"
    # nat_gw               = aws_eip_association.nat-eip-association.allocation_id
  })
  # depends_on = [
  #   aws_eip_association.nat-eip-association
  # ]
}

# module "vpc_cni_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name_prefix      = "${local.project-name}-VPC-CNI-IRSA"
#   attach_vpc_cni_policy = true
#   vpc_cni_enable_ipv6   = false

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-node"]
#     }
#   }

#   tags = local.tags
# }
# module "eks-nodes" {
#   for_each = { for i,az in local.azs: az => module.vpc.private_subnets[i] }

#   source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
#   cluster_name = module.eks.cluster_name
#   name = "${local.project-name}-${each.key}"
#   min_size     = 0
#   max_size     = 10
#   desired_size = 1
#   cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
#   vpc_security_group_ids            = [module.eks.node_security_group_id]
#   subnet_ids = [each.value]
#   # availability_zones = [each.key]
#   disk_size                  = 50
#   instance_types             = [local.eks-worker-type]
#   iam_role_attach_cni_policy = true
#   capacity_type   = "SPOT"
#   use_name_prefix = true
#   tags = merge(local.tags, {
#     yb_aws_service       = "eks"
#     yb_aws_resource_type = "worker"
#   })
# }

provider "kubernetes" {
  host = module.eks.cluster_endpoint

  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
  
}


provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}

