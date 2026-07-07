mock_provider "aws" {}

variables {
  name     = "test-table"
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

run "basic_table_shape" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this[0].name == "test-table"
    error_message = "The table resource should use the configured name."
  }

  assert {
    condition     = aws_dynamodb_table.this[0].hash_key == "id"
    error_message = "The table resource should use the configured hash_key."
  }

  assert {
    condition     = aws_dynamodb_table.this[0].billing_mode == "PAY_PER_REQUEST"
    error_message = "The table should default to PAY_PER_REQUEST billing mode."
  }
}

run "name_tag_is_merged" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this[0].tags["Name"] == "test-table"
    error_message = "The module should merge a Name tag using the configured table name."
  }

  assert {
    condition     = aws_dynamodb_table.this[0].tags["service-id"] == "SV5005"
    error_message = "Caller tags should be propagated to the table resource."
  }
}

run "stream_outputs_remain_null_when_disabled" {
  command = plan

  assert {
    condition     = output.dynamodb_table_stream_arn == null
    error_message = "Stream ARN output should be null when streams are disabled."
  }

  assert {
    condition     = output.dynamodb_table_stream_label == null
    error_message = "Stream label output should be null when streams are disabled."
  }
}