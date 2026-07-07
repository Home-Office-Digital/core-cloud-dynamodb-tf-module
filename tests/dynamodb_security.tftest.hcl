mock_provider "aws" {}

variables {
  name     = "secure-table"
  hash_key = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  tags = {
    account-code     = "AC2002"
    budget-holder    = "finops"
    cost-centre      = "CC1001"
    environment-type = "test"
    hosting-platform = "test-platform"
    owner-business   = "platform"
    portfolio-id     = "PF3003"
    project-id       = "PR4004"
    service-id       = "SV5005"
    source-repo      = "Home-Office-Digital/core-cloud-dynamodb-tf-module"
  }
}

run "security_defaults_are_enabled" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this[0].point_in_time_recovery[0].enabled == true
    error_message = "Point-in-time recovery should be enabled by default."
  }

  assert {
    condition     = aws_dynamodb_table.this[0].server_side_encryption[0].enabled == true
    error_message = "Server-side encryption should be enabled by default."
  }
}

run "deletion_protection_can_be_enabled_explicitly" {
  command = plan

  variables {
    deletion_protection_enabled = true
  }

  assert {
    condition     = aws_dynamodb_table.this[0].deletion_protection_enabled == true
    error_message = "Deletion protection should be configurable by callers."
  }
}

run "provisioned_gsi_requires_capacity" {
  command = plan

  variables {
    billing_mode   = "PROVISIONED"
    read_capacity  = 5
    write_capacity = 5
    attributes = [
      {
        name = "id"
        type = "S"
      },
      {
        name = "gsi_hash"
        type = "S"
      }
    ]
    global_secondary_indexes = [
      {
        name            = "GsiWithoutCapacity"
        hash_key        = "gsi_hash"
        projection_type = "ALL"
      }
    ]
  }

  expect_failures = [aws_dynamodb_table.this]
}