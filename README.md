# Core Cloud DynamoDB Module

This DynamoDB child module is written and maintained as part of the Core Cloud Terraform module set. It creates and manages DynamoDB tables, optional indexes, autoscaling configuration, resource policies, table import settings, replicas, streams, point-in-time recovery, and server-side encryption configuration.

The repository includes Dependabot, Semantic Versioning workflows, Checkov scanning, and Sonarqube scanning. Repository ownership is defined in `CODEOWNERS`.

## Module Structure

<strong>---| .github</strong>
&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [dependabot.yaml](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/.github/dependabot.yaml)</strong> - Checks repository dependencies and raises pull requests for review.  \
&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| workflows</strong> \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-semver-label-check.yaml](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/.github/workflows/pull-request-semver-label-check.yaml)</strong> - Verifies pull requests to main have an appropriate semver label: major, minor, or patch. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-semver-tag-merge.yaml](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/.github/workflows/pull-request-semver-tag-merge.yaml)</strong> - Calculates and applies the semver tag when a pull request is merged. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [sast-scans.yaml](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/.github/workflows/sast-scans.yaml)</strong> - Runs Checkov and Sonarqube scans through Core Cloud shared workflows. \
<strong>---| [CHANGELOG.md](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/CHANGELOG.md)</strong> - Contains significant changes associated with semver tags.  \
<strong>---| [CODEOWNERS](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/CODEOWNERS)</strong> - Defines repository review ownership.  \
<strong>---| [CODE_OF_CONDUCT.md](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/CODE_OF_CONDUCT.md)</strong>  \
<strong>---| [CONTRIBUTING.md](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/CONTRIBUTING.md)</strong>  \
<strong>---| [LICENSE](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/LICENSE)</strong>  \
<strong>---| [README.md](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/README.md)</strong>  \
<strong>---| [main.tf](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/main.tf)</strong> - Contains the DynamoDB table resources and resource policy wiring.  \
<strong>---| [autoscaling.tf](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/autoscaling.tf)</strong> - Contains table and index autoscaling resources.  \
<strong>---| [outputs.tf](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/outputs.tf)</strong> - Contains output definitions for the module.  \
<strong>---| [variables.tf](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/variables.tf)</strong> - Contains module variable declarations.  \
<strong>---| [versions.tf](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/blob/main/versions.tf)</strong> - Contains Terraform and provider constraints.  \
<strong>---| tests</strong> - Contains Terraform native tests covering contract, validation, and security behaviors.  \
<strong>---| examples</strong> - Contains runnable examples for basic, autoscaling, and S3 import usage.  \
<strong>---| wrappers</strong> - Contains the retained wrapper module surface.

## Validation

Run the following commands before opening a pull request that changes Terraform code:

