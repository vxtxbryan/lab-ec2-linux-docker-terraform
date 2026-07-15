# ==========================================
# PROVIDER & CONFIGURAÇÕES INICIAIS
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==========================================
# DATA SOURCE (Consulta dinamicamente a AMI do Ubuntu)
# ==========================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID oficial da Canonical (criadora do Ubuntu) na AWS

  filter {
    name   = "name"
    # Filtra por Ubuntu 22.04 LTS de arquitetura x86 (64 bits) do tipo Server
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================
# RECURSOS DE REDE (VPC, Subnet, IGW, Route Table)
# ==========================================

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "private-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Atribui IP público automaticamente para instâncias nela

  tags = {
    Name = "-subnet-public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route-table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# FIREWALL (Security Group)
# ==========================================

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Liberar portas HTTP, HTTPS e SSH"
  vpc_id      = aws_vpc.main_vpc.id

  # Entrada (Ingress)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "API Node"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída (Egress) - Crucial para que o User Data consiga baixar o Nginx
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# ==========================================
# COMPUTAÇÃO (A Instância EC2)
# ==========================================

resource "aws_instance" "web_server" {
  # Se 'ami_id' for null, usa o ID retornado pelo Data Source acima
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Coloca a instância na nossa subnet e no nosso Security Group
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Chave para acesso SSH via Putty
  key_name               = var.key_name

  # Mapeia o arquivo User Data externo de inicialização
  user_data = file("${path.module}/userdata.sh")

  # Se o arquivo userdata.sh for alterado, a instancia EC2 é recriada do zero
  user_data_replace_on_change = true

  tags = {
    Name = "Servidor-Web-Terraform"
  }
}