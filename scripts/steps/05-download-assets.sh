#!/bin/bash

# ============================================================
# Objetivo:
# Baixar os artefatos necessários para a instalação.
#
# Esta etapa:
# - cria os diretórios locais;
# - baixa o backup PostgreSQL;
# - baixa o pacote da aplicação;
# - valida os arquivos baixados.
# ============================================================

download_assets() {
    step "Baixando artefatos da instalação"

    create_assets_directories

    download_database_backup
    validate_database_backup

    download_application_package
    validate_application_package

    sucesso "Artefatos baixados com sucesso."
}

create_assets_directories() {

    log "Criando diretórios dos artefatos..."

    mkdir -p "$BACKUP_LOCAL_DIR"
    mkdir -p "$APPLICATION_LOCAL_DIR"

}

download_database_backup() {

    log "Baixando backup do banco de dados..."

    echo "Origem : $BACKUP_DOWNLOAD_URL"
    echo "Destino: $BACKUP_LOCAL_FILE"

    if ! wget -O "$BACKUP_LOCAL_FILE" "$BACKUP_DOWNLOAD_URL"; then
        erro "Falha ao baixar o backup do banco."
    fi

    log "Download do backup concluído."

}

validate_database_backup() {

    if [ ! -s "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup inválido."
    fi

    echo
    echo "========================================"
    echo " Backup PostgreSQL"
    echo "========================================"
    echo "Arquivo : $BACKUP_LOCAL_FILE"
    echo "Tamanho : $(du -h "$BACKUP_LOCAL_FILE" | awk '{print $1}')"
    echo "========================================"
    echo

}

download_application_package() {

    log "Baixando pacote da aplicação..."

    echo "Origem : $APPLICATION_DOWNLOAD_URL"
    echo "Destino: $APPLICATION_LOCAL_FILE"

    if ! wget -O "$APPLICATION_LOCAL_FILE" "$APPLICATION_DOWNLOAD_URL"; then
        erro "Falha ao baixar o pacote da aplicação."
    fi

    log "Download da aplicação concluído."

}

validate_application_package() {

    if [ ! -s "$APPLICATION_LOCAL_FILE" ]; then
        erro "Pacote da aplicação inválido."
    fi

    echo
    echo "========================================"
    echo " Aplicação"
    echo "========================================"
    echo "Arquivo : $APPLICATION_LOCAL_FILE"
    echo "Tamanho : $(du -h "$APPLICATION_LOCAL_FILE" | awk '{print $1}')"
    echo "========================================"
    echo

}