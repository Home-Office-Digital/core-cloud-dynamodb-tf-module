mock_provider "aws" {}

variables {
  name     = "validation-table"
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

run "reject_invalid_billing_mode" {
  command = plan

  variables {
    billing_mode = "INVALID"
  }

  expect_failures = [var.billing_mode]
}

run "reject_invalid_stream_view_type" {
  command = plan

  variables {
    stream_view_type = "BAD_VALUE"
  }

  expect_failures = [var.stream_view_type]
}

run "reject_invalid_import_format" {
  command = plan

  variables {
    import_table = {
      input_format = "XML"
      bucket       = "example-bucket"
    }
  }

  expect_failures = [var.import_table]
}

run "reject_missing_mandatory_tags" {
  command = plan

  variables {
    tags = {
      service-id = "SV5005"
    }
  }

  expect_failures = [var.tags]
}