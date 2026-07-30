#!/bin/bash

# Cores para mensagens
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para detectar o sistema
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" ]]; then
            echo "debian"
        elif [[ "$ID" == "ubuntu" ]]; then
            echo "ubuntu"
        else
            echo "unsupported"
        fi
    else
        echo "unknown"
    fi
}

# Verificar compatibilidade
SYSTEM=$(detect_system)
OS_VERSION=$(lsb_release -rs)
OS_CODENAME=$(lsb_release -cs)

if [[ "$SYSTEM" == "unsupported" || "$SYSTEM" == "unknown" ]]; then
    echo -e "${RED}❌ Sistema não suportado! Este script funciona apenas em Debian ou Ubuntu.${NC}"
    exit 1
fi

show_splash() {
    clear
    echo -e "\e[31m"
    echo "███████╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗"
    echo "╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝"
    echo "  ███╔╝ ███████║██████╔╝██████╔╝██║ ╚███╔╝ "
    echo " ███╔╝  ██╔══██║██╔══██╗██╔══██╗██║ ██╔██╗ "
    echo "███████╗██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗"
    echo "╚══════╝╚═╝  ╚═╝╚═════╝╚═════╝ ╚═╝╚═╝  ╚═╝"
    echo -e "\e[0m"
    echo "========================================================"
    echo "         INSTALADOR ZABBIX 7 LTS (Somente Zabbix)"
    echo "           PARA ${SYSTEM^^} $OS_VERSION ($OS_CODENAME)"
    echo "========================================================"
    echo ""
    sleep 2
}

show_splash

echo -e "${BLUE}========================================================${NC}"
echo -e "          ${YELLOW}🚀 Instalação Automatizada Segura${NC}"
echo -e "          ${YELLOW}📜 Zabbix 7.0 LTS (MySQL)${NC}"
echo -e "${BLUE}========================================================${NC}"

# === VERIFICAÇÃO DE ROOT ===
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${RED}❌ ERRO: Este script deve ser executado como root ou com sudo.${NC}" >&2
    exit 1
fi

# === GARANTINDO O PATH CORRETO PARA O ROOT ===
if [[ ":$PATH:" != *":/usr/sbin:"* || ":$PATH:" != *":/sbin:"* || ":$PATH:" != *":/usr/local/sbin:"* ]]; then
    echo -e "${YELLOW}⚠️ PATH do root incompleto. Adicionando diretórios administrativos ao PATH...${NC}"
    export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
fi

# === VARIÁVEIS ===
DB_PASSWORD="zabbix@123"
ZBX_DB="zabbix"
ZBX_USER="zabbix"
PHP_TIMEZONE="America/Sao_Paulo"

# === ATUALIZAÇÃO DO SISTEMA ===
echo -e "\n${GREEN}🔄 [ETAPA 1/7] Verificando dependências e atualizando pacotes...${NC}"
apt update && apt upgrade -y
apt install -y wget curl gnupg2 lsb-release apt-transport-https ca-certificates software-properties-common net-tools

# Configurar timezone
timedatectl set-timezone $PHP_TIMEZONE

# === INSTALAÇÃO DO BANCO DE DADOS ===
echo -e "\n${GREEN}🛢️ [ETAPA 2/7] Instalando MySQL/MariaDB Server...${NC}"
if [[ "$SYSTEM" == "debian" ]]; then
    apt install -y mariadb-server mariadb-client
else
    apt install -y mysql-server
fi
systemctl enable mysql
systemctl start mysql

# === CONFIGURAÇÃO DO BANCO DE DADOS ===
echo -e "\n${GREEN}💾 [ETAPA 3/7] Recriando banco de dados limpo para o Zabbix...${NC}"
mysql -uroot <<MYSQL_SCRIPT
DROP DATABASE IF EXISTS $ZBX_DB;
CREATE DATABASE $ZBX_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '$ZBX_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
ALTER USER '$ZBX_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $ZBX_DB.* TO '$ZBX_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# === INSTALAÇÃO DO ZABBIX 7.0 (COM TRAVA DE SEGURANÇA) ===
echo -e "\n${GREEN}📊 [ETAPA 4/7] Adicionando repositório oficial do Zabbix 7.0 LTS...${NC}"

if [[ "$SYSTEM" == "ubuntu" && "$OS_VERSION" == "24.04" ]]; then
    REPO_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-5%2Bubuntu24.04_all.deb"
elif [[ "$SYSTEM" == "debian" ]]; then
    REPO_URL="https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian12_all.deb"
else
    REPO_URL="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu${OS_VERSION}_all.deb"
fi

echo -e "${YELLOW}Tentando baixar o repositório: ${REPO_URL}${NC}"

