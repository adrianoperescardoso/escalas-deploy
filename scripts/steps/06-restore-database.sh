#!/bin/bash

# ============================================================
# Escalas Deploy - Restauração do Banco de Dados
# ============================================================
#
# Responsável por restaurar o banco PostgreSQL da aplicação.
#
# Esta etapa:
# - valida o arquivo de backup;
# - executa o pg_restore;
# - valida a restauração;
# - obtém a chave de conexão do GAM;
# - grava a chave no arquivo .env.
# ============================================================

restore_database() {

    step "Restaurando banco de dados"

    validate_backup_file
    execute_database_restore
    validate_database_restore
    configure_gam_connection_key

    sucesso "Restore do banco concluído com sucesso."
}

# ------------------------------------------------------------
# Valida o arquivo de backup.
# ------------------------------------------------------------
validate_backup_file() {

    log "Validando arquivo de backup..."

    [ -f "$BACKUP_LOCAL_FILE" ] || erro "Arquivo de backup não encontrado: $BACKUP_LOCAL_FILE"
    [ -s "$BACKUP_LOCAL_FILE" ] || erro "Arquivo de backup está vazio: $BACKUP_LOCAL_FILE"

    log "Backup encontrado: $BACKUP_LOCAL_FILE"
}

# ------------------------------------------------------------
# Executa a restauração utilizando pg_restore.
# ------------------------------------------------------------
execute_database_restore() {

    source "$APP_DIR/.env"

    log "Executando restore do banco ${POSTGRES_DB}..."

    docker exec -i "$POSTGRES_CONTAINER_NAME"         pg_restore         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         --clean         --if-exists         --no-owner         --no-privileges         < "$BACKUP_LOCAL_FILE"

    log "Restore concluído."
}

# ------------------------------------------------------------
# Valida se a restauração criou as tabelas esperadas.
# ------------------------------------------------------------
validate_database_restore() {

    source "$APP_DIR/.env"

    log "Validando restore do banco..."

    local TABLE_COUNT

    TABLE_COUNT=$(docker exec "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

    [ "$TABLE_COUNT" -gt 0 ] || erro "Restore executado, mas nenhuma tabela foi encontrada no schema public."

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

# ------------------------------------------------------------
# Obtém a chave de conexão do GAM e grava no .env.
# ------------------------------------------------------------
configure_gam_connection_key() {

    source "$APP_DIR/.env"

    log "Consultando chave de conexão do GAM..."

    local GAM_CONNECTION_KEY

    GAM_CONNECTION_KEY=$(docker exec "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -tAc "SELECT s.sysconncfgkey FROM gam.sysconnectionconfig s LIMIT 1;"         | tr -d '[:space:]')

    [ -n "$GAM_CONNECTION_KEY" ] || erro "Não foi possível localizar a chave do GAM em gam.sysconnectionconfig."

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

# ------------------------------------------------------------
# Atualiza ou adiciona uma variável no arquivo .env.
# ------------------------------------------------------------
update_env_variable() {

    local KEY="$1"
    local VALUE="$2"
    local ENV_FILE="$APP_DIR/.env"

    [ -f "$ENV_FILE" ] || erro "Arquivo .env não encontrado: $ENV_FILE"

    if grep -q "^${KEY}=" "$ENV_FILE"; then
        sed -i "s#^${KEY}=.*#${KEY}=${VALUE}#g" "$ENV_FILE"
    else
        echo "${KEY}=${VALUE}" >> "$ENV_FILE"
    fi
}
