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
# Exibe as informações necessárias para acesso ao ambiente
# após a conclusão da instalação.
# ------------------------------------------------------------
show_access_information() {

    load_env_file

    local HOST_IP
    HOST_IP="$(get_host_ip)"

    echo
    echo "========================================"
    echo " Informações de acesso"
    echo "========================================"
    echo
    echo "Aplicação"
    echo "----------------------------------------"
    echo "URL...............: http://${HOST_IP}:${APP_PORT:-8080}"
    echo
    echo "PostgreSQL"
    echo "----------------------------------------"
    echo "Host..............: ${HOST_IP}"
    echo "Porta.............: ${POSTGRES_PORT:-5432}"
    echo "Banco.............: ${POSTGRES_DB:-escalas}"
    echo "Usuário...........: ${POSTGRES_USER:-postgres}"
    echo
    echo "Docker"
    echo "----------------------------------------"
    echo "Projeto Compose...: ${PROJECT_NAME}"
    echo "Imagem aplicação..: ${APPLICATION_IMAGE}"
    echo
    echo "Arquivos"
    echo "----------------------------------------"
    echo "Diretório.........: ${APP_DIR}"
    echo "Backup............: ${BACKUP_LOCAL_DIR}"
    echo "Build.............: ${APPLICATION_BUILD_DIR}"
    echo "Log...............: ${LOG_FILE}"
    echo "========================================"
    echo
}

# ------------------------------------------------------------
# Exibe um resumo da instalação realizada.
# ------------------------------------------------------------
print_summary() {

    echo
    echo "========================================"
    echo " Resumo da instalação"
    echo "========================================"
    echo "Aplicação              : $APP_NAME"
    echo "Projeto Docker Compose : $PROJECT_NAME"
    echo "Diretório              : $APP_DIR"
    echo "Modo desenvolvimento   : $DEVELOPMENT_MODE"
    echo "Release GitHub         : $RELEASE_VERSION"
    echo "Imagem aplicação       : $APPLICATION_IMAGE"
    echo "Docker                 : $(docker --version 2>/dev/null || echo 'não instalado')"
    echo "Docker Compose         : $(docker compose version 2>/dev/null || echo 'não instalado')"
    echo "Log                    : $LOG_FILE"
    echo "========================================"
    echo
}