provider "aws" {
  region = "us-west-2"
}

data "aws_iam_policy_document" "assume_role" {
  statement = {
    actions = ["sts:AssumeRole"]

    principals = {
      type        = "Service"
      identifiers = ["vmie.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:Externalid"
      values   = ["vmimport"]
    }
  }
}

data "aws_iam_policy_document" "vmimport" {
  statement {
    sid    = "1"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.input.arn}",
      "${aws_s3_bucket.input.arn}/*",
    ]
  }

  statement {
    sid    = "3"
    effect = "Allow"

    actions = [
      "ec2:ModifySnapshotAttribute",
      "ec2:CopySnapshot",
      "ec2:RegisterImage",
      "ec2:Describe*",
      "ec2:ImportSnapshot",
    ]

    resources = [
      "*",
    ]
  }
}

module "input_bucket_name" {
  source        = "github.com/traveloka/terraform-aws-resource-naming.git?ref=v0.17.1"
  name_prefix   = "vmimport-input"
  resource_type = "s3_bucket"
}

resource "aws_iam_role" "this" {
  name        = "vmimport"
  path        = "/"
  description = "Service Role for AWS vmimport"

  assume_role_policy    = "${data.aws_iam_policy_document.assume_role.json}"
  force_detach_policies = false
  max_session_duration  = 43200

  tags {
    Name          = "vmimport"
    Environment   = "management"
    ProductDomain = "devops"
    Description   = "Service Role for AWS vmimport"
    ManagedBy     = "terraform"
  }
}

resource "aws_iam_role_policy" "main" {
  name   = "main"
  role   = "${aws_iam_role.this.name}"
  policy = "${data.aws_iam_policy_document.vmimport.json}"
}

resource "aws_s3_bucket" "input" {
  bucket = "${module.input_bucket_name.name}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

output "iam_role_name" {
  value = "${aws_iam_role.this.name}"
}

output "iam_role_arn" {
  value = "${aws_iam_role.this.arn}"
}

output "bucket_name" {
  value = "${aws_s3_bucket.input.id}"
}
