#!/bin/bash

# ============================================================
# Escalas Deploy - Download de Artefatos
# ============================================================
#
# Responsável por disponibilizar todos os arquivos necessários
# para a instalação da aplicação.
#
# Esta etapa:
# - cria os diretórios de armazenamento;
# - baixa o backup do PostgreSQL;
# - baixa o pacote da aplicação;
# - valida a integridade básica dos arquivos.
#
# Caso os arquivos já existam localmente e não estejam vazios,
# o download é ignorado para reduzir o tempo de instalação.
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

# ------------------------------------------------------------
# Cria os diretórios utilizados para armazenar os artefatos.
# ------------------------------------------------------------
create_assets_directories() {

    log "Criando diretórios dos artefatos..."

    mkdir -p "$BACKUP_LOCAL_DIR"
    mkdir -p "$APPLICATION_ASSETS_DIR"
}

# ------------------------------------------------------------
# Baixa o backup do PostgreSQL.
# ------------------------------------------------------------
download_database_backup() {

    log "Verificando backup do banco de dados..."

    echo "Origem : $BACKUP_DOWNLOAD_URL"
    echo "Destino: $BACKUP_LOCAL_FILE"

    if [ -s "$BACKUP_LOCAL_FILE" ]; then
        log "Backup já existe localmente. Download ignorado."
        return
    fi

    log "Baixando backup do banco de dados..."

    wget -O "$BACKUP_LOCAL_FILE" "$BACKUP_DOWNLOAD_URL"         || erro "Falha ao baixar o backup do banco."

    log "Download do backup concluído."
}

# ------------------------------------------------------------
# Valida o arquivo de backup.
# ------------------------------------------------------------
validate_database_backup() {

    log "Validando backup PostgreSQL..."

    [ -f "$BACKUP_LOCAL_FILE" ] || erro "Arquivo de backup não encontrado: $BACKUP_LOCAL_FILE"
    [ -s "$BACKUP_LOCAL_FILE" ] || erro "Arquivo de backup inválido ou vazio: $BACKUP_LOCAL_FILE"

    echo
    echo "========================================"
    echo " Backup PostgreSQL"
    echo "========================================"
    echo "Arquivo : $BACKUP_LOCAL_FILE"
    echo "Tamanho : $(du -h "$BACKUP_LOCAL_FILE" | awk '{print $1}')"
    echo "========================================"
    echo
}

# ------------------------------------------------------------
# Baixa o pacote da aplicação.
# ------------------------------------------------------------
download_application_package() {

    log "Verificando pacote da aplicação..."

    echo "Origem : $APPLICATION_DOWNLOAD_URL"
    echo "Destino: $APPLICATION_LOCAL_FILE"

    if [ -s "$APPLICATION_LOCAL_FILE" ]; then
        log "Pacote da aplicação já existe localmente. Download ignorado."
        return
    fi

    log "Baixando pacote da aplicação..."

    wget -O "$APPLICATION_LOCAL_FILE" "$APPLICATION_DOWNLOAD_URL"         || erro "Falha ao baixar o pacote da aplicação."

    log "Download da aplicação concluído."
}

# ------------------------------------------------------------
# Valida o pacote da aplicação.
# ------------------------------------------------------------
validate_application_package() {

    log "Validando pacote da aplicação..."

    [ -f "$APPLICATION_LOCAL_FILE" ] || erro "Pacote da aplicação não encontrado: $APPLICATION_LOCAL_FILE"
    [ -s "$APPLICATION_LOCAL_FILE" ] || erro "Pacote da aplicação inválido ou vazio: $APPLICATION_LOCAL_FILE"

    echo
    echo "========================================"
    echo " Pacote da aplicação"
    echo "========================================"
    echo "Arquivo : $APPLICATION_LOCAL_FILE"
    echo "Tamanho : $(du -h "$APPLICATION_LOCAL_FILE" | awk '{print $1}')"
    echo "========================================"
    echo
}
