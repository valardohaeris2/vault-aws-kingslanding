data "aws_vpc" "vault_vpc" {
  id = var.network
}

data "aws_kms_key" "vault_unseal" {
  key_id = var.aws_kms_key_id
}
 
