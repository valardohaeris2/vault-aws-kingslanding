# General variables
variable "region" {
  type        = string
  description = "(required) The AWS region to use"
}

variable "tags" {
  type        = map(string)
  description = "(optional) A map containing tags to assign to all resources"
  default = {
    "app" = "vault"
  }
}

variable "auto_join_tag" {
  type        = map(string)
  description = "(optional) A map containing a single tag which will be used by Vault to join other nodes to the cluster. If left blank, the module will use the first entry in `tags`"
  default     = null
}

variable "node_count" {
  type        = number
  description = "(optional) The number of nodes to create in the pool"
  default     = 5
}

variable "application_prefix" {
  type        = string
  description = "(optional) The prefix to give to cloud entities"
  default     = "vault"
}

variable "skip_install_tools" {
  type        = bool
  description = "(optional) Skips installing required packages (unzip, jq, wget)"
  default     = false
}

# TLS variables
variable "vault_ca_bundle_secret" {
  type        = string
  description = "(required) The ARN of the CA bundle secret in AWS Secrets Manager"
}

variable "vault_signed_cert_secret" {
  type        = string
  description = "(required) The ARN of the signed certificate secret in AWS Secrets Manager"
}

variable "vault_private_key_secret" {
  type        = string
  description = "(required) The ARN of the signed certificate's private key secret in AWS Secrets Manager"
}

# Networking variables
variable "network" {
  type        = string
  description = "(required) The VPC ID to host the cluster in"
}

variable "subnetworks" {
  type        = list(string)
  description = "(required) The subnet IDs in the VPC to host the cluster in"
}

variable "security_group_ids" {
  type        = list(string)
  description = "(optional) List of security group IDs to be used by the auto scaling group"
  default     = null
}

variable "ingress_ssh_cidr_blocks" {
  type        = list(string)
  description = "(optional) List of CIDR blocks to allow SSH access to Vault instances. Not used if `security_group_ids` is set"
  default     = []
}

variable "ingress_vault_cidr_blocks" {
  type        = list(string)
  description = "(optional) List of CIDR blocks to allow API access to Vault. Not used if `security_group_ids` is set"
  default     = []
}

# Virtual machine variables
variable "ami_image" {
  type        = string
  description = "(optional) The AMI of the image to use"
  default     = null
}

variable "packer_image" {
  type        = string
  description = "(optional) The packer image to use"
  default     = null
}

variable "disk_configuration" {
  description = "(optional) The disk (EBS) configuration to use for the Vault nodes"
  type = object(
    {
      volume_type           = string
      volume_size           = number
      volume_iops           = number
      volume_throughput     = number
      delete_on_termination = bool
      encrypted             = bool
    }
  )
  default = {
    volume_type           = "gp3"
    volume_size           = 100
    volume_iops           = 3000
    volume_throughput     = 125
    delete_on_termination = true
    encrypted             = true
  }
}


variable "machine_type" {
  type        = string
  description = "(optional) The machine type to use for the Vault nodes"
  default     = "t2.small.large"
}

variable "machine_key_pair" {
  type        = string
  description = "(optional) The machine SSH key pair name to use for the cluster nodes"
  default     = null
}

# IAM variables
variable "iam_role_permissions_boundary_arn" {
  type        = string
  description = "(optional) The ARN of the policy that is used to set the permissions boundary for the role"
  default     = null
}

variable "iam_role_path" {
  type        = string
  description = "(optional) Path for IAM entities"
  default     = "/"
}

# Load Balancer variables
variable "load_balancing_scheme" {
  type        = string
  description = "(optional) Type of load balancer to use (INTERNAL, EXTERNAL, or NONE)"
  default     = "INTERNAL"

  validation {
    condition     = var.load_balancing_scheme == "INTERNAL" || var.load_balancing_scheme == "EXTERNAL" || var.load_balancing_scheme == "NONE"
    error_message = "The load balancing scheme must be INTERNAL, EXTERNAL, or NONE."
  }
}

