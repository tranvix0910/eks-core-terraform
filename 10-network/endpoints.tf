# S3 Gateway endpoint.
#
# Without this, every S3 request from a private subnet goes out through the NAT
# Gateway, which charges per GB processed. Loki, Mimir and Tempo write their
# entire dataset to S3 continuously, so that bill grows with every log line.
#
# A Gateway endpoint is just a route table entry. It costs nothing - no hourly
# charge, no data charge. There is no reason not to have it.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    module.vpc.private_route_table_ids,
    module.vpc.public_route_table_ids,
  )

  tags = { Name = "${local.name}-s3" }
}

# Not created: ECR interface endpoints.
#
# Interface endpoints use PrivateLink and DO cost money - roughly $0.01/hour per
# endpoint per AZ, plus per-GB processing. Against NAT at ~$0.05/GB the break-even
# sits around 600-700 GB of image pulls per month. A lab pulling a handful of
# images stays well under that, so NAT is cheaper here.
