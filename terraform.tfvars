#=======Required Variables 
network                     = "vpc-00486c3ef62ee9f8d"                                                                             #(required) The VPC ID to host the cluster in
region                      = "us-east-2"                                                                                         #(required) The AWS region to use
subnetworks                 = ["subnet-00d93cf0ccbb3b5a6", "subnet-0ede1a4da20f1aa5a", "subnet-06ac77c8e9844e43f"]                #(required) The subnet IDs in the VPC to host the cluster in
vault_ca_bundle_secret      = "arn:aws:secretsmanager:us-east-2:641977889341:secret:kingslanding_ca_bundle-wjS44N"               #vault_ca_bundle_secret	(required) The ARN of the CA bundle secret in AWS Secrets Manager
vault_disable_mlock         = true                                                                                                #(optional) Disable the server from executing the mlock syscall
vault_leader_tls_servername = "aconner-vault.com"                                                                                 #(optional) TLS servername to use when trying to connect to the Raft cluster with HTTPS
vault_private_key_secret    = "arn:aws:secretsmanager:us-east-2:641977889341:secret:kingslanding_certificate_private_key-5segfb" #(required) The ARN of the signed certificate's private key secret in AWS Secrets Manager
vault_signed_cert_secret    = "arn:aws:secretsmanager:us-east-2:641977889341:secret:kingslanding_signed_certificate-FQgpzx"      #(required) The ARN of the signed certificate secret in AWS Secrets Manager
packer_image                = "ami-041b32f089f3abdff"                                                                             #(optional) The packer image to use


#=========Optional Variables 


# Health Checks
asg_health_check_grace_period = 600 #(optional) The amount of time to expire before the autoscaling group terminates an unhealthy node is terminated. 
asg_health_check_type         = "EC2" #(optional) Defines how autoscaling health checking is done. 'EC2' or 'ELB'
health_check_interval         = 30  #(optional) How often, in seconds, to send a health check.  '10' or '30' seconds

# AWS Resource Tags
auto_join_tag = { #(optional) A map containing a single tag which will be used by Vault to join other nodes to the cluster. If left blank, the module will use the first entry in tags
  Name = "kingslanding"
}

tags = { #(optional) A map containing tags to assign to all resources
  Name = "kingslanding"
}

# Keys, Certificates, Key Pairs
aws_kms_key_id   = "20eb274b-2c05-4a70-8965-dd00c3288ee6" #(optional) The KMS key ID to use for Vault auto-unseal
aws_kms_region   = "us-east-2"                            #(optional) The region the KMS is in. Leave null if in the same region as everything else
machine_key_pair = "us-east-2"                        #(optional) The machine SSH key pair name to use for the cluster nodes

# Persistent Storage 


# IAM
iam_role_path                     = "/" #(optional) Path for IAM entities
iam_role_permissions_boundary_arn = ""                       #(optional) The ARN of the policy that is used to set the permissions boundary for the role

# ACL
security_group_ids = ["sg-0eb54f1713edf8878"] #(optional) List of security group IDs to be used by the auto scaling group

# Networking
ingress_ssh_cidr_blocks   = ["192.168.0/16", "0.0.0.0/0"]                                                         #(optional) List of CIDR blocks to allow SSH access to Vault instances. Not used if security_group_ids is set
ingress_vault_cidr_blocks = ["192.168.0/16", "0.0.0.0/0"]                                                         #(optional) List of CIDR blocks to allow API access to Vault. Not used if security_group_ids is set
lb_subnetwork             = ["subnet-00d93cf0ccbb3b5a6", "subnet-0ede1a4da20f1aa5a", "subnet-06ac77c8e9844e43f"] #(optional) The subnet IDs in the Virtual network to host the load balancer in. Can be left blank if subnet IDs are the same as subnetworks
load_balancing_scheme     = "EXTERNAL"                                                                           #(optional) Type of load balancer to use (INTERNAL, EXTERNAL, or NONE)

# OS Configuration
ami_image          = "ami-041b32f089f3abdff" #(optional) The AMI of the image to use
application_prefix = "kingslanding"            #(optional) The prefix to give to cloud entities (load-balancer name)
skip_install_tools = false                   #(optional) Skips installing required packages (unzip, jq, wget)
machine_type       = "t2.small"              #(optional) The machine type to use for the Vault nodes
node_count         = 5                       #(optional) The number of nodes to create in the pool

disk_configuration = { #(optional) The disk (EBS) configuration to use for the Vault nodes
  delete_on_termination = true
  encrypted             = true
  volume_iops           = 3000
  volume_size           = 100
  volume_throughput     = 125
  volume_type           = "gp3"
}

# Vault Configuration
vault_api_port        = 8200       #(optional) The port the Vault API will listen on
vault_backend_storage = "integrated" #(optional) The backend storage type to use. 'integrated' or 'consul'
vault_bin_directory   = "/usr/bin"      #(optional) The bin directory for the Vault binary
vault_cluster_port    = 8201       #(optional) The port the Vault cluster port will listen on
vault_data_directory  = "/opt/vault"      #(optional) The data directory for the Vault raft data
vault_enable_ui       = true        #(optional) Enable the Vault UI
vault_health_endpoints = {    #(optional) The status codes to return when querying Vault's sys/health endpoint
    standbyok              = "true"
    perfstandbyok          = "true"
    activecode             = "200"
    standbycode            = "429"
    drsecondarycode        = "472"
    performancestandbycode = "473"
    sealedcode             = "503"
    uninitcode             = "501"
  }
    
vault_home_directory                     = "/etc/vault.d"                                                                                                 #(optional) The home directory for the Vault user
vault_license_secret                     = "arn:aws:secretsmanager:us-east-2:641977889341:secret:vault_enterprise.hclic-wV9W6y" #(optional) The ARN of the license secret in AWS Secrets Manager
vault_seal_type                          = "awskms"                                                                                                #(optional) The seal type to use for Vault
vault_systemd_directory                  = "/lib/systemd/system"                                                                                                 #(optional) The directory for the systemd unit
vault_tls_disable_client_certs           = true                                                                                                   #(optional) Disable client authentication for the Vault listener
vault_tls_require_and_verify_client_cert = false                                                                                                   #(optional) Require a client to present a client certificate that validates against system CAs
vault_version                            = "1.12.0+ent"                                                                                                 #(optional) The version of Vault to use
