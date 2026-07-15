variable "aws_region" {
    description = "Região da AWS onde os recursos serão criados"
    type        = string
    default     = "us-east-1"
}

variable "instance_type" {
    description = "Tipo da instância EC2"
    type        = string
    default     = "t3.micro" 
}

variable "ami_id" {
    description = "ID da AMI do Ubuntu Server. null, busca a mais recente automaticamente."
    type        = string
    default     = null
}

variable "key_name" {
  description = "Nome da chave SSH cadastrada na AWS para acesso à EC2"
  type        = string
  default     = "key-ec2" 
}