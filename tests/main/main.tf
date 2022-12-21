module "accelerator_aws_vault" {
  source = "../../"

  application_prefix          = "kingslanding"
  node_count                  = 5
  vault_seal_type             = "awskms"
  region                      = "us-east-2"
  network                     = "vpc-0eb6247a83d99d7bf"
  subnetworks                 = ["subnet-09ff625d70066e485", "subnet-07ba23ae1a92b8b2f", "subnet-081b33fdfc2e54943"]
  packer_image                = "ami-09b0a8f4ede395236" # Vault 1.12.0
  vault_license_secret        = "arn:aws:secretsmanager:us-east-2:641977889341:secret:vault_enterprise.hclic-wV9W6y"
  vault_ca_bundle_secret      = "arn:aws:secretsmanager:us-east-2:641977889341:secret:kingslanding_ca_bundle-wjS44N"
  vault_signed_cert_secret    = "arn:aws:secretsmanager:us-east-2:641977889341:secret:kingslanding_signed_certificate-FQgpzx"
  vault_private_key_secret    = "arn:aws:secretsmanager:us-east-2:641977889341:secret:kingslanding_certificate_private_key-5segfb"
  machine_key_pair            = "kingslanding-key"
  aws_kms_key_id              = "abccc794-f0c6-4968-bf1e-43ea9cec3a47"
  vault_leader_tls_servername = "aconner-vault.com"
  ingress_ssh_cidr_blocks     = ["0.0.0.0/0"]
}

output "loadbalancer_ip" {
  value       = module.accelerator_aws_vault.vault_load_balancer_name
  description = "The load balancer DNS name."
}
