[![Terraform Module Test](https://github.com/hashicorp-services/accelerator-aws-vault/actions/workflows/terraform.yml/badge.svg)](https://github.com/hashicorp-services/accelerator-aws-vault/actions/workflows/terraform.yml)

# HashiCorp Implementation Services Accelerator - Vault Enterprise on Amazon Web Services
This Terraform module deploys Vault Enterprise with integrated storage to Amazon Web Services.

## Prerequisites
This module requires the following to already be in place in AWS:
- A [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-subnet-basics) with the following:
  - A or multiple [Subnet(s)](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#subnet-basics)
  - Internet Gateway
  - Routing tables
- A dedicated [KMS Key](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) leveraging the "AWS role-based access control" permission model (if using auto-unseal)
- Access to [Secrets Manager](https://aws.amazon.com/secrets-manager/)

## Authentication to AWS
It is recommended to authenticate to AWS via AWS Access Key ID and Secret Access Key when running Terraform non-interactively or locally.

### With Access Key ID and Secret Access Key
Ensure the `aws` binary is installed locally and executable. Authenticate to AWS by running the following command:

```bash
$ aws configure
```

## Deployment
Upon first deployment, Vault servers will auto-join and form a fresh cluster. The cluster will be in an uninitialized, sealed state. An operator must then connect to the cluster to initialize Vault. If using Shamir seal, the operator must manually unseal each node. If auto-unseal is used via AWS KMS, the Vault nodes will automatically unseal upon initialization.

## Examples
Example deployment scenarios can be found in the `tests` directory of this repo [here](tests/). These examples cover multiple capabilities of the module and are meant to serve as a starting point for operators.

## Deployment Options
This module can deploy a Vault cluster by leveraging a Packer image for initial configuration or without one.

### With Packer
The recommended approach is to use a Packer image as the image of the compute instances that make up the Vault cluster. A Packer image should be built with the dedicated repository [here](https://github.com/hashicorp-services/accelerator-vault-packer-images). More information about this repository can be found in it's README.

The Packer image build will take care of setting up general aspects such as creating a dedicated user account and installing the Vault binary. From there, the bash script in this repository will be loaded as a startup script and will tailor the remaining Vault configurations to the desired state defined in this module.

To deploy with this method, ensure the following variable is passed:

- `packer_image`

If this method is used, the following variables will not have any effect as most of this information is set in the Packer image build:

- `ami_image`
- `vault_version`

Also ensure that the following variables match what was defined during the Packer image build:

- `vault_bin_directory`
- `vault_data_directory`
- `vault_home_directory`

The default values for these variables will work.

### Without Packer
If a Packer image is not used, the module can also deploy a Vault cluster in full by just passing in a generic cloud image or a custom image provided by the consumer. To deploy with this method, ensure the following variables are passed:

- `ami_image`

## Terraform Configuration

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_image"></a> [ami\_image](#input\_ami\_image) | (optional) The AMI of the image to use | `string` | `null` | no |
| <a name="input_application_prefix"></a> [application\_prefix](#input\_application\_prefix) | (optional) The prefix to give to cloud entities | `string` | `"vault"` | no |
| <a name="input_asg_health_check_grace_period"></a> [asg\_health\_check\_grace\_period](#input\_asg\_health\_check\_grace\_period) | (optional) The amount of time to expire before the autoscaling group terminates an unhealthy node is terminated | `string` | `600` | no |
| <a name="input_asg_health_check_type"></a> [asg\_health\_check\_type](#input\_asg\_health\_check\_type) | (optional) Defines how autoscaling health checking is done | `string` | `"EC2"` | no |
| <a name="input_auto_join_tag"></a> [auto\_join\_tag](#input\_auto\_join\_tag) | (optional) A map containing a single tag which will be used by Vault to join other nodes to the cluster. If left blank, the module will use the first entry in `tags` | `map(string)` | `null` | no |
| <a name="input_aws_kms_key_id"></a> [aws\_kms\_key\_id](#input\_aws\_kms\_key\_id) | (optional) The KMS key ID to use for Vault auto-unseal | `string` | `null` | no |
| <a name="input_aws_kms_region"></a> [aws\_kms\_region](#input\_aws\_kms\_region) | (optional) The region the KMS is in. Leave null if in the same region as everything else | `string` | `null` | no |
| <a name="input_disk_configuration"></a> [disk\_configuration](#input\_disk\_configuration) | (optional) The disk (EBS) configuration to use for the Vault nodes | <pre>object(<br>    {<br>      volume_type           = string<br>      volume_size           = number<br>      volume_iops           = number<br>      volume_throughput     = number<br>      delete_on_termination = bool<br>      encrypted             = bool<br>    }<br>  )</pre> | <pre>{<br>  "delete_on_termination": true,<br>  "encrypted": true,<br>  "volume_iops": 3000,<br>  "volume_size": 100,<br>  "volume_throughput": 125,<br>  "volume_type": "gp3"<br>}</pre> | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | (optional) How often, in seconds, to send a health check | `number` | `30` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | (optional) Path for IAM entities | `string` | `"/"` | no |
| <a name="input_iam_role_permissions_boundary_arn"></a> [iam\_role\_permissions\_boundary\_arn](#input\_iam\_role\_permissions\_boundary\_arn) | (optional) The ARN of the policy that is used to set the permissions boundary for the role | `string` | `null` | no |
| <a name="input_ingress_ssh_cidr_blocks"></a> [ingress\_ssh\_cidr\_blocks](#input\_ingress\_ssh\_cidr\_blocks) | (optional) List of CIDR blocks to allow SSH access to Vault instances. Not used if `security_group_ids` is set | `list(string)` | `[]` | no |
| <a name="input_ingress_vault_cidr_blocks"></a> [ingress\_vault\_cidr\_blocks](#input\_ingress\_vault\_cidr\_blocks) | (optional) List of CIDR blocks to allow API access to Vault. Not used if `security_group_ids` is set | `list(string)` | `[]` | no |
| <a name="input_lb_subnetwork"></a> [lb\_subnetwork](#input\_lb\_subnetwork) | (optional) The subnet IDs in the Virtual network to host the load balancer in. Can be left blank if subnet IDs are the same as `subnetworks` | `list(string)` | `null` | no |
| <a name="input_load_balancing_scheme"></a> [load\_balancing\_scheme](#input\_load\_balancing\_scheme) | (optional) Type of load balancer to use (INTERNAL, EXTERNAL, or NONE) | `string` | `"INTERNAL"` | no |
| <a name="input_machine_key_pair"></a> [machine\_key\_pair](#input\_machine\_key\_pair) | (optional) The machine SSH key pair name to use for the cluster nodes | `string` | `null` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | (optional) The machine type to use for the Vault nodes | `string` | `"m5.large"` | no |
| <a name="input_network"></a> [network](#input\_network) | (required) The VPC ID to host the cluster in | `string` | n/a | yes |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | (optional) The number of nodes to create in the pool | `number` | `5` | no |
| <a name="input_packer_image"></a> [packer\_image](#input\_packer\_image) | (optional) The packer image to use | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | (required) The AWS region to use | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | (optional) List of security group IDs to be used by the auto scaling group | `list(string)` | `null` | no |
| <a name="input_skip_install_tools"></a> [skip\_install\_tools](#input\_skip\_install\_tools) | (optional) Skips installing required packages (unzip, jq, wget) | `bool` | `false` | no |
| <a name="input_subnetworks"></a> [subnetworks](#input\_subnetworks) | (required) The subnet IDs in the VPC to host the cluster in | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (optional) A map containing tags to assign to all resources | `map(string)` | <pre>{<br>  "app": "vault"<br>}</pre> | no |
| <a name="input_vault_api_port"></a> [vault\_api\_port](#input\_vault\_api\_port) | (optional) The port the Vault API will listen on | `string` | `"8200"` | no |
| <a name="input_vault_backend_storage"></a> [vault\_backend\_storage](#input\_vault\_backend\_storage) | (optional) The backend storage type to use | `string` | `"integrated"` | no |
| <a name="input_vault_bin_directory"></a> [vault\_bin\_directory](#input\_vault\_bin\_directory) | (optional) The bin directory for the Vault binary | `string` | `"/usr/bin"` | no |
| <a name="input_vault_ca_bundle_secret"></a> [vault\_ca\_bundle\_secret](#input\_vault\_ca\_bundle\_secret) | (required) The ARN of the CA bundle secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_vault_cluster_port"></a> [vault\_cluster\_port](#input\_vault\_cluster\_port) | (optional) The port the Vault cluster port will listen on | `string` | `"8201"` | no |
| <a name="input_vault_data_directory"></a> [vault\_data\_directory](#input\_vault\_data\_directory) | (optional) The data directory for the Vault raft data | `string` | `"/opt/vault"` | no |
| <a name="input_vault_disable_mlock"></a> [vault\_disable\_mlock](#input\_vault\_disable\_mlock) | (optional) Disable the server from executing the `mlock` syscall | `bool` | `true` | no |
| <a name="input_vault_enable_ui"></a> [vault\_enable\_ui](#input\_vault\_enable\_ui) | (optional) Enable the Vault UI | `bool` | `true` | no |
| <a name="input_vault_health_endpoints"></a> [vault\_health\_endpoints](#input\_vault\_health\_endpoints) | (optional) The status codes to return when querying Vault's sys/health endpoint | `map(string)` | <pre>{<br>  "activecode": "200",<br>  "drsecondarycode": "472",<br>  "performancestandbycode": "473",<br>  "perfstandbyok": "true",<br>  "sealedcode": "503",<br>  "standbycode": "429",<br>  "standbyok": "true",<br>  "uninitcode": "501"<br>}</pre> | no |
| <a name="input_vault_home_directory"></a> [vault\_home\_directory](#input\_vault\_home\_directory) | (optional) The home directory for the Vault user | `string` | `"/etc/vault.d"` | no |
| <a name="input_vault_leader_tls_servername"></a> [vault\_leader\_tls\_servername](#input\_vault\_leader\_tls\_servername) | (optional) TLS servername to use when trying to connect to the Raft cluster with HTTPS | `string` | `null` | no |
| <a name="input_vault_license_secret"></a> [vault\_license\_secret](#input\_vault\_license\_secret) | (optional) The ARN of the license secret in AWS Secrets Manager | `string` | `null` | no |
| <a name="input_vault_private_key_secret"></a> [vault\_private\_key\_secret](#input\_vault\_private\_key\_secret) | (required) The ARN of the signed certificate's private key secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_vault_seal_type"></a> [vault\_seal\_type](#input\_vault\_seal\_type) | (optional) The seal type to use for Vault | `string` | `"shamir"` | no |
| <a name="input_vault_signed_cert_secret"></a> [vault\_signed\_cert\_secret](#input\_vault\_signed\_cert\_secret) | (required) The ARN of the signed certificate secret in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_vault_systemd_directory"></a> [vault\_systemd\_directory](#input\_vault\_systemd\_directory) | (optional) The directory for the systemd unit | `string` | `"/lib/systemd/system"` | no |
| <a name="input_vault_tls_disable_client_certs"></a> [vault\_tls\_disable\_client\_certs](#input\_vault\_tls\_disable\_client\_certs) | (optional) Disable client authentication for the Vault listener | `bool` | `true` | no |
| <a name="input_vault_tls_require_and_verify_client_cert"></a> [vault\_tls\_require\_and\_verify\_client\_cert](#input\_vault\_tls\_require\_and\_verify\_client\_cert) | (optional) Require a client to present a client certificate that validates against system CAs | `bool` | `false` | no |
| <a name="input_vault_version"></a> [vault\_version](#input\_vault\_version) | (optional) The version of Vault to use | `string` | `"1.10.0+ent"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vault_load_balancer_name"></a> [vault\_load\_balancer\_name](#output\_vault\_load\_balancer\_name) | The DNS name of the load balancer. |

## TLS
This module enforces the use of TLS certificates for Vault's API endpoint. Pre-provisioned TLS certificates can be provided to the module by storing them in AWS Secrets Manager as a Plaintext secret and referencing their ARN in the designated variables.

In order to use pre-provisioned TLS certificates, the following **three** variables **must** be set, pointing to their appropriate value:

- `vault_ca_bundle_secret`
- `vault_signed_cert_secret`
- `vault_private_key_secret`

### Generate TLS Certificates
If you need to generate a CA and signed certificate and private key to test the module, the following steps can be followed:

```bash
# Generate the CA private key
$ openssl genrsa -out ca-key.pem 4096

# Create a configuration file for the CA certificate
$ cat <<EOF > ca_cert_config.txt
[req]
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
prompt             = no

[req_distinguished_name]
countryName             = CA
stateOrProvinceName     = Ontario
localityName            = Toronto
organizationName        = HashiCorp
commonName              = HashiCorp

[v3_ca]
basicConstraints        = critical,CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
EOF

# Generate a CA valid for 10 years
$ openssl req -new -x509 -days 3650 \
-config ca_cert_config.txt \
-key ca-key.pem \
-out ca.pem

# Generate a private key for the client certificate
$ openssl genrsa -out cert-key.pem 4096

# Create a configuration file for the client certificate
$ cat <<EOF > server_cert_config.txt
default_bit        = 4096
distinguished_name = req_distinguished_name
prompt             = no

[req_distinguished_name]
countryName             = CA
stateOrProvinceName     = Ontario
localityName            = Toronto
organizationName        = HashiCorp
commonName              = vault.hashicorp.com
EOF

# Create an extension and SAN file for the client certificate
# Add any additional SANs necessary for the Vault nodes
$ cat <<EOF > server_ext_config.txt
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage       = serverAuth, clientAuth
subjectAltName         = @alt_names

[alt_names]
DNS.1 = vault.hashicorp.com
EOF

# Generate the Certificate Signing Request
$ openssl req -new -key cert-key.pem -out cert-csr.pem -config server_cert_config.txt

# Generate the signed certificate valid for 1 year
$ openssl x509 -req -in cert-csr.pem -out cert.pem \
-CA ca.pem -CAkey ca-key.pem -CAcreateserial \
-days 365 -sha512 -extfile server_ext_config.txt
```

Proceed with the following steps to upload them to AWS Secrets Manager:

```bash
# Upload the CA certificate
$ aws secretsmanager create-secret --name ca_bundle --secret-string file://ca.pem

# Upload the signed certificate
$ aws secretsmanager create-secret --name signed_certificate --secret-string file://cert.pem

# Upload the certificate's private key
$ aws secretsmanager create-secret --name certificate_private_key --secret-string file://cert-key.pem
```

## Load Balancing
This module supports the deployment of AWS' TCP Layer 4 [network load balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) to sit in front of the Vault cluster. The load balancer can be external (public IP) or internal (private IP) and is configured to use Vault's `sys/health` API endpoint to determine health status of Vault to ensure clients are always directed to a healthy instance when possible.

The variable `load_balancing_scheme` is used to dictate the type of load balancer that should be used and can be set as one of the following values:

- `INTERNAL` - Load balancer should receive an IP address on a private subnet
- `EXTERNAL` - Load balancer should receive a public IP
- `NONE` - No load balancer should be provisioned

## KMS
This module supports both the Shamir and auto-unseal (via AWS KMS) seal mechanism. By default, the module will assume the Shamir method should be used. In the event auto-unseal should be used, set the variable `vault_seal_type` to `awskms` and set the following two additional variables:

- `aws_kms_region` - The name of the AWS region where the KMS key resides
- `aws_kms_key_id` - The KMS key id. May also be set to the full ARN.

## Licensing
In Vault >= 1.8.0, license files are stored on the Vault servers and their location is referenced in the configuration file. This module supports reading the license file from AWS Secrets Manager. Given it's ARN via the `vault_license_secret` variable, the module will retrieve it and store it on disk of each Vault node.

> Note: If deploying an older version of Vault (< 1.8.0), the license file is uploaded after Vault is online, therefore the variable `vault_license_secret` can be left blank.

