module "accelerator_aws_vault" {
  source = "../../"

  application_prefix          = "kingslanding"
  node_count                  = 5
  vault_seal_type             = "awskms"
  region                      = "us-east-2"
  network                     = "vpc-000000000"
  subnetworks                 = ["subnet-000000000", "subnet-000000000", "subnet-000000000"]
  packer_image                = "ami-000000000" # Vault 1.16.2
  vault_license_secret        = "arn:aws:secretsmanager:us-east-2:000000000:secret:vault_enterprise.hclic-000000000"
  vault_ca_bundle_secret      = "arn:aws:secretsmanager:us-east-2:000000000:secret:kingslanding_ca_bundle-000000000"
  vault_signed_cert_secret    = "arn:aws:secretsmanager:us-east-2:000000000:secret:kingslanding_signed_certificate-000000000"
  vault_private_key_secret    = "arn:aws:secretsmanager:us-east-2:000000000:secret:kingslanding_certificate_private_key-000000000"
  machine_key_pair            = "us-east-2"
  aws_kms_key_id              = "000000000"
  vault_leader_tls_servername = "aconner-vault.com"
  ingress_ssh_cidr_blocks     = ["0.0.0.0/0"]
}

#output "loadbalancer_ip" {
#  value       = module.accelerator_aws_vault.vault_load_balancer_name
#  description = "The load balancer DNS name."
#}
