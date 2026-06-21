#!/bin/bash

# ============================================================
# Objetivo:
# Criar a imagem Docker da aplicação Escalas.
#
# Esta etapa:
# - valida se o Dockerfile existe;
# - valida se os arquivos da aplicação foram extraídos;
# - executa o docker build;
# - confirma se a imagem foi criada.
#
# Esta etapa NÃO inicia a aplicação.
# ============================================================

build_application_image() {
    step "Criando imagem Docker da aplicação"

    validate_application_dockerfile
    validate_application_build_directory
    build_docker_image
    validate_docker_image

    sucesso "Imagem Docker da aplicação criada com sucesso."
}

validate_application_dockerfile() {

    log "Validando Dockerfile da aplicação..."

    if [ ! -f "$APPLICATION_DOCKERFILE" ]; then
        erro "Dockerfile da aplicação não encontrado: $APPLICATION_DOCKERFILE"
    fi

}

validate_application_build_directory() {

    log "Validando diretório de build da aplicação..."

    if [ ! -d "$APPLICATION_BUILD_DIR" ]; then
        erro "Diretório de build da aplicação não encontrado: $APPLICATION_BUILD_DIR"
    fi

    if [ ! -f "$APPLICATION_BUILD_DIR/bin/GxNetCoreStartup.dll" ]; then
        erro "Arquivo principal da aplicação não encontrado: $APPLICATION_BUILD_DIR/bin/GxNetCoreStartup.dll"
    fi

}

build_docker_image() {

    log "Executando docker build..."

    echo "Dockerfile : $APPLICATION_DOCKERFILE"
    echo "Contexto   : $APPLICATION_BUILD_DIR"
    echo "Imagem     : $APPLICATION_IMAGE"

    docker build \
        -t "$APPLICATION_IMAGE" \
        -f "$APPLICATION_DOCKERFILE" \
        "$APPLICATION_BUILD_DIR"

}

validate_docker_image() {

    log "Validando imagem Docker criada..."

    if ! docker image inspect "$APPLICATION_IMAGE" >/dev/null 2>&1; then
        erro "Imagem Docker não foi encontrada após o build: $APPLICATION_IMAGE"
    fi

    echo
    echo "============================================================"
    echo " Imagem Docker criada"
    echo "============================================================"
    echo "Imagem : $APPLICATION_IMAGE"
    echo "============================================================"
    echo

}