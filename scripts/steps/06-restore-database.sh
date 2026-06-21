#!/bin/bash

# ============================================================
# Objetivo:
# Restaurar o backup do banco de dados PostgreSQL.
#
# Esta etapa:
# - valida se o arquivo de backup existe;
# - executa o pg_restore dentro do container PostgreSQL;
# - valida se tabelas foram criadas no banco;
# - consulta a chave de conexão do GAM no banco restaurado;
# - grava a chave GX_CONNECTION_GAM_KEY no arquivo .env.
# ============================================================

restore_database() {
    step "Restaurando banco de dados"

    validate_backup_file
    execute_database_restore
    validate_database_restore
    configure_gam_connection_key

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
    source "$APP_DIR/.env"

    log "Executando restore do banco ${POSTGRES_DB}..."

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
    source "$APP_DIR/.env"

    log "Validando restore do banco..."

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

configure_gam_connection_key() {
    source "$APP_DIR/.env"

    log "Consultando chave de conexão do GAM..."

    local GAM_CONNECTION_KEY

    GAM_CONNECTION_KEY=$(docker exec "$POSTGRES_CONTAINER_NAME" \
        psql \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        -tAc "SELECT s.sysconncfgkey FROM gam.sysconnectionconfig s LIMIT 1;" \
        | tr -d '[:space:]')

    if [ -z "$GAM_CONNECTION_KEY" ]; then
        erro "Não foi possível localizar a chave do GAM em gam.sysconnectionconfig."
    fi

    update_env_variable "GX_CONNECTION_GAM_KEY" "$GAM_CONNECTION_KEY"

    echo
    echo "========================================"
    echo " Chave GAM configurada"
    echo "========================================"
    echo "Tabela : gam.sysconnectionconfig"
    echo "Campo  : sysconncfgkey"
    echo "Chave  : $GAM_CONNECTION_KEY"
    echo "Env    : GX_CONNECTION_GAM_KEY"
    echo "========================================"
    echo
}

update_env_variable() {
    local KEY="$1"
    local VALUE="$2"
    local ENV_FILE="$APP_DIR/.env"

    if [ ! -f "$ENV_FILE" ]; then
        erro "Arquivo .env não encontrado: $ENV_FILE"
    fi

    if grep -q "^${KEY}=" "$ENV_FILE"; then
        sed -i "s#^${KEY}=.*#${KEY}=${VALUE}#g" "$ENV_FILE"
    else
        echo "${KEY}=${VALUE}" >> "$ENV_FILE"
    fi
}