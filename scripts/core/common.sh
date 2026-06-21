#!/bin/bash

# ============================================================
# Escalas Deploy - Funções Compartilhadas
# ============================================================
#
# Reúne funções compartilhadas utilizadas por diversas etapas
# do instalador.
#
# Este arquivo deve conter apenas funções reutilizáveis.
# Configurações do projeto devem permanecer em config.sh.
#
# ============================================================

# ------------------------------------------------------------
# Inicializa o sistema de logs da instalação.
#
# Todo o conteúdo exibido no terminal também será gravado no
# arquivo de log para facilitar auditoria e troubleshooting.
# ------------------------------------------------------------
init_logging() {

    rm -f "$LOG_FILE" 2>/dev/null || true
    touch "$LOG_FILE"

    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
}

# ------------------------------------------------------------
# Exibe as principais informações da instalação antes do início
# da execução do instalador.
# ------------------------------------------------------------
print_header() {

    echo "========================================"
    echo " Instalador - $APP_NAME"
    echo " Projeto Docker Compose: $PROJECT_NAME"
    echo " Diretório: $APP_DIR"
    echo " Modo desenvolvimento: $DEVELOPMENT_MODE"
    echo " Release GitHub: $RELEASE_VERSION"
    echo " Imagem aplicação: $APPLICATION_IMAGE"
    echo " Log: $LOG_FILE"
    echo "========================================"
}

# ------------------------------------------------------------
# Exibe uma mensagem informativa com data e hora.
# ------------------------------------------------------------
log() {

    echo
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo
}

# ------------------------------------------------------------
# Exibe o andamento da instalação.
# ------------------------------------------------------------
step() {

    CURRENT_STEP=$((CURRENT_STEP + 1))

    echo
    echo "========================================"
    echo "[$CURRENT_STEP/$TOTAL_STEPS] $1"
    echo "========================================"
    echo
}

# ------------------------------------------------------------
# Exibe uma mensagem de erro e encerra imediatamente
# a instalação.
# ------------------------------------------------------------
erro() {

    echo
    echo "========================================"
    echo "ERRO: $1"
    echo "Log da instalação: $LOG_FILE"
    echo "========================================"
    echo

    exit 1
}

# ------------------------------------------------------------
# Exibe uma mensagem de sucesso.
# ------------------------------------------------------------
sucesso() {

    echo
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo
}

# ------------------------------------------------------------
# Verifica se um comando está disponível no sistema.
# ------------------------------------------------------------
command_exists() {

    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------
# Solicita uma confirmação ao usuário.
#
# Retorna:
#   0 -> confirmação positiva
#   1 -> qualquer outra resposta
# ------------------------------------------------------------
confirmar() {

    local mensagem="$1"

    read -r -p "$mensagem [s/N]: " resposta

    case "$resposta" in
        s|S|sim|SIM|Sim)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Aguarda até que o gerenciador de pacotes (APT/dpkg)
# esteja disponível para uso.
# ------------------------------------------------------------
aguardar_apt_livre() {

    log "Verificando se o APT está livre..."

    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do

        echo "APT/dpkg está em uso por outro processo. Aguardando 5 segundos..."
        sleep 5

    done
}

# ------------------------------------------------------------
# Corrige instalações interrompidas que deixaram o dpkg
# em estado inconsistente.
# ------------------------------------------------------------
corrigir_dpkg() {

    log "Verificando estado do dpkg..."

    if dpkg --audit | grep -q .; then

        echo "dpkg possui pendências. Corrigindo..."

        dpkg --configure -a
        apt-get install -f -y

    else

        echo "dpkg está íntegro."

    fi
}

# ------------------------------------------------------------
# Carrega as variáveis definidas no arquivo .env, quando ele
# existir.
# ------------------------------------------------------------
load_env_file() {

    if [ -f "$APP_DIR/.env" ]; then

        set -a

        # shellcheck disable=SC1090
        source "$APP_DIR/.env"

        set +a

    fi
}

# ------------------------------------------------------------
# Obtém o endereço IP principal do servidor.
# ------------------------------------------------------------
get_host_ip() {

    hostname -I | awk '{print $1}'
}

# ------------------------------------------------------------
# Exibe a tela final da instalação.
#
# A URL da aplicação recebe destaque porque é a informação mais
# importante para quem acabou de executar o instalador.
# ------------------------------------------------------------
print_summary() {

    load_env_file

    local HOST_IP
    local DOCKER_VERSION
    local COMPOSE_VERSION
    local EXECUTION_MODE

    HOST_IP="$(get_host_ip)"
    DOCKER_VERSION="$(docker --version 2>/dev/null || echo 'não instalado')"
    COMPOSE_VERSION="$(docker compose version 2>/dev/null || echo 'não instalado')"

    if [ "$DEVELOPMENT_MODE" = true ]; then
        EXECUTION_MODE="Desenvolvimento"
    else
        EXECUTION_MODE="Produção"
    fi

    echo
    echo "============================================================"
    echo " Escalas Deploy concluído com sucesso!"
    echo "============================================================"
    echo
    echo "A instalação foi concluída e a aplicação foi iniciada."
    echo
    echo "============================================================"
    echo " Acesso ao Sistema"
    echo "============================================================"
    echo
    echo "URL:"
    echo
    echo "    http://${HOST_IP}:${APP_PORT:-8080}"
    echo
    echo "============================================================"
    echo " Banco de Dados"
    echo "============================================================"
    echo
    printf "%-17s %s\n" "Host:" "$HOST_IP"
    printf "%-17s %s\n" "Porta:" "${POSTGRES_PORT:-5432}"
    printf "%-17s %s\n" "Banco:" "${POSTGRES_DB:-escalas}"
    printf "%-17s %s\n" "Usuário:" "${POSTGRES_USER:-postgres}"
    printf "%-17s %s\n" "Senha:" "${POSTGRES_PASSWORD:-postgres}"
    echo
    echo "============================================================"
    echo " Arquivos"
    echo "============================================================"
    echo
    printf "%-17s %s\n" "Instalação:" "$APP_DIR"
    printf "%-17s %s\n" "Backup:" "$BACKUP_LOCAL_DIR"
    printf "%-17s %s\n" "Build:" "$APPLICATION_BUILD_DIR"
    printf "%-17s %s\n" "Log:" "$LOG_FILE"
    echo
    echo "============================================================"
    echo " Informações Técnicas"
    echo "============================================================"
    echo
    printf "%-17s %s\n" "Projeto:" "$PROJECT_NAME"
    printf "%-17s %s\n" "Imagem:" "$APPLICATION_IMAGE"
    printf "%-17s %s\n" "Release:" "$RELEASE_VERSION"
    printf "%-17s %s\n" "Docker:" "$DOCKER_VERSION"
    printf "%-17s %s\n" "Compose:" "$COMPOSE_VERSION"
    printf "%-17s %s\n" "Modo:" "$EXECUTION_MODE"
    echo
    echo "============================================================"
    echo
}
