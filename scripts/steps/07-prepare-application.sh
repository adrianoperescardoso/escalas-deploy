#!/bin/bash

# ============================================================
# Objetivo:
# Preparar os arquivos da aplicação para criação da imagem Docker.
#
# Nesta etapa:
# - valida se o pacote da aplicação existe;
# - cria o diretório de build;
# - remove arquivos antigos do build;
# - descompacta a aplicação;
# - valida os principais arquivos.
#
# Esta etapa NÃO cria a imagem Docker.
# ============================================================

prepare_application() {
    step "Preparando arquivos da aplicação"

    validate_application_package
    create_application_build_directory
    extract_application_package
    validate_application_files

    sucesso "Arquivos da aplicação preparados com sucesso."
}

validate_application_package() {

    log "Validando pacote da aplicação..."

    if [ ! -f "$APPLICATION_LOCAL_FILE" ]; then
        erro "Pacote da aplicação não encontrado: $APPLICATION_LOCAL_FILE"
    fi

    if [ ! -s "$APPLICATION_LOCAL_FILE" ]; then
        erro "Pacote da aplicação está vazio."
    fi

}

create_application_build_directory() {

    log "Preparando diretório de build da aplicação..."

    mkdir -p "$APPLICATION_BUILD_DIR"

    if [ "$DEVELOPMENT_MODE" = true ]; then
        log "Removendo arquivos antigos do build..."

        rm -rf "${APPLICATION_BUILD_DIR:?}/"*
    fi

}

extract_application_package() {

    log "Extraindo arquivos da aplicação para o build..."

    unzip -o \
        "$APPLICATION_LOCAL_FILE" \
        -d "$APPLICATION_BUILD_DIR" >/dev/null

}

validate_application_files() {

    log "Validando estrutura da aplicação..."

    local STARTUP_DLL
    local APPSETTINGS

    STARTUP_DLL=$(find "$APPLICATION_BUILD_DIR" -name "GxNetCoreStartup.dll" | head -n 1)
    APPSETTINGS=$(find "$APPLICATION_BUILD_DIR" -name "appsettings.json" | head -n 1)

    [ -z "$STARTUP_DLL" ] && erro "GxNetCoreStartup.dll não encontrado."
    [ -z "$APPSETTINGS" ] && erro "appsettings.json não encontrado."

    echo
    echo "============================================================"
    echo " Aplicação preparada"
    echo "============================================================"
    echo "Pacote      : $APPLICATION_PACKAGE_NAME"
    echo "Origem      : $APPLICATION_LOCAL_FILE"
    echo "Destino     : $APPLICATION_BUILD_DIR"
    echo "Startup DLL : $STARTUP_DLL"
    echo "Configuração: $APPSETTINGS"
    echo "============================================================"
    echo

}