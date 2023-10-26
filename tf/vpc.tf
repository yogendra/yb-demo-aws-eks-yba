
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.project-name}-vpc"
  cidr = local.project-cidr

  azs             = local.azs
  private_subnets = local.private-subnets
  public_subnets  = local.public-subbets
  intra_subnets   = local.intra-subnets

  enable_nat_gateway = false
  enable_vpn_gateway = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.project-name}-eks" = "shared"
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.project-name}-eks" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = merge(local.tags, {
    yb_aws_service       = "ec2"
    yb_aws_resource_type = "vpc"
  })
  depends_on = [
    aws_iam_user_policy_attachment.yba-policy-attach
  ]

}
module "nat" {
  source = "int128/nat-instance/aws"

  name                        = "${local.project-name}-nat"
  vpc_id                      = module.vpc.vpc_id
  public_subnet               = module.vpc.public_subnets[0]
  private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  private_route_table_ids     = module.vpc.private_route_table_ids
  use_spot_instance           = true

  tags = merge(local.tags, {
    Name                 = "${local.project-name}-nat"
    yb_aws_service       = "ec2"
    yb_aws_resource_type = "vpc"
  })
  depends_on = [
    module.vpc
  ]
}

resource "aws_eip" "nat-eip" {
  tags = {
    Name             = "${local.project-name}-nat-eip"
    yb_aws_service   = "ec2"
    yb_resource_type = "eip"
  }
  depends_on = [
    module.vpc
  ]
}
resource "aws_eip_association" "nat-eip-association" {
  allocation_id        = aws_eip.nat-eip.id
  network_interface_id = module.nat.eni_id
}
