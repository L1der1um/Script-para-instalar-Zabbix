#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação Automatizada - Zabbix Server 7.0 LTS
# Compatibilidade: Ubuntu Server (20.04, 22.04, 24.04, 26.04) e Debian (11, 12, 13)
# ==============================================================================

# Cores para feedback visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# === VERIFICAÇÃO DE PRIVILÉGIOS (ROOT) ===
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ ERRO: Execute este script como root ou utilize 'sudo ./install_zabbix.sh'.${NC}" >&2
    exit 1
fi

# === GARANTINDO O PATH ADMINISTRATIVO ===
if [[ ":$PATH:" != *":/usr/sbin:"* || ":$PATH:" != *":/sbin:"* || ":$PATH:" != *":/usr/local/sbin:"* ]]; then
    export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
fi

# Evita telas azuis/roxas interativas durante a instalação de pacotes
export DEBIAN_FRONTEND=noninteractive

# === DETECÇÃO DO SISTEMA OPERACIONAL ===
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

SYSTEM=$(detect_system)

if [[ "$SYSTEM" == "unsupported" || "$SYSTEM" == "unknown" ]]; then
    echo -e "${RED}❌ Sistema não suportado! Este script funciona apenas em Ubuntu ou Debian.${NC}"
    exit 1
fi

# Obter versão do sistema
if command -v lsb_release &> /dev/null; then
    OS_VERSION=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
else
    OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
    OS_CODENAME=$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')
fi

# === VARIÁVEIS DE CONFIGURAÇÃO ===
ZBX_LTS="7.0"
DB_PASSWORD="SenhaSegura123!"
ZBX_DB="zabbix"
ZBX_USER="zabbix"
PHP_TIMEZONE="America/Sao_Paulo"

# === SPLASH BANNER ===
clear
echo -e "${BLUE}"
echo "███████╗ █████╗ ██████╗ ██████╗ ██╗██╗  ██╗"
echo "╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██║╚██╗██╔╝"
echo "  ███╔╝ ███████║██████╔╝██████╔╝██║ ╚███╔╝ "
echo " ███╔╝  ██╔══██║██╔══██╗██╔══██╗██║ ██╔██╗ "
echo "███████╗██║  ██║██████╔╝██████╔╝██║██╔╝ ██╗"
echo "╚══════╝╚═╝  ╚═╝╚═════╝╚═════╝ ╚═╝╚═╝  ╚═╝"
echo -e "${NC}"
echo "========================================================"
echo "      INSTALADOR ZABBIX ${ZBX_LTS} LTS - SERVIDOR COMPLETO"
echo "      Sistema: ${SYSTEM^^} ${OS_VERSION} (${OS_CODENAME})"
echo "========================================================"
echo ""
sleep 1

# === ETAPA 1: ATUALIZAÇÃO E DEPENDÊNCIAS ===
echo -e "${GREEN}🔄 [ETAPA 1/7] Atualizando repositórios e instalando dependências base...${NC}"
apt update -y
apt install -y wget curl gnupg2 ca-certificates lsb-release

# Ajuste de fuso horário do sistema operacional
timedatectl set-timezone "$PHP_TIMEZONE" 2>/dev/null || true

# === ETAPA 2: BANCO DE DADOS (MARIADB) ===
echo -e "\n${GREEN}🛢️ [ETAPA 2/7] Instalando e inicializando MariaDB Server...${NC}"
apt install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl restart mariadb

