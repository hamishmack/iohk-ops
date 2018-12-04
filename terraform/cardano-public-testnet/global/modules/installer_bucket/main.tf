#
# installer_bucket
#
# Public S3 bucket where deployers group have write access.
#
# TODO: access logging to count downloads
#

resource "aws_s3_bucket" "bucket" {
  bucket   = "${var.bucket_name}"
  region   = "${var.aws_region}"
  acl      = "public-read"

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

module "s3-full-access" {
  source       = "../../../../modules/s3-full-access-policy"
  name         = "${var.prefix}-ci-deploy-s3-access"
  bucket_names = ["${aws_s3_bucket.bucket.id}"]
}

resource "aws_iam_group_policy_attachment" "s3-full-access-attachment" {
  group      = "${var.group}"
  policy_arn = "${module.s3-full-access.arn}"
}

resource "aws_iam_group_policy_attachment" "s3-grant-public-read" {
  group      = "${var.group}"
  policy_arn = "${element(aws_iam_policy.s3-grant-public-read.*.arn, 0)}"
}

resource "aws_iam_policy" "s3-grant-public-read" {
  name   = "${var.prefix}ci-deploy-s3-grant-public-read"
  policy = "${data.aws_iam_policy_document.s3-grant-public-read.json}"
}

data "aws_iam_policy_document" "s3-grant-public-read" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObjectAcl",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["public-read"]
    }

    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"]
  }
}

# HTML index of bucket
resource "aws_s3_bucket_object" "object" {
  bucket  = "${aws_s3_bucket.bucket.id}"
  key     = "index.html"
  content = "${data.template_file.bucket_index.rendered}"
  etag    = "${md5(data.template_file.bucket_index.rendered)}"
  acl     = "public-read"
  content_type = "text/html"
}

data "template_file" "bucket_index" {
  template = "${file("${path.module}/bucket-index.html")}"
  vars = {
    bucket_name = "${var.bucket_name}"
  }
}

