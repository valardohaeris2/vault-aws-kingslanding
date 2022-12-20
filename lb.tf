#------------------------------------------------------------------------------
# Backend
#------------------------------------------------------------------------------
resource "aws_lb_target_group" "vault_lb_target_group" {
  count                = var.load_balancing_scheme == "NONE" ? 0 : 1
  name                 = format("%s-target-group", var.application_prefix)
  target_type          = "instance"
  port                 = var.vault_api_port
  protocol             = "TCP"
  vpc_id               = var.network
  deregistration_delay = 15
  tags                 = var.tags

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
    interval = var.health_check_interval

    path = format("/v1/sys/health?standbyok=%s&perfstandbyok=%s&activecode=%s&standbycode=%s&drsecondarycode=%s&performancestandbycode=%s&sealedcode=%s&uninitcode=%s",
      var.vault_health_endpoints["standbyok"],
      var.vault_health_endpoints["perfstandbyok"],
      var.vault_health_endpoints["activecode"],
      var.vault_health_endpoints["standbycode"],
      var.vault_health_endpoints["drsecondarycode"],
      var.vault_health_endpoints["performancestandbycode"],
      var.vault_health_endpoints["sealedcode"],
    var.vault_health_endpoints["uninitcode"])
  }
}

resource "aws_lb_listener" "vault_lb_listener" {
  count             = var.load_balancing_scheme == "NONE" ? 0 : 1
  load_balancer_arn = aws_lb.vault_lb[0].id
  port              = var.vault_api_port
  protocol          = "TCP"
  tags              = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_lb_target_group[0].arn
  }
}

#------------------------------------------------------------------------------
# Frontend
#------------------------------------------------------------------------------
resource "aws_lb" "vault_lb" {
  count              = var.load_balancing_scheme == "NONE" ? 0 : 1
  name               = format("%s-load-balancer", var.application_prefix)
  internal           = var.load_balancing_scheme == "INTERNAL" ? true : false
  load_balancer_type = "network"
  subnets            = var.lb_subnetwork == null ? var.subnetworks : var.lb_subnetwork
  tags               = var.tags
}
