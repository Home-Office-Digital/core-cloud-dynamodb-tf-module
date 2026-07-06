# Wrapper for the Core Cloud DynamoDB module

The configuration in this directory contains a supported compatibility wrapper for the root DynamoDB module. It allows consumers to manage several DynamoDB tables from a single module call by passing an `items` map.

For new Terraform configurations, prefer using native Terraform `for_each` on the root module where possible. Use this wrapper when the calling workflow benefits from a single wrapper module, such as Terragrunt configurations that manage multiple resources from one `terragrunt.hcl` file.

This wrapper does not implement any extra functionality.

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module.git//wrappers?ref={tag}"
}

inputs = {
  defaults = { # Default values
    create_table = true
    tags = {
      account-code     = "example"
      budget-holder    = "example"
      cost-centre      = "example"
      environment-type = "test"
      hosting-platform = "test-platform"
      owner-business   = "example"
      portfolio-id     = "example"
      project-id       = "example"
      service-id       = "example"
      source-repo      = "core-cloud-dynamodb-tf-module"
    }
  }

  items = {
    my-item = {
      # omitted... can be any argument supported by the module
    }
    my-second-item = {
      # omitted... can be any argument supported by the module
    }
    # omitted...
  }
}
```

## Usage with Terraform

```hcl
module "wrapper" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-dynamodb-tf-module.git//wrappers?ref={tag}"

  defaults = { # Default values
    create_table = true
    tags = {
      account-code     = "example"
      budget-holder    = "example"
      cost-centre      = "example"
      environment-type = "test"
      hosting-platform = "test-platform"
      owner-business   = "example"
      portfolio-id     = "example"
      project-id       = "example"
      service-id       = "example"
      source-repo      = "core-cloud-dynamodb-tf-module"
    }
  }

  items = {
    my-item = {
      # omitted... can be any argument supported by the module
    }
    my-second-item = {
      # omitted... can be any argument supported by the module
    }
    # omitted...
  }
}
```
