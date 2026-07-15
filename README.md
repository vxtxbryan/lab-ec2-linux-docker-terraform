# Automated Docker Host Provisioning on AWS with Terraform & Bash

[![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-%232496ED.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat&logo=ubuntu&logoColor=white)](https://ubuntu.com/)

Este repositório contém a automação completa de infraestrutura (Infraestrutura como Código - IaC) para provisionamento de um **Docker Host** resiliente e seguro na nuvem da AWS utilizando **Terraform**. O sistema operacional é configurado de forma 100% autônoma no primeiro boot (`bootstrap`) por meio de um script Bash injetado no processo de inicialização (`User Data`).

O objetivo deste projeto é demonstrar a sinergia entre o provisionamento moderno de infraestrutura e a automação de configuração de ambientes de desenvolvimento/produção, mitigando erros manuais e reduzindo o tempo de deploy (*Time-to-Market*).

---

## 🗺️ Arquitetura de Rede e Recursos

O Terraform provisiona uma infraestrutura virtual seguindo o princípio de privilégio mínimo e boas práticas de arquitetura de nuvem:

* **VPC Dedicada:** Rede virtual isolada com bloco CIDR `10.0.0.0/16`.
* **Subnet Pública:** Bloco `10.0.1.0/24` configurado para associar dinamicamente IPs públicos aos recursos criados.
* **Internet Gateway (IGW):** Componente lógico que permite a comunicação bidirecional entre os recursos da VPC e a internet.
* **Tabela de Rotas (Route Table):** Roteamento explícito direcionando todo o tráfego de saída (`0.0.0.0/0`) para o Internet Gateway.
* **Security Group (Firewall Virtual):** Regras restritas para controle de fluxo:
  * **Ingress (Entrada):** Liberação das portas `TCP/22` (SSH), `TCP/80` (HTTP), `TCP/443` (HTTPS) e `TCP/3000` (API Node, exposta para fins de demonstração).
  * **Egress (Saída):** Liberação de todo o tráfego de saída, permitindo que o SO baixe e atualize pacotes necessários.
* **Instância EC2:** Servidor virtual executando o **Ubuntu Server 22.04 LTS**, cuja AMI é obtida dinamicamente via `data source` oficial da Canonical.

```
Internet
   │
   ▼
Internet Gateway (igw)
   │
   ▼
Route Table (0.0.0.0/0 → igw)
   │
   ▼
VPC 10.0.0.0/16
   │
   ▼
Subnet Pública 10.0.1.0/24
   │
   ▼
EC2 (Ubuntu 22.04) ── Security Group (22 / 80 / 443 / 3000)
   │
   ▼
Docker Engine
   ├── web (nginx:alpine)   → porta 80
   └── api (node:18-alpine) → porta 3000
```

---

## 🛠️ Tecnologias Utilizadas

* **IaC:** Terraform (HCL), provider `hashicorp/aws ~> 5.0`
* **Cloud Provider:** AWS (Amazon Web Services)
* **Sistema Operacional:** Ubuntu Server 22.04 LTS
* **Containerização:** Docker Engine & Docker Compose
* **Automação:** Shell Script (Bash)

---

## ✅ Pré-requisitos

Antes de começar, você precisa ter:

1. **Conta AWS** ativa com permissões para criar VPC, EC2, Security Group e recursos de rede.
2. **[Terraform](https://developer.hashicorp.com/terraform/install)** instalado (versão compatível com `~> 5.0` do provider AWS).
3. **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)** instalada e configurada com suas credenciais:
   ```bash
   aws configure
   ```
4. **Key Pair** criado na região da AWS que você for usar, para acesso SSH à instância:
   ```bash
   aws ec2 create-key-pair --key-name key-ec2 --query 'KeyMaterial' --output text > key-ec2.pem
   chmod 400 key-ec2.pem
   ```
   > Se você usa Windows/PuTTY, converta o `.pem` para `.ppk` com o PuTTYgen. O nome da key precisa bater com a variável `key_name` (padrão: `key-ec2`).

---

## 📂 Estrutura de Arquivos do Projeto

```text
├── main.tf         # Arquivo principal do Terraform (Provider, Rede, SG, EC2 e Data Sources)
├── variables.tf    # Declaração das variáveis do projeto (Região, Chaves, Tipo de instância)
├── outputs.tf       # Definição das saídas exibidas no terminal (IP público e URL de acesso)
├── userdata.sh      # Script Bash responsável por atualizar o SO, instalar Docker/Compose e subir os containers
├── .gitignore       # Filtro de arquivos locais que não devem ser rastreados pelo Git
└── README.md        # Documentação técnica e guia de execução
```

---

## 🚀 Como Usar

### 1. Clone o repositório

```bash
git clone https://github.com/<seu-usuario>/<seu-repositorio>.git
cd <seu-repositorio>
```

### 2. Inicialize o Terraform

```bash
terraform init
```

### 3. Revise o plano de execução

```bash
terraform plan
```

### 4. Aplique a infraestrutura

```bash
terraform apply
```

Confirme digitando `yes` quando solicitado. O provisionamento completo (rede + EC2 + Docker + containers) leva poucos minutos.

### 5. Acesse a aplicação

Ao final do `apply`, o Terraform exibirá os outputs configurados:

```
Outputs:

instance_public_ip = "x.x.x.x"
website_url = "http://x.x.x.x"
```

Abra a `website_url` no navegador para ver a página servida pelo Nginx, ou acesse `http://x.x.x.x:3000` para a API Node.

### 6. Acesse a instância via SSH (opcional)

```bash
ssh -i key-ec2.pem ubuntu@<instance_public_ip>
```

Para debugar o processo de bootstrap, o log completo do `userdata.sh` fica disponível dentro da instância em:

```bash
sudo cat /var/log/user-data.log
```

### 7. Destrua a infraestrutura

Para evitar custos desnecessários na AWS, destrua os recursos quando não precisar mais deles:

```bash
terraform destroy
```

---

## 📸 Demonstração

### Plano de execução (`terraform plan`)
![Terraform plan](images/01-terraform-plan.png)

### Provisionamento em andamento
![Terraform apply](images/02-terraform-apply-creating.png)

### Provisionamento concluído
![Apply complete](images/03-terraform-apply-complete.png)

### API Node respondendo (porta 3000)
![API Online](images/04-api-porta-3000.png)

### Website Nginx respondendo (porta 80)
![Website rodando](images/05-website-nginx.png)

### Docker PS mostrando containers 
![Docker PS](images\06-docker-ps.jpg)

---

## ⚙️ Variáveis (`variables.tf`)

| Nome            | Descrição                                                            | Tipo   | Padrão         |
|-----------------|------------------------------------------------------------------    |--------|----------------|
| `aws_region`    | Região da AWS onde os recursos serão criados                         | string | `us-east-1`    |
| `instance_type` | Tipo da instância EC2                                                | string | `t3.micro`     |
| `ami_id`        | ID da AMI do Ubuntu. Se `null`, busca a mais recente automaticamente | string | `null`         |
| `key_name`      | Nome da Key Pair cadastrada na AWS para acesso SSH                   | string | `key-ec2`      |

Para sobrescrever qualquer variável, use um arquivo `terraform.tfvars` ou a flag `-var`:

```bash
terraform apply -var="instance_type=t3.small" -var="aws_region=sa-east-1"
```

---

## 📤 Outputs (`outputs.tf`)

| Nome                 | Descrição                                |
|----------------------|--------------------------------------------|
| `instance_public_ip` | IP público da instância EC2 criada         |
| `website_url`        | URL completa para acessar o servidor web   |

---

## 🐳 O que o `userdata.sh` faz

No primeiro boot da instância, o script automatiza:

1. Atualização não-interativa dos pacotes do sistema (`apt-get update/upgrade`).
2. Instalação de dependências (`curl`, `gnupg`, `git`, etc.).
3. Adição do repositório oficial do Docker e instalação do Docker Engine + Docker Compose plugin.
4. Ativação do serviço Docker no boot (`systemctl enable docker`).
5. Criação de um `docker-compose.yml` com dois serviços:
   * **web** — `nginx:alpine` servindo uma página estática na porta `80`.
   * **api** — `node:18-alpine` servindo uma resposta simples na porta `3000`.
6. Subida dos containers em background (`docker compose up -d`).

Todo o processo é logado em `/var/log/user-data.log` para facilitar troubleshooting.

---

## 🔒 Segurança e Boas Práticas

* **Nunca versione arquivos sensíveis.** Adicione ao `.gitignore`:
  ```gitignore
  *.pem
  *.ppk
  *.tfstate
  *.tfstate.backup
  .terraform/
  terraform.tfvars
  ```
* O `terraform.tfstate` guarda o estado real da infraestrutura (incluindo IDs e metadados de recursos) e **não deve ser commitado**. Para uso em equipe, considere um backend remoto (ex: S3 + DynamoDB para locking).
* As portas 22/80/443/3000 estão liberadas para `0.0.0.0/0` neste projeto por simplicidade didática. Em produção, restrinja a porta 22 ao seu IP, evite expor a API diretamente (use um proxy reverso ou API Gateway) e use um bastion host / SSM Session Manager para acesso administrativo.
* Rotacione a Key Pair (`key-ec2`) caso ela já tenha sido exposta publicamente.

---

## 📄 Licença

Este projeto está disponível sob a licença MIT. Sinta-se livre para usar, modificar e distribuir.
