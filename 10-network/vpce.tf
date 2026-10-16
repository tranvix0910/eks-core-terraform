# S3 Gateway endpoint (free) - keeps Loki/Mimir/Tempo S3 traffic off NAT
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.6"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = concat(
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids,
      )
      tags = { Name = "${local.prefix}-vpce-s3" }
    }
  }

  tags = var.tags
}
