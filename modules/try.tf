resource "aws_s3_bucket" "bucket1" {
  bucket = "s3samplblablabla"
  acl    = "private"

  versioning {
    enabled = true
  }
}

####
