# TLS for the internal ALB fronting Mimir remote_write and Loki push - see
# eks-core-gitops: platform/observability/ingress/internal-ingress.yaml for the Ingress
# side, and the two X-Scope-OrgID/loki push senders on cluster 1
# (eks-core-gitops: platform/addons/prometheus/values.yaml,
# eks-core-gitops: platform/addons/alloy/values.yaml) for the client side.
#
# The CA and leaf cert were issued by cert-manager on cluster eks-workload
# (the cluster that already runs cert-manager for Rancher - see
# eks-core-gitops: platform/addons/cert-manager/values.yaml), not by this layer:
#   ClusterIssuer selfsigned-root -> Certificate observability-ca
#     (namespace cert-manager, secret observability-ca-secret)
#   ClusterIssuer observability-ca-issuer (signs with that CA)
#     -> Certificate observability-alb-tls
#     (namespace cert-manager, secret observability-alb-tls,
#      SANs: mimir.observability.internal, loki.observability.internal)
#
# ALB only accepts certificates that live in ACM (or IAM), never a raw K8s TLS
# Secret directly - so the cert.crt/key.pem/chain.pem exported from that
# Secret were imported into ACM by hand first:
#
#   kubectl --context eks-workload get secret observability-alb-tls -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > certs/cert.pem
#   kubectl --context eks-workload get secret observability-alb-tls -n cert-manager -o jsonpath='{.data.tls\.key}'  | base64 -d > certs/key.pem
#   kubectl --context eks-workload get secret observability-alb-tls -n cert-manager -o jsonpath='{.data.ca\.crt}'   | base64 -d > certs/chain.pem
#   aws acm import-certificate --certificate fileb://certs/cert.pem \
#     --private-key fileb://certs/key.pem --certificate-chain fileb://certs/chain.pem \
#     --region ap-southeast-1 --profile eks-core
#
# This resource brings that already-imported certificate under Terraform
# management via `terraform import`, rather than letting it exist as an
# untracked resource only AWS CLI knows about. The three file() arguments
# below must keep pointing at the exact same bytes that were imported, or
# Terraform will try to re-import (replace) the certificate on the next
# apply - certs/*.pem are gitignored (*.pem, *.key), so they only exist on
# whichever machine ran the import command; anyone else running `terraform
# plan` needs those same three files present locally first.
# BOOTSTRAP TEMP COMMENT (Tokyo rebuild): needs cert-manager running on the
# new eks-workload cluster to issue the cert first (see the export/import
# steps above), and certs/*.pem don't exist yet on this machine for the new
# cluster. Re-enable once cert-manager is deployed and the export/import
# steps above have been re-run for Tokyo.
# resource "aws_acm_certificate" "observability_alb" {
#   private_key       = file("${path.module}/../certs/key.pem")
#   certificate_body  = file("${path.module}/../certs/cert.pem")
#   certificate_chain = file("${path.module}/../certs/chain.pem")
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = merge(local.tags, { Name = "${local.name}-internal-alb" })
# }
