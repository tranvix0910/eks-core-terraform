# TLS cert for the internal ALB (mimir/loki.observability.internal).
# Issued by cert-manager on eks-workload, exported to certs/*.pem (gitignored), then imported to ACM.
# Disabled until cert-manager runs on the Tokyo eks-workload cluster and certs/*.pem exist locally.
#
# resource "aws_acm_certificate" "observability_alb" {
#   private_key       = file("${path.module}/../certs/key.pem")
#   certificate_body  = file("${path.module}/../certs/cert.pem")
#   certificate_chain = file("${path.module}/../certs/chain.pem")
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = merge(var.tags, { Name = "${local.name}-internal-alb" })
# }