```sh
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

For changes to examples, run `terraform init -backend=false` and `terraform validate` from each affected example directory.

Run `terraform test` from the module root after changing validated module behavior or the `tests/` suite.

## Migration Notes

Consumers upgrading from versions before the typed-input release must pass the mandatory Core Cloud tags to this module. Optional object inputs such as `import_table` and `on_demand_throughput` now use `null` when unset instead of `{}`.

Point-in-time recovery and server-side encryption are enabled by default for new module consumers. Set `point_in_time_recovery_enabled = false` or `server_side_encryption_enabled = false` only where there is an approved exception. Deletion protection remains caller-controlled; production tables should set `deletion_protection_enabled = true` unless lifecycle automation requires otherwise.

## Usage

Recommended settings:

- Adhere to Core Cloud mandatory tags.
- Enable point-in-time recovery for production tables unless there is an approved exception.
- Enable server-side encryption, and provide a customer managed KMS key when required by the workload.
- Enable deletion protection for production tables unless lifecycle automation requires otherwise.
- Use `PAY_PER_REQUEST` unless provisioned capacity and autoscaling are explicitly required.

See the below example configuration:

```hcl
module "dynamodb_table" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module.git?ref={tag}"

  name                              = "my-table"
  hash_key                          = "id"
  table_class                       = "STANDARD"
  point_in_time_recovery_enabled    = true
  server_side_encryption_enabled    = true
  deletion_protection_enabled       = true

  attributes = [
    {
      name = "id"
      type = "N"
    }
  ]

  tags = {
    cost-centre      = "xxx"
    account-code     = "xxx"
    portfolio-id     = "xxx"
    project-id       = "xxx"
    service-id       = "xxx"
    environment-type = "test"
    hosting-platform = "test-platform"
    owner-business   = "xxx"
    budget-holder    = "xxx"
    source-repo      = "xxx"
  }
}
```

## Notes

**Warning: enabling or disabling autoscaling can cause your table to be recreated**

There are two separate Terraform resources used for the DynamoDB table: one is for when autoscaling is enabled and the other is for when autoscaling is disabled. If your table is already created and then you change `autoscaling_enabled`, Terraform can recreate the table unless you move state to the new resource address. For example:

```sh
terraform state mv module.dynamodb_table.aws_dynamodb_table.this module.dynamodb_table.aws_dynamodb_table.autoscaled
```

**Warning: autoscaling with global secondary indexes**

When using an autoscaled provisioned table with GSIs, applying Terraform changes while a GSI is scaled up can reset the capacity. There is an [open issue for this on the AWS Provider](https://github.com/hashicorp/terraform-provider-aws/issues/671). To work around this issue, you can enable `ignore_changes_global_secondary_index`; however, changes to GSIs will then be ignored by Terraform and must be applied manually or through separate automation.

Setting `ignore_changes_global_secondary_index` after the table is created can also cause the table resource address to change. Move state before applying where appropriate:

```sh
terraform state mv module.dynamodb_table.aws_dynamodb_table.autoscaled module.dynamodb_table.aws_dynamodb_table.autoscaled_ignore_gsi
```

## Module Wrappers

Users of this Terraform module can create multiple similar resources by using the [`for_each` meta-argument within a module block](https://www.terraform.io/language/meta-arguments/for_each).

The `wrappers/` directory is retained for consumers that need the wrapper module pattern, such as Terragrunt-based consumers.

## Examples

- [Basic example](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/tree/main/examples/basic)
- [Autoscaling example](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/tree/main/examples/autoscaling)
- [S3 import example](https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module/tree/main/examples/s3-import)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.88.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.88.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.index_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.index_write_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.table_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.table_write_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.index_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_appautoscaling_target.index_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_appautoscaling_target.table_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_appautoscaling_target.table_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_dynamodb_resource_policy.autoscaled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.autoscaled_gsi_ignore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_resource_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_resource_policy) | resource |
| [aws_dynamodb_table.autoscaled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.autoscaled_gsi_ignore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | List of nested attribute definitions. Only required for hash\_key and range\_key attributes. Each attribute has two properties: name - (Required) The name of the attribute, type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data | <pre>list(object({<br/>    name = string<br/>    type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_autoscaling_defaults"></a> [autoscaling\_defaults](#input\_autoscaling\_defaults) | A map of default autoscaling settings | <pre>object({<br/>    scale_in_cooldown  = optional(number, 0)<br/>    scale_out_cooldown = optional(number, 0)<br/>    target_value       = optional(number, 70)<br/>  })</pre> | <pre>{<br/>  "scale_in_cooldown": 0,<br/>  "scale_out_cooldown": 0,<br/>  "target_value": 70<br/>}</pre> | no |
| <a name="input_autoscaling_enabled"></a> [autoscaling\_enabled](#input\_autoscaling\_enabled) | Whether or not to enable autoscaling. See note in README about this setting | `bool` | `false` | no |
| <a name="input_autoscaling_indexes"></a> [autoscaling\_indexes](#input\_autoscaling\_indexes) | A map of index autoscaling configurations. See example in examples/autoscaling | <pre>map(object({<br/>    read_max_capacity  = number<br/>    read_min_capacity  = number<br/>    write_max_capacity = number<br/>    write_min_capacity = number<br/>    scale_in_cooldown  = optional(number, null)<br/>    scale_out_cooldown = optional(number, null)<br/>    target_value       = optional(number, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_autoscaling_read"></a> [autoscaling\_read](#input\_autoscaling\_read) | A map of read autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling | <pre>object({<br/>    max_capacity       = number<br/>    scale_in_cooldown  = optional(number, null)<br/>    scale_out_cooldown = optional(number, null)<br/>    target_value       = optional(number, null)<br/>  })</pre> | `null` | no |
| <a name="input_autoscaling_write"></a> [autoscaling\_write](#input\_autoscaling\_write) | A map of write autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling | <pre>object({<br/>    max_capacity       = number<br/>    scale_in_cooldown  = optional(number, null)<br/>    scale_out_cooldown = optional(number, null)<br/>    target_value       = optional(number, null)<br/>  })</pre> | `null` | no |
| <a name="input_billing_mode"></a> [billing\_mode](#input\_billing\_mode) | Controls how you are billed for read/write throughput and how you manage capacity. The valid values are PROVISIONED or PAY\_PER\_REQUEST | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_create_table"></a> [create\_table](#input\_create\_table) | Controls if DynamoDB table and associated resources are created | `bool` | `true` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | Enables deletion protection for table | `bool` | `null` | no |
| <a name="input_dynamodb_resource_policy"></a> [dynamodb\_resource\_policy](#input\_dynamodb\_resource\_policy) | Optional - you can specify a resource policy for the DynamoDB table, you can provide a JSON encoded string or File | `string` | `null` | no |
| <a name="input_global_secondary_indexes"></a> [global\_secondary\_indexes](#input\_global\_secondary\_indexes) | Describe a GSI for the table; subject to the normal limits on the number of GSIs, projected attributes, etc. | <pre>list(object({<br/>    name               = string<br/>    hash_key           = string<br/>    projection_type    = string<br/>    range_key          = optional(string, null)<br/>    read_capacity      = optional(number, null)<br/>    write_capacity     = optional(number, null)<br/>    non_key_attributes = optional(list(string), null)<br/>    on_demand_throughput = optional(object({<br/>      max_read_request_units  = optional(number, null)<br/>      max_write_request_units = optional(number, null)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_hash_key"></a> [hash\_key](#input\_hash\_key) | The attribute to use as the hash (partition) key. Must also be defined as an attribute | `string` | `null` | no |
| <a name="input_ignore_changes_global_secondary_index"></a> [ignore\_changes\_global\_secondary\_index](#input\_ignore\_changes\_global\_secondary\_index) | Whether to ignore changes lifecycle to global secondary indices, useful for provisioned tables with scaling | `bool` | `false` | no |
| <a name="input_import_table"></a> [import\_table](#input\_import\_table) | Configurations for importing s3 data into a new table. | <pre>object({<br/>    input_format           = string<br/>    input_compression_type = optional(string, null)<br/>    bucket                 = string<br/>    bucket_owner           = optional(string, null)<br/>    key_prefix             = optional(string, null)<br/>    input_format_options = optional(object({<br/>      csv = optional(object({<br/>        delimiter   = optional(string, null)<br/>        header_list = optional(list(string), null)<br/>      }), null)<br/>    }), null)<br/>  })</pre> | `null` | no |
| <a name="input_local_secondary_indexes"></a> [local\_secondary\_indexes](#input\_local\_secondary\_indexes) | Describe an LSI on the table; these can only be allocated at creation so you cannot change this definition after you have created the resource. | <pre>list(object({<br/>    name               = string<br/>    range_key          = string<br/>    projection_type    = string<br/>    non_key_attributes = optional(list(string), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the DynamoDB table | `string` | `null` | no |
| <a name="input_on_demand_throughput"></a> [on\_demand\_throughput](#input\_on\_demand\_throughput) | Sets the maximum number of read and write units for the specified on-demand table | <pre>object({<br/>    max_read_request_units  = optional(number, null)<br/>    max_write_request_units = optional(number, null)<br/>  })</pre> | `null` | no |
| <a name="input_point_in_time_recovery_enabled"></a> [point\_in\_time\_recovery\_enabled](#input\_point\_in\_time\_recovery\_enabled) | Whether to enable point-in-time recovery | `bool` | `true` | no |
| <a name="input_range_key"></a> [range\_key](#input\_range\_key) | The attribute to use as the range (sort) key. Must also be defined as an attribute | `string` | `null` | no |
| <a name="input_read_capacity"></a> [read\_capacity](#input\_read\_capacity) | The number of read units for this table. If the billing\_mode is PROVISIONED, this field should be greater than 0 | `number` | `null` | no |
| <a name="input_replica_regions"></a> [replica\_regions](#input\_replica\_regions) | Region names for creating replicas for a global DynamoDB table. | <pre>list(object({<br/>    region_name            = string<br/>    kms_key_arn            = optional(string, null)<br/>    propagate_tags         = optional(bool, null)<br/>    point_in_time_recovery = optional(bool, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_restore_date_time"></a> [restore\_date\_time](#input\_restore\_date\_time) | Time of the point-in-time recovery point to restore. | `string` | `null` | no |
| <a name="input_restore_source_name"></a> [restore\_source\_name](#input\_restore\_source\_name) | Name of the table to restore. Must match the name of an existing table. | `string` | `null` | no |
| <a name="input_restore_source_table_arn"></a> [restore\_source\_table\_arn](#input\_restore\_source\_table\_arn) | ARN of the source table to restore. Must be supplied for cross-region restores. | `string` | `null` | no |
| <a name="input_restore_to_latest_time"></a> [restore\_to\_latest\_time](#input\_restore\_to\_latest\_time) | If set, restores table to the most recent point-in-time recovery point. | `bool` | `null` | no |
| <a name="input_server_side_encryption_enabled"></a> [server\_side\_encryption\_enabled](#input\_server\_side\_encryption\_enabled) | Whether or not to enable encryption at rest using an AWS managed KMS customer master key (CMK) | `bool` | `true` | no |
| <a name="input_server_side_encryption_kms_key_arn"></a> [server\_side\_encryption\_kms\_key\_arn](#input\_server\_side\_encryption\_kms\_key\_arn) | The ARN of the CMK that should be used for the AWS KMS encryption. This attribute should only be specified if the key is different from the default DynamoDB CMK, alias/aws/dynamodb. | `string` | `null` | no |
| <a name="input_stream_enabled"></a> [stream\_enabled](#input\_stream\_enabled) | Indicates whether Streams are to be enabled (true) or disabled (false). | `bool` | `false` | no |
| <a name="input_stream_view_type"></a> [stream\_view\_type](#input\_stream\_view\_type) | When an item in the table is modified, StreamViewType determines what information is written to the table's stream. Valid values are KEYS\_ONLY, NEW\_IMAGE, OLD\_IMAGE, NEW\_AND\_OLD\_IMAGES. | `string` | `null` | no |
| <a name="input_table_class"></a> [table\_class](#input\_table\_class) | The storage class of the table. Valid values are STANDARD and STANDARD\_INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Must include Core Cloud mandatory tags. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Updated Terraform resource management timeouts | `map(string)` | <pre>{<br/>  "create": "10m",<br/>  "delete": "10m",<br/>  "update": "60m"<br/>}</pre> | no |
| <a name="input_ttl_attribute_name"></a> [ttl\_attribute\_name](#input\_ttl\_attribute\_name) | The name of the table attribute to store the TTL timestamp in | `string` | `""` | no |
| <a name="input_ttl_enabled"></a> [ttl\_enabled](#input\_ttl\_enabled) | Indicates whether ttl is enabled | `bool` | `false` | no |
| <a name="input_write_capacity"></a> [write\_capacity](#input\_write\_capacity) | The number of write units for this table. If the billing\_mode is PROVISIONED, this field should be greater than 0 | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | ARN of the DynamoDB table |
| <a name="output_dynamodb_table_id"></a> [dynamodb\_table\_id](#output\_dynamodb\_table\_id) | ID of the DynamoDB table |
| <a name="output_dynamodb_table_stream_arn"></a> [dynamodb\_table\_stream\_arn](#output\_dynamodb\_table\_stream\_arn) | The ARN of the Table Stream. Only available when var.stream\_enabled is true |
| <a name="output_dynamodb_table_stream_label"></a> [dynamodb\_table\_stream\_label](#output\_dynamodb\_table\_stream\_label) | A timestamp, in ISO 8601 format of the Table Stream. Only available when var.stream\_enabled is true |
<!-- END_TF_DOCS -->

## Attribution

This module was initially cut from [terraform-aws-modules/terraform-aws-dynamodb-table](https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table/tree/v4.2.0). It is now maintained as part of the Core Cloud Terraform module set.

## License

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.
