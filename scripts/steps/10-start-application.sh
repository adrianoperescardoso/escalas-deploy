#!/bin/bash

# ============================================================
# Escalas Deploy - Inicialização da Aplicação
# ============================================================
#
# Responsável por iniciar a stack completa do Sistema Escalas.
#
# Esta etapa:
# - inicia os serviços definidos no Docker Compose;
# - valida se a aplicação entrou em execução;
# - exibe os logs caso ocorra alguma falha.
#
# Ao final desta etapa a aplicação estará disponível para uso.
# ============================================================

start_application() {

    step "Subindo aplicação via Docker Compose"

    start_docker_compose_stack
    validate_application_container

    sucesso "Aplicação iniciada com sucesso."
}

# ------------------------------------------------------------
# Inicializa todos os serviços do Docker Compose.
# ------------------------------------------------------------
start_docker_compose_stack() {

    log "Iniciando serviços do Docker Compose..."

    cd "$APP_DIR"

    docker compose -p "$PROJECT_NAME" up -d
}

# ------------------------------------------------------------
# Valida se o container da aplicação iniciou corretamente.
# ------------------------------------------------------------
validate_application_container() {

    log "Validando container da aplicação..."

    if ! docker ps --format '{{.Names}}' | grep -q "^${APP_NAME}-app$"; then

        echo
        echo "Container da aplicação não está em execução."
        echo "Exibindo logs da aplicação..."
        echo

        docker logs "${APP_NAME}-app" 2>/dev/null || true

        erro "Aplicação não iniciou corretamente."
    fi

    echo
    echo "============================================================"
    echo " Aplicação em execução"
    echo "============================================================"
    echo "Container : ${APP_NAME}-app"
    echo "Imagem    : ${APPLICATION_IMAGE}"
    echo "Porta     : APP_PORT -> 8080"
    echo "============================================================"
    echo
}
