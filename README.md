# 🚀 Zabbix Auto Installer

<p align="center">

![Bash](https://img.shields.io/badge/Bash-Script-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Compatible-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Debian](https://img.shields.io/badge/Debian-Supported-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-Supported-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?style=for-the-badge)
![MariaDB](https://img.shields.io/badge/MariaDB-Database-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-Compatible-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

</p>

Script desenvolvido para realizar a **instalação totalmente automatizada do Zabbix 7.0 LTS**, incluindo banco de dados, frontend web, servidor, agente e configuração inicial do ambiente.

O objetivo é disponibilizar uma instalação **segura, rápida e padronizada**, eliminando praticamente toda a configuração manual necessária.

---

# 📦 Este repositório

Este repositório contém instaladores para diferentes versões LTS do Zabbix.

| Script | Versão |
|---------|---------|
| ✅ install_zabbix6.sh | Zabbix 6 LTS |
| ✅ install_zabbix7.sh | Zabbix 7.0 LTS |

Cada script utiliza exclusivamente os repositórios oficiais da versão correspondente.

---

# ✨ Funcionalidades

- 🚀 Instalação completa do Zabbix 7.0 LTS
- 🐧 Compatível com Debian e Ubuntu
- 🔍 Detecção automática da distribuição
- 📦 Instalação automática das dependências
- 🛢️ Instalação automática do MySQL ou MariaDB
- 💾 Criação automática do banco de dados
- 👤 Criação automática do usuário do banco
- 🔑 Configuração automática do repositório oficial
- 📊 Instalação do Zabbix Server
- 🌐 Instalação do Frontend Web
- 🤖 Instalação do Zabbix Agent
- 🐘 Instalação dos módulos PHP necessários
- 🔥 Configuração automática do firewall (UFW)
- ⏰ Configuração automática do Timezone
- 🎨 Interface amigável com mensagens coloridas

---

# 🖥️ Sistemas suportados

O script detecta automaticamente o sistema operacional.

Atualmente suporta:

- Debian 12 e 13
- Ubuntu 22.04
- Ubuntu 24.04

Outras versões do Ubuntu também podem funcionar desde que possuam repositório oficial do Zabbix 7 disponível.

---

# 📦 Componentes instalados

O script instala automaticamente:

- Zabbix Server
- Zabbix Frontend
- Apache
- PHP
- PHP Modules
- Zabbix Agent
- Banco de Dados
- Repositório Oficial

---

# 🛢️ Banco de dados

O script instala automaticamente:

## Debian

- MariaDB Server

## Ubuntu

- MySQL Server

Após a instalação são criados automaticamente:

- Banco de dados
- Usuário
- Permissões
- Importação do schema oficial

---

# ⚙️ Como funciona

A instalação é dividida em sete etapas.

---

## 1️⃣ Atualização do sistema

- atualização dos repositórios
- instalação das dependências
- configuração do timezone

---

## 2️⃣ Instalação do banco

Instala automaticamente:

- MariaDB (Debian)

ou

- MySQL (Ubuntu)

---

## 3️⃣ Configuração do banco

O script:

- cria o banco;
- cria o usuário;
- redefine a senha;
- concede permissões;
- habilita temporariamente o parâmetro necessário para importação do schema.

---

## 4️⃣ Instalação do Zabbix

Nesta etapa são realizadas:

- configuração do repositório oficial;
- download do pacote release;
- atualização do APT;
- instalação do servidor;
- instalação do frontend;
- instalação do agente.

Caso o repositório oficial não exista para aquela distribuição, a instalação é interrompida para evitar inconsistências.

---

## 5️⃣ Configuração do PHP

São instalados automaticamente:

- php
- mysql
- xml
- curl
- gd
- ldap
- zip
- bcmath
- mbstring

Também é configurado automaticamente:

```text
date.timezone = America/Sao_Paulo
```

---

## 6️⃣ Importação do banco

O script importa automaticamente o schema oficial do Zabbix.

Durante esta etapa podem ser criadas milhares de tabelas.

Dependendo do hardware do servidor, esse processo pode levar entre **10 e 15 minutos**.

---

## 7️⃣ Inicialização

Ao finalizar a instalação o script:

- ajusta o arquivo `zabbix_server.conf`;
- inicia os serviços;
- habilita inicialização automática;
- configura o firewall.

---

# 🔄 Fluxo da instalação

```text
Detectar Sistema
        │
        ▼
Atualizar Sistema
        │
        ▼
Instalar Banco
        │
        ▼
Criar Banco
        │
        ▼
Adicionar Repositório
        │
        ▼
Instalar Zabbix
        │
        ▼
Instalar PHP
        │
        ▼
Importar Schema
        │
        ▼
Configurar Serviços
        │
        ▼
Configurar Firewall
        │
        ▼
Exibir Credenciais
```

---

# ▶️ Execução

Conceda permissão:

```bash
chmod +x install_zabbix7.sh
```

Execute:

```bash
sudo ./install_zabbix7.sh
```

---

# 🌐 Informações de acesso

Após a instalação:

```text
URL

http://IP_DO_SERVIDOR/zabbix
```

Credenciais padrão:

```text
Usuário

Admin
```

```text
Senha

zabbix
```

---

# 🛢️ Banco de dados

São criados automaticamente:

| Item | Valor |
|------|------|
| Banco | zabbix |
| Usuário | zabbix |
| Senha | zabbix@123 |

Após a instalação recomenda-se alterar todas as senhas padrão.

---

# 🔥 Firewall

Caso o **UFW** esteja instalado serão liberadas automaticamente as portas:

| Porta | Serviço |
|--------|----------|
| 80 | Frontend Web |
| 10050 | Zabbix Agent |

---

# 📋 Comandos úteis

Verificar status:

```bash
sudo systemctl status zabbix-server
```

Reiniciar:

```bash
sudo systemctl restart zabbix-server
```

Logs:

```bash
tail -50 /var/log/zabbix/zabbix_server.log
```

---

# 📌 Pré-requisitos

- Debian ou Ubuntu
- Conexão com a Internet
- Permissão de root
- Acesso aos repositórios oficiais do Zabbix

---

# ✅ Benefícios

- Instalação em poucos minutos
- Processo totalmente automatizado
- Compatível com versões LTS
- Configuração padronizada
- Utiliza apenas repositórios oficiais
- Criação automática do banco
- Configuração automática do PHP
- Configuração automática do firewall
- Ideal para ambientes corporativos
- Fácil manutenção

---

# 🛠️ Tecnologias utilizadas

- Bash
- Zabbix Server
- Zabbix Agent
- Apache
- PHP
- MySQL
- MariaDB
- systemd
- UFW
- APT

---

# 🔗 Projetos relacionados

Este repositório contém instaladores para diferentes versões do Zabbix:

- 🟥 **Zabbix 6 LTS Installer**
- 🟥 **Zabbix 7.0 LTS Installer**

Os scripts seguem a mesma filosofia de instalação automatizada, permitindo implantar rapidamente a versão mais adequada ao seu ambiente.

---

# 📄 Licença

Este projeto está licenciado sob a licença **MIT**.

Você pode utilizar, modificar e distribuir este projeto livremente, desde que mantenha os créditos e o texto da licença.

---

# 👨‍💻 Autor

Desenvolvido para automatizar a implantação do **Zabbix LTS** em ambientes Debian e Ubuntu, padronizando instalações, reduzindo erros de configuração e acelerando a disponibilização de ambientes de monitoramento para laboratórios e produção.
