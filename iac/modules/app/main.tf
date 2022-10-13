variable "env" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "codedeploy_termination_wait_time" {
  type = number
}

variable "deploy_test_postman_collection" {
  type = string
}

variable "deploy_test_postman_environment" {
  type = string
}

locals {
  repo_name = "sg738-fav-color"
  tags = {
    env              = var.env
    data-sensitivity = "public"
    repo             = "https://github.com/byu-oit/${local.repo_name}"
  }
}

data "aws_ecr_repository" "my_ecr_repo" {
  name = "${local.repo_name}-${var.env}"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v3.4.0"
}

module "my_fargate_api" {
  source                           = "github.com/byu-oit/terraform-aws-fargate-api?ref=v3.3.1"
  app_name                         = "${local.repo_name}-${var.env}"
  container_port                   = 8080
  health_check_path                = "/health"
  codedeploy_test_listener_port    = 4443
  task_policies                    = [aws_iam_policy.dynamo_access.arn]
  hosted_zone                      = module.acs.route53_zone
  https_certificate_arn            = module.acs.certificate.arn
  public_subnet_ids                = module.acs.public_subnet_ids
  private_subnet_ids               = module.acs.private_subnet_ids
  vpc_id                           = module.acs.vpc.id
  codedeploy_service_role_arn      = module.acs.power_builder_role.arn
  codedeploy_termination_wait_time = var.codedeploy_termination_wait_time
  role_permissions_boundary_arn    = module.acs.role_permissions_boundary.arn
  tags                             = local.tags

  primary_container_definition = {
    name  = "${local.repo_name}-${var.env}"
    image = "${data.aws_ecr_repository.my_ecr_repo.repository_url}:${var.image_tag}"
    ports = [8080]
    environment_variables = {
      dynamo_table_name = aws_dynamodb_table.sg738-fav-color-dev.name
    }
    secrets           = {}
    efs_volume_mounts = null
  }

  autoscaling_config = {
    min_capacity = 1
    max_capacity = 2
  }

  codedeploy_lifecycle_hooks = {
    BeforeInstall         = null
    AfterInstall          = null
    AfterAllowTestTraffic = module.postman_test_lambda.lambda_function.function_name
    BeforeAllowTraffic    = null
    AfterAllowTraffic     = null
  }
}

// Databases
// If RDS is needed use the https://github.com/byu-oit/terraform-aws-rds/
// If DynamoDB Table is needed use the aws_dynamodb_table resource https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
// Then include the task policies and any env variables or secrets into the fargate module

resource "aws_dynamodb_table" "sg738-fav-color-dev" {
  hash_key     = "byuId"
  name         = "${local.repo_name}-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "byuId"
    type = "S"
  }
}
resource "aws_iam_policy" "dynamo_access" {
  name        = "${aws_dynamodb_table.sg738-fav-color-dev.name}-access"
  description = "Access to the ${aws_dynamodb_table.sg738-fav-color-dev.name} DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:ListTables",
          "dynamodb:DescribeTable",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:Update*",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = [
          aws_dynamodb_table.sg738-fav-color-dev.arn,
          "${aws_dynamodb_table.sg738-fav-color-dev.arn}/index/*"
        ]
      }
    ]
  })
}

// Smoke Test
module "postman_test_lambda" {
  source   = "github.com/byu-oit/terraform-aws-postman-test-lambda?ref=v3.2.3"
  app_name = "${local.repo_name}-${var.env}"
  postman_collections = [
    {
      collection  = var.deploy_test_postman_collection
      environment = null
    }
  ]
  # set the context here so that we don't need 10+ environment.json files
  test_env_var_overrides = {
    context : "https://${module.my_fargate_api.dns_record.name}:4443"
  }
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
}

output "url" {
  value = module.my_fargate_api.dns_record.name
}

output "codedeploy_app_name" {
  value = module.my_fargate_api.codedeploy_deployment_group.app_name
}

output "codedeploy_deployment_group_name" {
  value = module.my_fargate_api.codedeploy_deployment_group.deployment_group_name
}

output "codedeploy_appspec_json_file" {
  value = module.my_fargate_api.codedeploy_appspec_json_file
}