if ! wget -O zabbix-release.deb "$REPO_URL"; then
    echo -e "\n${RED}======================================================================${NC}"
    echo -e "${RED}❌ FALHA CRÍTICA: O repositório do Zabbix 7.0 não foi encontrado!${NC}"
    echo -e "${RED}A execução do script será abortada para evitar quebrar seu servidor.${NC}"
    echo -e "${RED}======================================================================${NC}"
    exit 1
fi

dpkg -i zabbix-release.deb
apt update

echo -e "\n${GREEN}📦 [ETAPA 5/7] Instalando Zabbix server, frontend e agente...${NC}"
if ! apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent; then
     echo -e "\n${RED}❌ ERRO: Falha ao instalar os pacotes do Zabbix. Verifique o log acima.${NC}"
     exit 1
fi

# === INSTALAÇÃO DO PHP ===
echo -e "\n${GREEN}🐘 [ETAPA 6/7] Instalando módulos PHP necessários...${NC}"
if [[ "$SYSTEM" == "debian" ]]; then
    apt install -y php8.2 php8.2-mysql php8.2-bcmath php8.2-mbstring php8.2-gd php8.2-xml php8.2-curl php8.2-ldap php8.2-zip
else
    apt install -y php php-mysql php-bcmath php-mbstring php-gd php-xml php-curl php-ldap php-zip
fi

echo -e "\n${GREEN}⏰ Configurando fuso horário do PHP...${NC}"
if [[ "$SYSTEM" == "debian" ]]; then
    sed -i "s@;date.timezone =@date.timezone = $PHP_TIMEZONE@" /etc/php/8.2/apache2/php.ini
else
    sed -i "s@;date.timezone =@date.timezone = $PHP_TIMEZONE@" /etc/php/*/apache2/php.ini
fi

echo -e "\n${GREEN}🗃️ Importando schema do banco de dados do Zabbix...${NC}"
echo -e "${YELLOW}⏳ ATENÇÃO: Esta etapa copia milhares de tabelas e leva de 10 a 15 minutos.${NC}"
echo -e "${RED}⏳ NÃO APERTE CTRL+C. Por favor, aguarde o processo terminar silenciosamente...${NC}"

# O '2>/dev/null' esconde o aviso inofensivo de senha do MySQL para não assustar o usuário
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u$ZBX_USER -p$DB_PASSWORD $ZBX_DB 2>/dev/null

echo -e "${GREEN}✅ Importação concluída com sucesso!${NC}"

echo -e "\n${GREEN}🛡️ Desativando log_bin_trust_function_creators (Segurança)...${NC}"
mysql -uroot -e "SET GLOBAL log_bin_trust_function_creators = 0;"

echo -e "\n${GREEN}⚙️ Ajustando configuração do Zabbix server...${NC}"
sed -i "s/^# DBPassword=/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

echo -e "\n${GREEN}🚀 Habilitando e iniciando serviços do Zabbix...${NC}"
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

# === CONFIGURAÇÃO DO FIREWALL ===
echo -e "\n${GREEN}🔥 [ETAPA 7/7] Configurando firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 10050/tcp
    ufw reload
    echo -e "Portas liberadas: ${YELLOW}80, 10050${NC}"
fi

# === INFORMAÇÕES DE ACESSO ===
echo -e "\n${GREEN}✅ ✅ ✅ Instalação concluída com sucesso! ✅ ✅ ✅${NC}"
echo -e "${BLUE}========================================================${NC}"
echo -e "🌐 ${YELLOW}ACESSO AO ZABBIX 7.0 LTS:${NC}"
echo -e "   URL:      ${GREEN}http://$(hostname -I | awk '{print $1}')/zabbix${NC}"
echo -e "   Usuário:  ${YELLOW}Admin${NC}"
echo -e "   Senha:    ${YELLOW}zabbix${NC}"
echo -e "${BLUE}--------------------------------------------------------${NC}"
echo -e "🛢️ ${YELLOW}CREDENCIAIS DO BANCO DE DADOS:${NC}"
echo -e "   Usuário:  ${YELLOW}${ZBX_USER}${NC}"
echo -e "   Senha:    ${YELLOW}${DB_PASSWORD}${NC}"
echo -e "${BLUE}========================================================${NC}"
echo -e "🔒 ${RED}IMPORTANTE:${NC} Altere todas as senhas padrão após a instalação!"
echo -e "${BLUE}========================================================${NC}"
echo -e "🛠️ ${YELLOW}COMANDOS ÚTEIS:${NC}"
echo -e "   Verificar status: ${YELLOW}sudo systemctl status zabbix-server${NC}"
echo -e "   Verificar logs:   ${YELLOW}tail -50 /var/log/zabbix/zabbix_server.log${NC}"
echo -e "${BLUE}========================================================${NC}"
