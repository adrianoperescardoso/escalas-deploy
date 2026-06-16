#!/bin/bash

# ============================================================
# Objetivo:
# Baixar os artefatos necessários para a instalação.
#
# Nesta etapa:
# - cria o diretório local de backup;
# - baixa o arquivo Escalas.backup da Release do GitHub;
# - valida se o arquivo foi baixado corretamente.
#
# Esta etapa NÃO executa restore do banco.
# ============================================================

download_assets() {
    step "Baixando artefatos da instalação"

    create_backup_directory
    download_database_backup
    validate_database_backup

    sucesso "Artefatos baixados com sucesso."
}

create_backup_directory() {
    log "Criando diretório local de backup..."

    mkdir -p "$BACKUP_LOCAL_DIR"

    if [ ! -d "$BACKUP_LOCAL_DIR" ]; then
        erro "Não foi possível criar o diretório de backup: $BACKUP_LOCAL_DIR"
    fi

    log "Diretório de backup disponível em: $BACKUP_LOCAL_DIR"
}

download_database_backup() {
    log "Baixando backup do banco de dados..."

    echo "Origem : $BACKUP_DOWNLOAD_URL"
    echo "Destino: $BACKUP_LOCAL_FILE"

    if ! wget -O "$BACKUP_LOCAL_FILE" "$BACKUP_DOWNLOAD_URL"; then
        erro "Falha ao baixar o backup do banco de dados."
    fi

    log "Download do backup concluído."
}

validate_database_backup() {
    log "Validando arquivo de backup..."

    if [ ! -f "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup não encontrado após o download: $BACKUP_LOCAL_FILE"
    fi

    if [ ! -s "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup está vazio: $BACKUP_LOCAL_FILE"
    fi

    echo
    echo "========================================"
    echo " Backup disponível"
    echo "========================================"
    echo "Arquivo : $BACKUP_LOCAL_FILE"
    echo "Tamanho : $(du -h "$BACKUP_LOCAL_FILE" | awk '{print $1}')"
    echo "========================================"
    echo
}