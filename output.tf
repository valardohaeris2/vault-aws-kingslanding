output "vault_load_balancer_name" {
  value       = var.load_balancing_scheme == "NONE" ? null : aws_lb.vault_lb[0].dns_name
  description = "The DNS name of the load balancer."
}

#output "connection_details" {  
 # value = <<-EOF
  #To connect using AWS Session Manager:
  #%{ for instance in aws_instance.kings-landing }
  #aws ssm start-session --target ${instance.id}
  #%{ endfor }
  #To connect using SSH:
  #%{ for instance in aws_instance.kings-landing }
  #ssh -i .instance_id_rsa centos@${instance.public_ip}
  #%{ endfor }
  #EOF
#}