# === ETAPA 3: CONFIGURAÇÃO DA BASE DO ZABBIX (IDEMPOTENTE) ===
echo -e "\n${GREEN}💾 [ETAPA 3/7] Preparando banco de dados '${ZBX_DB}'...${NC}"
mariadb <<EOF
DROP DATABASE IF EXISTS ${ZBX_DB};
CREATE DATABASE ${ZBX_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '${ZBX_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${ZBX_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${ZBX_DB}.* TO '${ZBX_USER}'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

# === ETAPA 4: REPOSITÓRIO OFICIAL ZABBIX (LTS DINÂMICO) ===
echo -e "\n${GREEN}📊 [ETAPA 4/7] Configurando repositório oficial Zabbix ${ZBX_LTS} LTS...${NC}"

if [[ "$SYSTEM" == "ubuntu" ]]; then
    REPO_URL="https://repo.zabbix.com/zabbix/${ZBX_LTS}/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_${ZBX_LTS}+ubuntu${OS_VERSION}_all.deb"
elif [[ "$SYSTEM" == "debian" ]]; then
    DEBIAN_MAJOR=$(echo "$OS_VERSION" | cut -d. -f1)
    REPO_URL="https://repo.zabbix.com/zabbix/${ZBX_LTS}/debian/pool/main/z/zabbix-release/zabbix-release_latest_${ZBX_LTS}+debian${DEBIAN_MAJOR}_all.deb"
fi

echo -e "${YELLOW}URL selecionada: ${REPO_URL}${NC}"

if ! wget -q -O /tmp/zabbix-release.deb "$REPO_URL"; then
    echo -e "\n${RED}❌ FALHA CRÍTICA: Não foi possível baixar o repositório Zabbix.${NC}"
    exit 1
fi

dpkg -i /tmp/zabbix-release.deb
rm -f /tmp/zabbix-release.deb
apt update -y

# === ETAPA 5: INSTALAÇÃO DO ZABBIX SERVER, APACHE E FRONTEND ===
echo -e "\n${GREEN}📦 [ETAPA 5/7] Instalando pacotes do Zabbix, PHP-FPM e servidor Web...${NC}"
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# === ETAPA 6: IMPORTAÇÃO DO SCHEMA E AJUSTES DE CONFIGURAÇÃO ===
echo -e "\n${GREEN}🗃️ [ETAPA 6/7] Importando schema da base de dados...${NC}"
SCHEMA_PATH="/usr/share/zabbix-sql-scripts/mysql/server.sql.gz"

if [ ! -f "$SCHEMA_PATH" ]; then
    echo -e "${RED}❌ Arquivo de schema não encontrado em ${SCHEMA_PATH}.${NC}"
    exit 1
fi

echo -e "${YELLOW}⏳ Importando tabelas (aguarde)...${NC}"
if ! zcat "$SCHEMA_PATH" | mariadb -u"${ZBX_USER}" -p"${DB_PASSWORD}" "${ZBX_DB}"; then
    echo -e "${RED}❌ Erro durante a importação do schema!${NC}"
    exit 1
fi
echo -e "${GREEN}✔ Schema importado com sucesso!${NC}"

# Desativar a flag especial após a carga
mariadb -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Configurar senha no zabbix_server.conf
sed -i "s/^# DBPassword=/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf

# Ajustar Timezone em TODOS os php.ini instalados (fpm, cli, apache2)
find /etc/php/ -name "php.ini" -exec sed -i "s@;*date.timezone =.*@date.timezone = ${PHP_TIMEZONE}@" {} + 2>/dev/null || true

# === ETAPA 7: INTEGRAÇÃO APACHE + PHP-FPM E INICIALIZAÇÃO ===
echo -e "\n${GREEN}🔥 [ETAPA 7/7] Configurando Apache, PHP-FPM e Daemons...${NC}"

# 1. Habilitar módulos necessários do Apache para interpretar PHP via FastCGI
a2enmod proxy_fcgi setenvif &>/dev/null || true

# 2. Habilitar automaticamente a configuração da versão ativa do PHP-FPM
for conf in /etc/apache2/conf-available/php*-fpm.conf; do
    if [ -f "$conf" ]; then
        CONF_NAME=$(basename "$conf" .conf)
        a2enconf "$CONF_NAME" &>/dev/null || true
    fi
done

# 3. Garantir a configuração do Zabbix no Apache
a2enconf zabbix &>/dev/null || true

# 4. Ajustar regras de Firewall UFW (caso ativo)
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 80/tcp comment "Zabbix Web UI"
    ufw allow 10051/tcp comment "Zabbix Server Trapper"
    ufw allow 10050/tcp comment "Zabbix Agent Local"
    ufw reload &>/dev/null
    echo -e "Portas liberadas no firewall: ${YELLOW}80/tcp (Web), 10051/tcp (Server), 10050/tcp (Agent)${NC}"
fi

# 5. Lista de serviços a inicializar e validar
SERVICES=("mariadb" "zabbix-server" "zabbix-agent" "apache2")

# Identificar dinamicamente o serviço PHP-FPM instalado
while read -r svc; do
    [ -n "$svc" ] && SERVICES+=("$svc")
done < <(systemctl list-unit-files 'php*-fpm.service' --no-legend 2>/dev/null | awk '{print $1}')

# 6. Reiniciar, habilitar e validar cada daemon individualmente
echo -e "${YELLOW}Iniciando e testando integridade dos daemons...${NC}"
for svc in "${SERVICES[@]}"; do
    systemctl enable "$svc" &>/dev/null
    if ! systemctl restart "$svc"; then
        echo -e "\n${RED}❌ ERRO CRÍTICO: Falha ao iniciar o serviço '${svc}'.${NC}"
        echo -e "${YELLOW}--- Últimos logs do serviço (${svc}) ---${NC}"
        journalctl -xeu "$svc" --no-pager -n 20
        exit 1
    fi

    if ! systemctl is-active --quiet "$svc"; then
        echo -e "\n${RED}❌ ERRO: O serviço '${svc}' não permaneceu em execução.${NC}"
        exit 1
    fi
    echo -e "  ✔ Serviço ${GREEN}${svc}${NC}: Ativo e operacional"
done

# Obter IP primário da máquina
SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' || hostname -I | awk '{print $1}')

# === CONCLUSÃO E INSTRUÇÕES ===
echo -e "\n${GREEN}========================================================${NC}"
echo -e "${GREEN}   ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO! ✅${NC}"
echo -e "${GREEN}========================================================${NC}"
echo -e "🌐 ${YELLOW}Interface Web:${NC}     http://${SERVER_IP}/zabbix"
echo -e "👤 ${YELLOW}Usuário Padrão:${NC}    Admin"
echo -e "🔑 ${YELLOW}Senha Padrão:${NC}      zabbix"
echo -e "--------------------------------------------------------"
echo -e "🛢️ ${YELLOW}Base de Dados:${NC}     ${ZBX_DB}"
echo -e "👤 ${YELLOW}Usuário do Banco:${NC}  ${ZBX_USER}"
echo -e "🔑 ${YELLOW}Senha do Banco:${NC}    ${DB_PASSWORD}"
echo -e "--------------------------------------------------------"
echo -e "🛠️ ${YELLOW}Checar portas ativas:${NC} ss -tulpn | grep -E ':(80|10051|3306)'"
echo -e "${GREEN}========================================================${NC}"
