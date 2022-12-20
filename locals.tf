locals {
  kms_data = {
    region     = var.aws_kms_region == null ? var.region : var.aws_kms_region
    kms_key_id = var.aws_kms_key_id
  }
}
