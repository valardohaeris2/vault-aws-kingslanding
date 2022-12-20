#------------------------------------------------------------------------------
# AWS IAM
#------------------------------------------------------------------------------
resource "aws_iam_role" "vault_iam_role" {
  name                 = format("%s-iam-role", var.application_prefix)
  path                 = var.iam_role_path
  assume_role_policy   = file("${path.module}/templates/vault-server-role.json.tpl")
  permissions_boundary = var.iam_role_permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_instance_profile" "vault_iam_instance_profile" {
  name_prefix = format("%s-iam-instance-profile", var.application_prefix)
  role        = aws_iam_role.vault_iam_role.name
  path        = var.iam_role_path
  tags        = var.tags
}

resource "aws_iam_role_policy" "main" {
  name = format("%s-iam-role-policy", var.application_prefix)
  role = aws_iam_role.vault_iam_role.id

  policy = templatefile("${path.module}/templates/vault-server-role-policy.json.tpl", {
    vault_license_secret     = var.vault_license_secret == null ? "" : var.vault_license_secret,
    vault_ca_bundle_secret   = var.vault_ca_bundle_secret == null ? "" : var.vault_ca_bundle_secret,
    vault_signed_cert_secret = var.vault_signed_cert_secret == null ? "" : var.vault_signed_cert_secret,
    vault_private_key_secret = var.vault_private_key_secret == null ? "" : var.vault_private_key_secret,
    vault_seal_type          = var.vault_seal_type,
    vault_kms_key_arn        = data.aws_kms_key.vault_unseal
  })
}
