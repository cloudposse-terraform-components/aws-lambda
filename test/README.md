# Test

## Integration tests (atmos / Terratest)

The component is exercised end-to-end with the Cloud Posse Terratest + atmos
harness. These deploy and destroy real AWS resources and require credentials:

```bash
atmos test run
```

## Unit tests (native `terraform test`, no AWS required)

Fast, credential-free unit tests live under `unit/`. They isolate pure logic
from `src/` that cannot be planned standalone (the component depends on the
`account-map` and remote-state modules).

### `unit/image_uri`

Guards the `image_uri` resolution in `src/main.tf`. Regression coverage for the
zip-deploy bug where `image_uri == null` while `cicd_ssm_param_name` is set —
`&&` does not short-circuit in Terraform/OpenTofu, so `strcontains()` was fed a
null and the plan failed.

```bash
terraform -chdir=test/unit/image_uri init
terraform -chdir=test/unit/image_uri test
```

The local logic in `unit/image_uri/main.tf` mirrors `local.image_uri` in
`src/main.tf`; keep the two in sync when changing image_uri handling.