variable "lb_subnetwork" {
  type        = list(string)
  description = "(optional) The subnet IDs in the Virtual network to host the load balancer in. Can be left blank if subnet IDs are the same as `subnetworks`"
  default     = null
}

variable "health_check_interval" {
  type        = number
  description = "(optional) How often, in seconds, to send a health check"
  default     = 30
}

# Autoscaling Lifecycle Behavior
variable "asg_health_check_grace_period" {
  type        = string
  description = "(optional) The amount of time to expire before the autoscaling group terminates an unhealthy node is terminated"
  default     = 600
}

variable "asg_health_check_type" {
  type        = string
  description = "(optional) Defines how autoscaling health checking is done"
  default     = "EC2"

  validation {
    condition     = var.asg_health_check_type == "EC2" || var.asg_health_check_type == "ELB"
    error_message = "The health check type must be either EC2 or ELB."
  }
}

# Key Management Service variables
variable "vault_seal_type" {
  type        = string
  description = "(optional) The seal type to use for Vault"
  default     = "shamir"

  validation {
    condition     = var.vault_seal_type == "shamir" || var.vault_seal_type == "awskms"
    error_message = "The seal type must be shamir or awskms."
  }
}

variable "aws_kms_region" {
  type        = string
  description = "(optional) The region the KMS is in. Leave null if in the same region as everything else"
  default     = null
}

variable "aws_kms_key_id" {
  type        = string
  description = "(optional) The KMS key ID to use for Vault auto-unseal"
  default     = null
}

# Vault variables
variable "vault_version" {
  type        = string
  description = "(optional) The version of Vault to use"
  default     = "1.12.0+ent"
}

variable "vault_tls_require_and_verify_client_cert" {
  type        = bool
  description = "(optional) Require a client to present a client certificate that validates against system CAs"
  default     = false
}

variable "vault_tls_disable_client_certs" {
  type        = bool
  description = "(optional) Disable client authentication for the Vault listener"
  default     = true
}

variable "vault_leader_tls_servername" {
  type        = string
  description = "(optional) TLS servername to use when trying to connect to the Raft cluster with HTTPS"
  default     = null
}

variable "vault_backend_storage" {
  type        = string
  description = "(optional) The backend storage type to use"
  default     = "integrated"

  validation {
    condition     = var.vault_backend_storage == "integrated" || var.vault_backend_storage == "consul"
    error_message = "The backend storage type must be integrated or consul."
  }
}

variable "vault_license_secret" {
  type        = string
  description = "(optional) The ARN of the license secret in AWS Secrets Manager"
  default     = null
}

variable "vault_health_endpoints" {
  type        = map(string)
  description = "(optional) The status codes to return when querying Vault's sys/health endpoint"
  default = {
    standbyok              = "true"
    perfstandbyok          = "true"
    activecode             = "200"
    standbycode            = "429"
    drsecondarycode        = "472"
    performancestandbycode = "473"
    sealedcode             = "503"
    uninitcode             = "501"
  }
}

variable "vault_home_directory" {
  type        = string
  description = "(optional) The home directory for the Vault user"
  default     = "/etc/vault.d"
}

variable "vault_data_directory" {
  type        = string
  description = "(optional) The data directory for the Vault raft data"
  default     = "/opt/vault"
}

variable "vault_bin_directory" {
  type        = string
  description = "(optional) The bin directory for the Vault binary"
  default     = "/usr/bin"
}

variable "vault_systemd_directory" {
  type        = string
  description = "(optional) The directory for the systemd unit"
  default     = "/lib/systemd/system"
}

variable "vault_disable_mlock" {
  type        = bool
  description = "(optional) Disable the server from executing the `mlock` syscall"
  default     = true
}

variable "vault_enable_ui" {
  type        = bool
  description = "(optional) Enable the Vault UI"
  default     = true
}

variable "vault_api_port" {
  type        = string
  description = "(optional) The port the Vault API will listen on"
  default     = "8200"
}

variable "vault_cluster_port" {
  type        = string
  description = "(optional) The port the Vault cluster port will listen on"
  default     = "8201"
}
