module "route53_zone" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.0"

  name = var.route53_private_zone_name

  vpc = {
    main = {
      vpc_id = local.vpc_id
    }
  }

  records = length(data.aws_lb.observability_internal) == 0 ? {} : {
    for svc in ["mimir", "loki"] : svc => {
      name = svc
      type = "A"
      alias = {
        name                   = data.aws_lb.observability_internal[0].dns_name
        zone_id                = data.aws_lb.observability_internal[0].zone_id
        evaluate_target_health = true
      }
    }
  }

  tags = var.tags
}
