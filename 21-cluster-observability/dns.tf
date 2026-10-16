resource "aws_route53_zone" "observability_internal" {
  name = "observability.internal"

  vpc {
    vpc_id = local.vpc_id
  }

  tags = local.tags
}

data "aws_lb" "observability_internal" {
  count = var.internal_observability_alb_name == null ? 0 : 1
  name  = var.internal_observability_alb_name
}

resource "aws_route53_record" "mimir" {
  count = length(data.aws_lb.observability_internal)

  zone_id = aws_route53_zone.observability_internal.zone_id
  name    = "mimir.observability.internal"
  type    = "A"

  alias {
    name                   = data.aws_lb.observability_internal[0].dns_name
    zone_id                = data.aws_lb.observability_internal[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "loki" {
  count = length(data.aws_lb.observability_internal)

  zone_id = aws_route53_zone.observability_internal.zone_id
  name    = "loki.observability.internal"
  type    = "A"

  alias {
    name                   = data.aws_lb.observability_internal[0].dns_name
    zone_id                = data.aws_lb.observability_internal[0].zone_id
    evaluate_target_health = true
  }
}
