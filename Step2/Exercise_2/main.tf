terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM Role for Lambda execution
# Defines a new IAM role resource.
resource "aws_iam_role" "lambda_exec_role" {
  # Names the IAM role.
  name = "lambda_exec_role"

  # Defines the trust relationship allowing Lambda to assume this role.
  # The policy allows the lambda.amazonaws.com service to assume the role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

# IAM Policy for Lambda logging
#  Attaches a policy to an IAM role.
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  # Specifies the ARN of the AWS-managed policy AWSLambdaBasicExecutionRole.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  # References the IAM role created earlier (lambda_exec_role).
  role = aws_iam_role.lambda_exec_role.name
}

# CloudWatch log group for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_logsss.function_name}"
  retention_in_days = 7
}

# Lambda function
resource "aws_lambda_function" "lambda_logsss" {
  # Package the lambda.py file into a ZIP file
  filename = "${path.module}/${data.archive_file.lambda.output_path}"
  # Sets the name of the Lambda function.
  function_name = "lambda_logsss"
  # Assigns the IAM role that the Lambda function will assume, defined later in the file.
  role = aws_iam_role.lambda_exec_role.arn
  # Specifies the function within your code that Lambda calls to start execution (lambda.py file's lambda_handler function).
  handler = "lambda.lambda_handler"
  # Sets the runtime environment to Python 3.9.
  runtime = "python3.12"
  # Computes a hash of the deployment package to detect changes. (filemd5, filesha1, filesha256, filesha512, filebase64sha512)
  #source_code_hash =  filebase64sha256("lambda.zip")
  source_code_hash = filebase64sha256("${data.archive_file.lambda.output_path}")
  #source_code_hash = data.archive_file.lambda.output_base64sha256

  # Sets an environment variable LOG_LEVEL to INFO.
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}


resource "null_resource" "zip_lambda" {
  provisioner "local-exec" {
    command = "powershell -Command \"Compress-Archive -Path lambda.py -DestinationPath lambda_function.zip\""
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy_attach" {
  # Specifies the ARN of the AWS-managed policy AWSLambdaBasicExecutionRole.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  # References the IAM role created earlier (lambda_exec_role).
  role = aws_iam_role.lambda_exec_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.lambda_exec_role.name
}

# Attach the role to EC2 instances to capture logs
resource "aws_instance" "example" {
  ami           = "ami-066784287e358dad1"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

# CloudWatch Log Stream for EC2 termination logs
resource "aws_cloudwatch_log_stream" "ec2_termination_log_stream" {
  name           = "ec2-termination-logs"
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name
}
