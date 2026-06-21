#!/bin/bash

# ============================================================
# Objetivo:
# Preparar os arquivos da aplicação GeneXus para criação da
# imagem Docker.
#
# Nesta etapa:
# - valida se o pacote da aplicação existe;
# - cria o diretório de build;
# - remove arquivos antigos do build;
# - descompacta a aplicação;
# - localiza o appsettings.json gerado pelo GeneXus;
# - transforma as configurações de conexão em variáveis;
# - valida os principais arquivos da aplicação.
#
# Esta etapa NÃO cria a imagem Docker.
# Ela apenas deixa o pacote GeneXus pronto para ser usado pelo
# Dockerfile na próxima etapa.
# ============================================================

prepare_application() {
    step "Preparando arquivos da aplicação"

    validate_application_package
    create_application_build_directory
    extract_application_package
    configure_genexus_appsettings
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

configure_genexus_appsettings() {

    log "Parametrizando appsettings.json gerado pelo GeneXus..."

    local APPSETTINGS_FILE

    APPSETTINGS_FILE=$(find "$APPLICATION_BUILD_DIR" -name "appsettings.json" | head -n 1)

    if [ -z "$APPSETTINGS_FILE" ]; then
        erro "appsettings.json não encontrado para parametrização."
    fi

    # ------------------------------------------------------------
    # Contexto:
    # O GeneXus gera o appsettings.json com os dados de conexão
    # "chapados", ou seja, fixos para o ambiente usado na geração.
    #
    # Como este instalador precisa funcionar em qualquer VM,
    # substituímos os valores fixos por variáveis ${GX_CONNECTION_*}.
    #
    # Depois, quando o container iniciar, o Dockerfile executará
    # envsubst e trocará essas variáveis pelos valores reais
    # vindos do .env carregado pelo Docker Compose.
    # ------------------------------------------------------------

    cp "$APPSETTINGS_FILE" "${APPSETTINGS_FILE}.original"

    replace_json_value "$APPSETTINGS_FILE" "Connection-Default-Datasource" '${GX_CONNECTION_DEFAULT_DATASOURCE}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-Default-User" '${GX_CONNECTION_DEFAULT_USER}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-Default-Password" '${GX_CONNECTION_DEFAULT_PASSWORD}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-Default-DB" '${GX_CONNECTION_DEFAULT_DB}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-Default-Port" '${GX_CONNECTION_DEFAULT_PORT}'

    replace_json_value "$APPSETTINGS_FILE" "Connection-GAM-Datasource" '${GX_CONNECTION_GAM_DATASOURCE}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-GAM-User" '${GX_CONNECTION_GAM_USER}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-GAM-Password" '${GX_CONNECTION_GAM_PASSWORD}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-GAM-DB" '${GX_CONNECTION_GAM_DB}'
    replace_json_value "$APPSETTINGS_FILE" "Connection-GAM-Port" '${GX_CONNECTION_GAM_PORT}'

    validate_genexus_appsettings_variables "$APPSETTINGS_FILE"

    log "appsettings.json parametrizado com sucesso."
}

replace_json_value() {

    local FILE_PATH="$1"
    local JSON_KEY="$2"
    local NEW_VALUE="$3"

    # ------------------------------------------------------------
    # Substitui o valor de uma chave simples do JSON.
    #
    # Exemplo:
    # "Connection-Default-Datasource": "127.0.0.1"
    #
    # vira:
    # "Connection-Default-Datasource": "${GX_CONNECTION_DEFAULT_DATASOURCE}"
    #
    # O appsettings gerado pelo GeneXus usa esse formato simples,
    # por isso o sed é suficiente aqui.
    # ------------------------------------------------------------

    if ! grep -q "\"${JSON_KEY}\"" "$FILE_PATH"; then
        erro "Chave não encontrada no appsettings.json: ${JSON_KEY}"
    fi

    sed -i \
        "s#\"${JSON_KEY}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"${JSON_KEY}\": \"${NEW_VALUE}\"#g" \
        "$FILE_PATH"

}

validate_genexus_appsettings_variables() {

    local APPSETTINGS_FILE="$1"

    log "Validando variáveis no appsettings.json..."

    grep -q '\${GX_CONNECTION_DEFAULT_DATASOURCE}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_DEFAULT_DATASOURCE não aplicada."
    grep -q '\${GX_CONNECTION_DEFAULT_USER}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_DEFAULT_USER não aplicada."
    grep -q '\${GX_CONNECTION_DEFAULT_PASSWORD}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_DEFAULT_PASSWORD não aplicada."
    grep -q '\${GX_CONNECTION_DEFAULT_DB}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_DEFAULT_DB não aplicada."
    grep -q '\${GX_CONNECTION_DEFAULT_PORT}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_DEFAULT_PORT não aplicada."

    grep -q '\${GX_CONNECTION_GAM_DATASOURCE}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_GAM_DATASOURCE não aplicada."
    grep -q '\${GX_CONNECTION_GAM_USER}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_GAM_USER não aplicada."
    grep -q '\${GX_CONNECTION_GAM_PASSWORD}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_GAM_PASSWORD não aplicada."
    grep -q '\${GX_CONNECTION_GAM_DB}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_GAM_DB não aplicada."
    grep -q '\${GX_CONNECTION_GAM_PORT}' "$APPSETTINGS_FILE" || erro "Variável GX_CONNECTION_GAM_PORT não aplicada."

}

validate_application_files() {

    log "Validando estrutura da aplicação..."

    local STARTUP_DLL
    local APPSETTINGS
    local CONNECTION_GAM

    STARTUP_DLL=$(find "$APPLICATION_BUILD_DIR" -name "GxNetCoreStartup.dll" | head -n 1)
    APPSETTINGS=$(find "$APPLICATION_BUILD_DIR" -name "appsettings.json" | head -n 1)
    CONNECTION_GAM=$(find "$APPLICATION_BUILD_DIR" -name "connection.gam" | head -n 1)

    [ -z "$STARTUP_DLL" ] && erro "GxNetCoreStartup.dll não encontrado."
    [ -z "$APPSETTINGS" ] && erro "appsettings.json não encontrado."
    [ -z "$CONNECTION_GAM" ] && erro "connection.gam não encontrado."

    echo
    echo "============================================================"
    echo " Aplicação preparada"
    echo "============================================================"
    echo "Pacote          : $APPLICATION_PACKAGE_NAME"
    echo "Origem          : $APPLICATION_LOCAL_FILE"
    echo "Destino         : $APPLICATION_BUILD_DIR"
    echo "Startup DLL     : $STARTUP_DLL"
    echo "Configuração    : $APPSETTINGS"
    echo "Backup original : ${APPSETTINGS}.original"
    echo "Connection GAM  : $CONNECTION_GAM"
    echo "============================================================"
    echo

}