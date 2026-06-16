#!/bin/bash

# ============================================================
# Objetivo:
# Restaurar o backup do banco de dados PostgreSQL.
#
# Esta etapa:
# - valida se o arquivo de backup existe;
# - executa o pg_restore dentro do container PostgreSQL;
# - valida se tabelas foram criadas no banco.
# ============================================================

restore_database() {
    step "Restaurando banco de dados"

    validate_backup_file
    execute_database_restore
    validate_database_restore

    sucesso "Restore do banco concluído com sucesso."
}

validate_backup_file() {
    log "Validando arquivo de backup..."

    if [ ! -f "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup não encontrado: $BACKUP_LOCAL_FILE"
    fi

    if [ ! -s "$BACKUP_LOCAL_FILE" ]; then
        erro "Arquivo de backup está vazio: $BACKUP_LOCAL_FILE"
    fi

    log "Backup encontrado: $BACKUP_LOCAL_FILE"
}

execute_database_restore() {
    log "Executando restore do banco ${POSTGRES_DB}..."

    source "$APP_DIR/.env"

    docker exec -i "$POSTGRES_CONTAINER_NAME" \
        pg_restore \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        < "$BACKUP_LOCAL_FILE"

    log "Comando pg_restore executado."
}

validate_database_restore() {
    log "Validando restore do banco..."

    source "$APP_DIR/.env"

    local TABLE_COUNT

    TABLE_COUNT=$(docker exec "$POSTGRES_CONTAINER_NAME" \
        psql \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

    if [ "$TABLE_COUNT" -le 0 ]; then
        erro "Restore executado, mas nenhuma tabela foi encontrada no schema public."
    fi

    echo
    echo "========================================"
    echo " Restore validado"
    echo "========================================"
    echo "Banco   : $POSTGRES_DB"
    echo "Tabelas : $TABLE_COUNT"
    echo "Backup  : $BACKUP_LOCAL_FILE"
    echo "========================================"
    echo
}