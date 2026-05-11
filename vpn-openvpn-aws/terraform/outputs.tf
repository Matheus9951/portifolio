output "vpn_server_ip" {
  description = "IP público do servidor VPN"
  value       = aws_eip.vpn.public_ip
}

output "vpn_server_id" {
  description = "ID da instância EC2 do servidor VPN"
  value       = aws_instance.vpn.id
}

output "ssm_connect_command" {
  description = "Comando para conectar via SSM (sem SSH)"
  value       = "aws ssm start-session --target ${aws_instance.vpn.id} --region ${var.aws_region}"
}
