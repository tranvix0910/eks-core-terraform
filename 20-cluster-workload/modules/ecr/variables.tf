variable "repository_names" {
  description = "ECR repository names to create, e.g. [\"shopnow/shopnow-frontend\", ...]"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "MUTABLE allows overriding tags during builds and deployments."
  type        = string
  default     = "MUTABLE"
}

variable "max_image_count" {
  description = "Images per repository to retain before the lifecycle policy expires the oldest."
  type        = number
  default     = 10
}

variable "tags" {
  type    = map(string)
  default = {}
}
