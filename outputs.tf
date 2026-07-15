output "instance_public_ip" {
  description = "IP Público da instância EC2 criada"
  value       = aws_instance.web_server.public_ip
}

output "website_url" {
  description = "URL para acessar o servidor web"
  value       = "http://${aws_instance.web_server.public_ip}"
}