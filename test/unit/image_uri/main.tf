terraform {
  required_version = ">= 1.3.0"
}

# Inputs that drive the image_uri resolution in the real component.
variable "image_uri" {
  type    = string
  default = null
}

variable "cicd_ssm_param_name" {
  type    = string
  default = null
}

# Stands in for `one(data.aws_ssm_parameter.cicd_ssm_param[*].value)` in the
# real component, so this fixture stays free of the AWS provider / data sources.
variable "ssm_param_value" {
  type    = string
  default = null
}

locals {
  # MIRROR of `local.image_uri` in ../../../src/main.tf. Keep these in sync.
  #
  # Regression guard: Terraform/OpenTofu's `&&` does NOT short-circuit, so both
  # operands are always evaluated. When deploying a zip (image_uri == null) with
  # a cicd_ssm_param_name set, `strcontains(var.image_uri, "%s")` would receive
  # null and error. The inner ternary DOES short-circuit, so it feeds strcontains
  # a safe "" without coalesce() (which would reject the empty string and error).
  image_uri = (var.cicd_ssm_param_name != null && var.image_uri != null && strcontains(var.image_uri == null ? "" : var.image_uri, "%s")) ? format(var.image_uri, var.ssm_param_value) : var.image_uri
}

output "image_uri" {
  value = local.image_uri
}
