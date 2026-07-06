variable "create_table" {
  description = "Controls if DynamoDB table and associated resources are created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions. Only required for hash_key and range_key attributes. Each attribute has two properties: name - (Required) The name of the attribute, type - (Required) Attribute type, which must be a scalar type: S, N, or B for (S)tring, (N)umber or (B)inary data"
  type        = list(map(string))
  default     = []

  validation {
    condition     = alltrue([for attribute in var.attributes : contains(["S", "N", "B"], lookup(attribute, "type", ""))])
    error_message = "All DynamoDB attribute types must be one of S, N, or B."
  }
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key. Must also be defined as an attribute"
  type        = string
  default     = null
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key. Must also be defined as an attribute"
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "Controls how you are billed for read/write throughput and how you manage capacity. The valid values are PROVISIONED or PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "billing_mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "write_capacity" {
  description = "The number of write units for this table. If the billing_mode is PROVISIONED, this field should be greater than 0"
  type        = number
  default     = null

  validation {
    condition     = var.write_capacity == null || var.write_capacity > 0
    error_message = "write_capacity must be greater than 0 when set."
  }
}

variable "read_capacity" {
  description = "The number of read units for this table. If the billing_mode is PROVISIONED, this field should be greater than 0"
  type        = number
  default     = null

  validation {
    condition     = var.read_capacity == null || var.read_capacity > 0
    error_message = "read_capacity must be greater than 0 when set."
  }
}

variable "point_in_time_recovery_enabled" {
  description = "Whether to enable point-in-time recovery"
  type        = bool
  default     = false
}

variable "ttl_enabled" {
  description = "Indicates whether ttl is enabled"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "The name of the table attribute to store the TTL timestamp in"
  type        = string
  default     = ""
}

variable "global_secondary_indexes" {
  description = "Describe a GSI for the table; subject to the normal limits on the number of GSIs, projected attributes, etc."
  type        = any
  default     = []
}

variable "local_secondary_indexes" {
  description = "Describe an LSI on the table; these can only be allocated at creation so you cannot change this definition after you have created the resource."
  type        = any
  default     = []
}

variable "replica_regions" {
  description = "Region names for creating replicas for a global DynamoDB table."
  type        = any
  default     = []
}

variable "stream_enabled" {
  description = "Indicates whether Streams are to be enabled (true) or disabled (false)."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "When an item in the table is modified, StreamViewType determines what information is written to the table's stream. Valid values are KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  type        = string
  default     = null

  validation {
    condition     = var.stream_view_type == null || contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "stream_view_type must be one of KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, or NEW_AND_OLD_IMAGES when set."
  }
}

variable "server_side_encryption_enabled" {
  description = "Whether or not to enable encryption at rest using an AWS managed KMS customer master key (CMK)"
  type        = bool
  default     = false
}

variable "server_side_encryption_kms_key_arn" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption. This attribute should only be specified if the key is different from the default DynamoDB CMK, alias/aws/dynamodb."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources. Must include Core Cloud mandatory tags."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      contains(keys(var.tags), "account-code"),
      contains(keys(var.tags), "cost-centre"),
      contains(keys(var.tags), "portfolio-id"),
      contains(keys(var.tags), "project-id"),
      contains(keys(var.tags), "service-id"),
      contains(keys(var.tags), "environment-type"),
      contains(keys(var.tags), "owner-business"),
      contains(keys(var.tags), "budget-holder"),
      contains(keys(var.tags), "source-repo"),
      contains(keys(var.tags), "hosting-platform")
    ])
    error_message = "Tags must include all mandatory fields: account-code, cost-centre, portfolio-id, project-id, service-id, environment-type, owner-business, budget-holder, source-repo, and hosting-platform."
  }
}

variable "timeouts" {
  description = "Updated Terraform resource management timeouts"
  type        = map(string)
  default = {
    create = "10m"
    update = "60m"
    delete = "10m"
  }
}

variable "autoscaling_enabled" {
  description = "Whether or not to enable autoscaling. See note in README about this setting"
  type        = bool
  default     = false
}

variable "autoscaling_defaults" {
  description = "A map of default autoscaling settings"
  type        = map(string)
  default = {
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
    target_value       = 70
  }
}

variable "autoscaling_read" {
  description = "A map of read autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling"
  type        = map(string)
  default     = {}
}

variable "autoscaling_write" {
  description = "A map of write autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling"
  type        = map(string)
  default     = {}
}

variable "autoscaling_indexes" {
  description = "A map of index autoscaling configurations. See example in examples/autoscaling"
  type        = map(map(string))
  default     = {}
}

variable "table_class" {
  description = "The storage class of the table. Valid values are STANDARD and STANDARD_INFREQUENT_ACCESS"
  type        = string
  default     = null

  validation {
    condition     = var.table_class == null || contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be either STANDARD or STANDARD_INFREQUENT_ACCESS when set."
  }
}

variable "deletion_protection_enabled" {
  description = "Enables deletion protection for table"
  type        = bool
  default     = null
}

variable "import_table" {
  description = "Configurations for importing s3 data into a new table."
  type        = any
  default     = {}
}

variable "ignore_changes_global_secondary_index" {
  description = "Whether to ignore changes lifecycle to global secondary indices, useful for provisioned tables with scaling"
  type        = bool
  default     = false
}

variable "on_demand_throughput" {
  description = "Sets the maximum number of read and write units for the specified on-demand table"
  type        = any
  default     = {}
}

variable "restore_date_time" {
  description = "Time of the point-in-time recovery point to restore."
  type        = string
  default     = null
}

variable "restore_source_name" {
  description = "Name of the table to restore. Must match the name of an existing table."
  type        = string
  default     = null
}

variable "restore_source_table_arn" {
  description = "ARN of the source table to restore. Must be supplied for cross-region restores."
  type        = string
  default     = null
}

variable "restore_to_latest_time" {
  description = "If set, restores table to the most recent point-in-time recovery point."
  type        = bool
  default     = null
}

variable "dynamodb_resource_policy" {
  description = "Optional - you can specify a resource policy for the DynamoDB table, you can provide a JSON encoded string or File"
  type        = string
  default     = null
}
