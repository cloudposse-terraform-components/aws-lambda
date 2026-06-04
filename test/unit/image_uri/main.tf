terraform {
  required_version = ">= 1.3.0"
}

# Inputs that drive the image_uri resolution in the real component.
variable "enabled" {
  type        = bool
  description = "Mirrors local.enabled in src. When false, the SSM data source has count 0, so the format branch must not be selected."
  default     = true
}

variable "image_uri" {
  type        = string
  description = "The ECR image URI, optionally containing a %s placeholder for the SSM parameter value. Mirrors var.image_uri in src."
  default     = null
}

variable "cicd_ssm_param_name" {
  type        = string
  description = "The name of the SSM parameter holding the latest version/sha. Mirrors var.cicd_ssm_param_name in src."
  default     = null
}

variable "ssm_param_value" {
  type        = string
  description = "Stands in for one(data.aws_ssm_parameter.cicd_ssm_param[*].value) so this fixture stays free of the AWS provider / data sources."
  default     = null
}

locals {
  # MIRROR of `local.image_uri` in ../../../src/main.tf. Keep these in sync.
  #
  # Regression guard: Terraform/OpenTofu's `&&` does NOT short-circuit, so both
  # operands are always evaluated. When deploying a zip (image_uri == null) with
  # a cicd_ssm_param_name set, `strcontains(var.image_uri, "%s")` would receive
  # null and error. The inner ternary DOES short-circuit, so it feeds strcontains
  # a safe "" without coalesce() (which would reject the empty string and error).
  #
  # The leading var.enabled mirrors local.enabled in src: the SSM data source is
  # gated on local.enabled, so the format branch (which reads one([...])) must not
  # be selected when disabled.
  image_uri = (var.enabled && var.cicd_ssm_param_name != null && var.image_uri != null && strcontains(var.image_uri == null ? "" : var.image_uri, "%s")) ? format(var.image_uri, var.ssm_param_value) : var.image_uri
}

output "image_uri" {
  description = "The resolved image_uri, mirroring local.image_uri in src/main.tf."
  value       = local.image_uri
}
