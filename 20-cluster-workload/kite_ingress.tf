# Kite is installed by helm_release.kite; its optional ALB Ingress has the same
# Terraform owner. Per-environment settings belong in gitignored *.auto.tfvars.
variable "kite_ingress_enabled" {
  description = "Expose Kite on the shared admin ALB's HTTP listener 8088. Disabled by default."
  type        = bool
  default     = false

  validation {
    condition     = !var.kite_ingress_enabled || length(var.kite_admin_cidrs) > 0
    error_message = "Set at least one kite_admin_cidrs entry before enabling Kite's ALB Ingress."
  }
}

variable "kite_admin_cidrs" {
  description = "Allowed IPv4 CIDRs for Kite's listener only. The shared ALB uses IPv4; unrestricted /0 ranges are forbidden."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for cidr in var.kite_admin_cidrs :
      can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) > 0, false)
    ])
    error_message = "kite_admin_cidrs must contain valid IPv4 CIDRs with a prefix from /1 to /32; /0 and IPv6 ranges are not supported."
  }
}

resource "kubernetes_ingress_v1" "kite" {
  count = var.kite_ingress_enabled ? 1 : 0

  metadata {
    name      = "kite"
    namespace = kubernetes_namespace_v1.kite.metadata[0].name

    annotations = {
      "alb.ingress.kubernetes.io/group.name"       = local.name
      "alb.ingress.kubernetes.io/group.order"      = "60"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 8088 }])
      "alb.ingress.kubernetes.io/inbound-cidrs"    = join(",", var.kite_admin_cidrs)
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kite"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
  depends_on             = [helm_release.kite]
}

output "kite_url" {
  description = "Kite's ALB URL when enabled and reconciled; otherwise null. HTTP is for lab access only."
  value = try(
    "http://${kubernetes_ingress_v1.kite[0].status[0].load_balancer[0].ingress[0].hostname}:8088",
    null,
  )
}
