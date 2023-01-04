#------------------------------------------------------------------------------
# Security Group rules
#------------------------------------------------------------------------------
resource "aws_security_group" "vault_security_group" {
  count       = var.security_group_ids == null ? 1 : 0
  name        = format("%s-security-group", var.application_prefix)
  description = "Security group to allow inbound SSH and Vault API connections"
  vpc_id      = var.network
  tags        = var.tags
}

resource "aws_security_group_rule" "allow_vault_api_communication" {
  count       = var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_api_port
  to_port     = var.vault_api_port
  protocol    = "tcp"
  cidr_blocks = concat([data.aws_vpc.vault_vpc.cidr_block], var.ingress_vault_cidr_blocks)
  description = "Allow API access to Vault nodes"

  security_group_id = aws_security_group.vault_security_group[0].id
}

resource "aws_security_group_rule" "allow_vault_cluster_communication" {
  count       = var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = var.vault_cluster_port
  to_port     = var.vault_cluster_port
  self        = true
  protocol    = "tcp"
  description = "Allow Vault nodes to communicate with each other in HA mode"

  security_group_id = aws_security_group.vault_security_group[0].id
}

resource "aws_security_group_rule" "allow_ssh_communication" {
  count       = var.security_group_ids == null ? 1 : 0
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.ingress_ssh_cidr_blocks
  description = "Allow SSH access to Vault nodes"

  security_group_id = aws_security_group.vault_security_group[0].id
}

resource "aws_security_group_rule" "allow_all_egress_communication" {
  count       = var.security_group_ids == null ? 1 : 0
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all egress traffic"

  security_group_id = aws_security_group.vault_security_group[0].id
}

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
resource "aws_launch_template" "vault_launch_template" {
  name                   = format("%s-launch-template", var.application_prefix)
  image_id               = var.packer_image == null ? var.ami_image : var.packer_image
  instance_type          = var.machine_type
  key_name               = var.machine_key_pair
  update_default_version = true
  tags                   = var.tags

  user_data = base64encode(templatefile("${path.module}/templates/vault_install.sh.tpl", {
    cloud                                    = "aws",
    using_packer_image                       = var.packer_image == null ? false : true,
    skip_install_tools                       = var.skip_install_tools,
    vault_install_url                        = format("https://releases.hashicorp.com/vault/%s/vault_%s_linux_amd64.zip", var.vault_version, var.vault_version),
    vault_api_port                           = var.vault_api_port,
    vault_cluster_port                       = var.vault_cluster_port,
    vault_license                            = var.vault_license_secret == null ? "" : var.vault_license_secret,
    vault_storage                            = var.vault_backend_storage,
    vault_home_directory                     = var.vault_home_directory,
    vault_data_directory                     = var.vault_data_directory,
    vault_bin_directory                      = var.vault_bin_directory,
    vault_systemd_directory                  = var.vault_systemd_directory,
    vault_enable_ui                          = var.vault_enable_ui,
    vault_disable_mlock                      = var.vault_disable_mlock,
    vault_tls_require_and_verify_client_cert = var.vault_tls_require_and_verify_client_cert,
    vault_tls_disable_client_certs           = var.vault_tls_disable_client_certs,
    vault_leader_tls_servername              = var.vault_leader_tls_servername == null ? "" : var.vault_leader_tls_servername,
    vault_api_ca_cert                        = var.vault_ca_bundle_secret,
    vault_api_cert                           = var.vault_signed_cert_secret,
    vault_api_key                            = var.vault_private_key_secret,
    vault_seal_type                          = var.vault_seal_type,
    kms_data                                 = local.kms_data
    auto_join_tag_key                        = var.auto_join_tag == null ? keys(var.tags)[0] : keys(var.auto_join_tag)[0]
    auto_join_tag_value                      = var.auto_join_tag == null ? values(var.tags)[0] : values(var.auto_join_tag)[0]
  }))

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = var.disk_configuration.volume_type
      volume_size           = var.disk_configuration.volume_size
      iops                  = var.disk_configuration.volume_iops
      throughput            = var.disk_configuration.volume_throughput
      delete_on_termination = var.disk_configuration.delete_on_termination
      encrypted             = var.disk_configuration.encrypted
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.vault_iam_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  vpc_security_group_ids = var.security_group_ids == null ? [aws_security_group.vault_security_group[0].id] : var.security_group_ids

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_placement_group" "vault_placement_group" {
  name     = format("%s-placement-group", var.application_prefix)
  strategy = "spread"
  tags     = var.tags
}

resource "aws_autoscaling_group" "vault_autoscaling_group" {
  name             = format("%s-autoscaling-group", var.application_prefix)
  min_size         = var.node_count
  max_size         = var.node_count
  desired_capacity = var.node_count

  wait_for_capacity_timeout = "10m"
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.asg_health_check_type

  vpc_zone_identifier = var.subnetworks

  default_cooldown = 30
  placement_group  = aws_placement_group.vault_placement_group.id

  target_group_arns = var.load_balancing_scheme == "NONE" ? [] : [aws_lb_target_group.vault_lb_target_group[0].arn]

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  launch_template {
    id      = aws_launch_template.vault_launch_template.id
    version = "$Latest"
  }
}