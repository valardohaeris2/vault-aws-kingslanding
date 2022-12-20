output "vault_load_balancer_name" {
  value       = var.load_balancing_scheme == "NONE" ? null : aws_lb.vault_lb[0].dns_name
  description = "The DNS name of the load balancer."
}
