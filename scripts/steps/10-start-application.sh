#!/bin/bash

# ============================================================
# Objetivo:
# Subir a stack completa do Sistema Escalas.
#
# Esta etapa:
# - inicia PostgreSQL e aplicação via Docker Compose;
# - valida se os containers estão em execução;
# - exibe os logs da aplicação caso ela falhe.
# ============================================================

start_application() {
    step "Subindo aplicação via Docker Compose"

    start_docker_compose_stack
    validate_application_container

    sucesso "Aplicação iniciada com sucesso."
}

start_docker_compose_stack() {

    log "Iniciando serviços do Docker Compose..."

    cd "$APP_DIR"

    docker compose -p "$PROJECT_NAME" up -d

}

validate_application_container() {

    log "Validando container da aplicação..."

    if ! docker ps --format '{{.Names}}' | grep -q "^${APP_NAME}-app$"; then
        echo
        echo "Container da aplicação não está em execução."
        echo "Exibindo logs:"
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