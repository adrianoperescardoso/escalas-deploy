#!/bin/bash

# ============================================================
# Objetivo:
# Baixar os artefatos necessários para a instalação.
#
# Esta etapa:
# - cria os diretórios locais de artefatos;
# - baixa o backup PostgreSQL, se ainda não existir;
# - baixa o pacote da aplicação, se ainda não existir;
# - valida os arquivos disponíveis localmente.
#
# Observação:
# Se os arquivos já existirem e não estiverem vazios, o download
# é ignorado. Isso evita baixar novamente arquivos grandes em
# execuções repetidas do instalador.
# ============================================================

download_assets() {
    step "Baixando artefatos da instalação"

    create_assets_directories

    download_database_backup
    validate_database_backup

    download_application_package
    validate_application_package

    sucesso "Artefatos disponíveis com sucesso."
}

create_assets_directories() {

    log "Criando diretórios dos artefatos..."

    mkdir -p "$BACKUP_LOCAL_DIR"
    mkdir -p "$APPLICATION_ASSETS_DIR"

}

download_database_backup() {

    log "Verificando backup do banco de dados..."

    echo "Origem : $BACKUP_DOWNLOAD_URL"
    echo "Destino: $BACKUP_LOCAL_FILE"

    if [ -s "$BACKUP_LOCAL_FILE" ]; then
        log "Backup já existe localmente. Download ignorado."
        return
    fi

    log "Baixando backup do banco de dados..."

    if ! wget -O "$BACKUP_LOCAL_FILE" "$BACKUP_DOWNLOAD_URL"; then
        erro "Falha ao baixar o backup do banco."
    fi

    log "Download do backup concluído."

}

validate_database_backup() {

    log "Validando backup PostgreSQL..."

    if [ ! -f "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup não encontrado: $BACKUP_LOCAL_FILE"
    fi

    if [ ! -s "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup inválido ou vazio: $BACKUP_LOCAL_FILE"
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

    log "Verificando pacote da aplicação..."

    echo "Origem : $APPLICATION_DOWNLOAD_URL"
    echo "Destino: $APPLICATION_LOCAL_FILE"

    if [ -s "$APPLICATION_LOCAL_FILE" ]; then
        log "Pacote da aplicação já existe localmente. Download ignorado."
        return
    fi

    log "Baixando pacote da aplicação..."

    if ! wget -O "$APPLICATION_LOCAL_FILE" "$APPLICATION_DOWNLOAD_URL"; then
        erro "Falha ao baixar o pacote da aplicação."
    fi

    log "Download da aplicação concluído."

}

validate_application_package() {

    log "Validando pacote da aplicação..."

    if [ ! -f "$APPLICATION_LOCAL_FILE" ]; then
        erro "Pacote da aplicação não encontrado: $APPLICATION_LOCAL_FILE"
    fi

    if [ ! -s "$APPLICATION_LOCAL_FILE" ]; then
        erro "Pacote da aplicação inválido ou vazio: $APPLICATION_LOCAL_FILE"
    fi

    echo
    echo "========================================"
    echo " Pacote da aplicação"
    echo "========================================"
    echo "Arquivo : $APPLICATION_LOCAL_FILE"
    echo "Tamanho : $(du -h "$APPLICATION_LOCAL_FILE" | awk '{print $1}')"
    echo "========================================"
    echo

}