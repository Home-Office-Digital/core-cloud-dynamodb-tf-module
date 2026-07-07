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
  type = list(object({
    name = string
    type = string
  }))
  default = []

  validation {
    condition     = alltrue([for attribute in var.attributes : contains(["S", "N", "B"], attribute.type)])
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
  default     = true
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
  type = list(object({
    name               = string
    hash_key           = string
    projection_type    = string
    range_key          = optional(string, null)
    read_capacity      = optional(number, null)
    write_capacity     = optional(number, null)
    non_key_attributes = optional(list(string), null)
    on_demand_throughput = optional(object({
      max_read_request_units  = optional(number, null)
      max_write_request_units = optional(number, null)
    }), null)
  }))
  default = []

  validation {
    condition     = alltrue([for index in var.global_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], index.projection_type)])
    error_message = "All global secondary index projection_type values must be one of ALL, KEYS_ONLY, or INCLUDE."
  }

  validation {
    condition     = alltrue([for index in var.global_secondary_indexes : index.projection_type != "INCLUDE" || index.non_key_attributes != null])
    error_message = "Global secondary indexes with projection_type INCLUDE must set non_key_attributes."
  }

  validation {
    condition     = alltrue([for index in var.global_secondary_indexes : index.read_capacity == null || index.read_capacity > 0])
    error_message = "Global secondary index read_capacity must be greater than 0 when set."
  }

  validation {
    condition     = alltrue([for index in var.global_secondary_indexes : index.write_capacity == null || index.write_capacity > 0])
    error_message = "Global secondary index write_capacity must be greater than 0 when set."
  }
}

variable "local_secondary_indexes" {
  description = "Describe an LSI on the table; these can only be allocated at creation so you cannot change this definition after you have created the resource."
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string
    non_key_attributes = optional(list(string), null)
  }))
  default = []

  validation {
    condition     = alltrue([for index in var.local_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], index.projection_type)])
    error_message = "All local secondary index projection_type values must be one of ALL, KEYS_ONLY, or INCLUDE."
  }

  validation {
    condition     = alltrue([for index in var.local_secondary_indexes : index.projection_type != "INCLUDE" || index.non_key_attributes != null])
    error_message = "Local secondary indexes with projection_type INCLUDE must set non_key_attributes."
  }
}

variable "replica_regions" {
  description = "Region names for creating replicas for a global DynamoDB table."
  type = list(object({
    region_name            = string
    kms_key_arn            = optional(string, null)
    propagate_tags         = optional(bool, null)
    point_in_time_recovery = optional(bool, null)
  }))
  default = []
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
  default     = true
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
  type = object({
    scale_in_cooldown  = optional(number, 0)
    scale_out_cooldown = optional(number, 0)
    target_value       = optional(number, 70)
  })
  default = {
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
    target_value       = 70
  }

  validation {
    condition     = var.autoscaling_defaults.scale_in_cooldown >= 0 && var.autoscaling_defaults.scale_out_cooldown >= 0
    error_message = "autoscaling_defaults cooldown values must be greater than or equal to 0."
  }

  validation {
    condition     = var.autoscaling_defaults.target_value > 0
    error_message = "autoscaling_defaults.target_value must be greater than 0."
  }
}

variable "autoscaling_read" {
  description = "A map of read autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling"
  type = object({
    max_capacity       = number
    scale_in_cooldown  = optional(number, null)
    scale_out_cooldown = optional(number, null)
    target_value       = optional(number, null)
  })
  default = null

  validation {
    condition     = var.autoscaling_read == null || var.autoscaling_read.max_capacity > 0
    error_message = "autoscaling_read.max_capacity must be greater than 0."
  }

  validation {
    condition     = var.autoscaling_read == null || var.autoscaling_read.scale_in_cooldown == null || var.autoscaling_read.scale_in_cooldown >= 0
    error_message = "autoscaling_read.scale_in_cooldown must be greater than or equal to 0 when set."
  }

  validation {
    condition     = var.autoscaling_read == null || var.autoscaling_read.scale_out_cooldown == null || var.autoscaling_read.scale_out_cooldown >= 0
    error_message = "autoscaling_read.scale_out_cooldown must be greater than or equal to 0 when set."
  }

  validation {
    condition     = var.autoscaling_read == null || var.autoscaling_read.target_value == null || var.autoscaling_read.target_value > 0
    error_message = "autoscaling_read.target_value must be greater than 0 when set."
  }
}

