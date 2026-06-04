# Unit tests for the image_uri resolution logic mirrored from src/main.tf.
#
# These run in plan mode against the self-contained fixture in this directory
# (no AWS provider / credentials required):
#
#   terraform -chdir=test/unit/image_uri init
#   terraform -chdir=test/unit/image_uri test
#
# The component itself can only be planned via the atmos/Terratest harness
# (it depends on the account-map and remote-state modules), so this isolates
# the pure logic that previously failed at plan time.

# Regression test for the zip-deploy bug: image_uri is null but a
# cicd_ssm_param_name is set. Before the coalesce() fix, strcontains() received
# a null and the plan errored with "Invalid value for \"str\" parameter".
run "zip_deploy_with_ssm_param_does_not_error" {
  command = plan

  variables {
    image_uri           = null
    cicd_ssm_param_name = "/cicd/lambda/sha"
    ssm_param_value     = "abc123"
  }

  assert {
    condition     = output.image_uri == null
    error_message = "image_uri must remain null for a zip deploy, even when cicd_ssm_param_name is set"
  }
}

# When disabled, the SSM data source has count 0 (one([]) == null). Even with a
# templated image_uri and cicd_ssm_param_name set, the format branch must not be
# selected, otherwise format(image_uri, null) fails at plan time.
run "disabled_with_ssm_param_and_template_does_not_error" {
  command = plan

  variables {
    enabled             = false
    image_uri           = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:%s"
    cicd_ssm_param_name = "/cicd/lambda/sha"
    ssm_param_value     = null
  }

  assert {
    condition     = output.image_uri == "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:%s"
    error_message = "When disabled, image_uri must pass through unchanged without formatting"
  }
}

# A templated image_uri with a cicd_ssm_param_name gets the SSM value formatted in.
run "templated_image_uri_is_formatted_with_ssm_value" {
  command = plan

  variables {
    image_uri           = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:%s"
    cicd_ssm_param_name = "/cicd/lambda/sha"
    ssm_param_value     = "abc123"
  }

  assert {
    condition     = output.image_uri == "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:abc123"
    error_message = "Templated image_uri should be formatted with the SSM parameter value"
  }
}

# A static image_uri (no %s placeholder) is passed through unchanged.
run "static_image_uri_passes_through" {
  command = plan

  variables {
    image_uri           = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:latest"
    cicd_ssm_param_name = "/cicd/lambda/sha"
    ssm_param_value     = "abc123"
  }

  assert {
    condition     = output.image_uri == "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:latest"
    error_message = "Static image_uri should pass through unchanged"
  }
}

# Without cicd_ssm_param_name, the image_uri is passed through verbatim
# (even if it contains a %s placeholder).
run "image_uri_without_ssm_param_passes_through" {
  command = plan

  variables {
    image_uri           = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:%s"
    cicd_ssm_param_name = null
    ssm_param_value     = null
  }

  assert {
    condition     = output.image_uri == "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:%s"
    error_message = "Without cicd_ssm_param_name, image_uri should pass through unchanged"
  }
}
