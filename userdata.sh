#!/bin/bash
# Redireciona toda a saída do script para um arquivo de log para que você possa debugar se algo der errado
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=================================================="
echo "STARTING AUTOMATED PROVISIONING (USER DATA)"
echo "=================================================="

# 1. Atualizar as dependências do sistema de forma não-interativa
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# 2. Instalar pacotes necessários para o Docker
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

# 3. Adicionar a chave GPG oficial do Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Configurar o repositório oficial do Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualizar o índice de pacotes com o novo repositório adicionado
apt-get update -y

# 5. Instalar o Docker Engine e o Docker Compose plugin
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Garantir que o daemon do Docker inicialize automaticamente com o sistema
systemctl start docker
systemctl enable docker

# 7. Criar uma pasta para o projeto e baixar/criar o docker-compose.yml
mkdir -p /app
cd /app

cat <<EOF > docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    container_name: web-container
    ports:
      - "80:80"
    restart: always
    volumes:
      - ./html:/usr/share/nginx/html

  api:
    image: node:18-alpine
    container_name: node-api
    command: sh -c "echo 'API Online' > index.html && npx serve -p 3000"
    ports:
      - "3000:3000"
    restart: always
EOF

# Cria a pasta de volumes que o docker-compose espera e uma página index.html simples para o Nginx rodar
mkdir -p html
echo "<h1>Docker Host Rodando via Terraform!</h1><p>Seus containers subiram automaticamente.</p>" > html/index.html

# 8. Dar o comando para subir os containers em background
docker compose up -d

echo "=================================================="
echo "PROVISIONING COMPLETE!"
echo "=================================================="