variable "autoscaling_write" {
  description = "A map of write autoscaling settings. `max_capacity` is the only required key. See example in examples/autoscaling"
  type = object({
    max_capacity       = number
    scale_in_cooldown  = optional(number, null)
    scale_out_cooldown = optional(number, null)
    target_value       = optional(number, null)
  })
  default = null

  validation {
    condition     = var.autoscaling_write == null || var.autoscaling_write.max_capacity > 0
    error_message = "autoscaling_write.max_capacity must be greater than 0."
  }

  validation {
    condition     = var.autoscaling_write == null || var.autoscaling_write.scale_in_cooldown == null || var.autoscaling_write.scale_in_cooldown >= 0
    error_message = "autoscaling_write.scale_in_cooldown must be greater than or equal to 0 when set."
  }

  validation {
    condition     = var.autoscaling_write == null || var.autoscaling_write.scale_out_cooldown == null || var.autoscaling_write.scale_out_cooldown >= 0
    error_message = "autoscaling_write.scale_out_cooldown must be greater than or equal to 0 when set."
  }

  validation {
    condition     = var.autoscaling_write == null || var.autoscaling_write.target_value == null || var.autoscaling_write.target_value > 0
    error_message = "autoscaling_write.target_value must be greater than 0 when set."
  }
}

variable "autoscaling_indexes" {
  description = "A map of index autoscaling configurations. See example in examples/autoscaling"
  type = map(object({
    read_max_capacity  = number
    read_min_capacity  = number
    write_max_capacity = number
    write_min_capacity = number
    scale_in_cooldown  = optional(number, null)
    scale_out_cooldown = optional(number, null)
    target_value       = optional(number, null)
  }))
  default = {}

  validation {
    condition     = alltrue([for index in var.autoscaling_indexes : index.read_min_capacity > 0 && index.read_max_capacity > 0 && index.write_min_capacity > 0 && index.write_max_capacity > 0])
    error_message = "autoscaling_indexes capacity values must be greater than 0."
  }

  validation {
    condition     = alltrue([for index in var.autoscaling_indexes : index.read_min_capacity <= index.read_max_capacity && index.write_min_capacity <= index.write_max_capacity])
    error_message = "autoscaling_indexes min capacity values must be less than or equal to max capacity values."
  }

  validation {
    condition     = alltrue([for index in var.autoscaling_indexes : index.scale_in_cooldown == null || index.scale_in_cooldown >= 0])
    error_message = "autoscaling_indexes scale_in_cooldown values must be greater than or equal to 0 when set."
  }

  validation {
    condition     = alltrue([for index in var.autoscaling_indexes : index.scale_out_cooldown == null || index.scale_out_cooldown >= 0])
    error_message = "autoscaling_indexes scale_out_cooldown values must be greater than or equal to 0 when set."
  }

  validation {
    condition     = alltrue([for index in var.autoscaling_indexes : index.target_value == null || index.target_value > 0])
    error_message = "autoscaling_indexes target_value values must be greater than 0 when set."
  }
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
  type = object({
    input_format           = string
    input_compression_type = optional(string, null)
    bucket                 = string
    bucket_owner           = optional(string, null)
    key_prefix             = optional(string, null)
    input_format_options = optional(object({
      csv = optional(object({
        delimiter   = optional(string, null)
        header_list = optional(list(string), null)
      }), null)
    }), null)
  })
  default = null

  validation {
    condition     = var.import_table == null || contains(["CSV", "DYNAMODB_JSON", "ION"], var.import_table.input_format)
    error_message = "import_table.input_format must be one of CSV, DYNAMODB_JSON, or ION."
  }

  validation {
    condition     = var.import_table == null || var.import_table.input_compression_type == null || contains(["GZIP", "ZSTD", "NONE"], var.import_table.input_compression_type)
    error_message = "import_table.input_compression_type must be one of GZIP, ZSTD, or NONE when set."
  }
}

variable "ignore_changes_global_secondary_index" {
  description = "Whether to ignore changes lifecycle to global secondary indices, useful for provisioned tables with scaling"
  type        = bool
  default     = false
}

variable "on_demand_throughput" {
  description = "Sets the maximum number of read and write units for the specified on-demand table"
  type = object({
    max_read_request_units  = optional(number, null)
    max_write_request_units = optional(number, null)
  })
  default = null

  validation {
    condition     = var.on_demand_throughput == null || var.on_demand_throughput.max_read_request_units == null || var.on_demand_throughput.max_read_request_units > 0
    error_message = "on_demand_throughput.max_read_request_units must be greater than 0 when set."
  }

  validation {
    condition     = var.on_demand_throughput == null || var.on_demand_throughput.max_write_request_units == null || var.on_demand_throughput.max_write_request_units > 0
    error_message = "on_demand_throughput.max_write_request_units must be greater than 0 when set."
  }
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
