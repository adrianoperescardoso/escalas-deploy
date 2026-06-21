#!/bin/bash

# ============================================================
# Escalas Deploy - Build da Aplicação
# ============================================================
#
# Responsável por criar a imagem Docker da aplicação Escalas.
#
# Esta etapa:
# - valida o Dockerfile;
# - valida os arquivos preparados para o build;
# - executa o docker build;
# - confirma que a imagem foi criada.
#
# A aplicação ainda não é iniciada nesta etapa.
# ============================================================

build_application_image() {

    step "Criando imagem Docker da aplicação"

    validate_application_dockerfile
    validate_application_build_directory
    build_docker_image
    validate_docker_image

    sucesso "Imagem Docker da aplicação criada com sucesso."
}

# ------------------------------------------------------------
# Valida a existência do Dockerfile.
# ------------------------------------------------------------
validate_application_dockerfile() {

    log "Validando Dockerfile da aplicação..."

    [ -f "$APPLICATION_DOCKERFILE" ]         || erro "Dockerfile da aplicação não encontrado: $APPLICATION_DOCKERFILE"
}

# ------------------------------------------------------------
# Valida os arquivos necessários para o build.
# ------------------------------------------------------------
validate_application_build_directory() {

    log "Validando diretório de build da aplicação..."

    [ -d "$APPLICATION_BUILD_DIR" ]         || erro "Diretório de build da aplicação não encontrado: $APPLICATION_BUILD_DIR"

    [ -f "$APPLICATION_BUILD_DIR/bin/GxNetCoreStartup.dll" ]         || erro "Arquivo principal da aplicação não encontrado: $APPLICATION_BUILD_DIR/bin/GxNetCoreStartup.dll"
}

# ------------------------------------------------------------
# Executa o build da imagem Docker.
# ------------------------------------------------------------
build_docker_image() {

    log "Executando docker build..."

    echo "Dockerfile : $APPLICATION_DOCKERFILE"
    echo "Contexto   : $APPLICATION_BUILD_DIR"
    echo "Imagem     : $APPLICATION_IMAGE"

    docker build         -t "$APPLICATION_IMAGE"         -f "$APPLICATION_DOCKERFILE"         "$APPLICATION_BUILD_DIR"
}

# ------------------------------------------------------------
# Valida se a imagem foi criada com sucesso.
# ------------------------------------------------------------
validate_docker_image() {

    log "Validando imagem Docker criada..."

    docker image inspect "$APPLICATION_IMAGE" >/dev/null 2>&1         || erro "Imagem Docker não foi encontrada após o build: $APPLICATION_IMAGE"

    echo
    echo "============================================================"
    echo " Imagem Docker criada"
    echo "============================================================"
    echo "Imagem : $APPLICATION_IMAGE"
    echo "============================================================"
    echo
}
