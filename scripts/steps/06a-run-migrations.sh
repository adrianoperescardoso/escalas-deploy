#!/bin/bash

# ============================================================
# Escalas Deploy - Migrations SQL versionadas
# ============================================================
#
# Executa, em ordem, arquivos .sql em migrations/ no banco
# existente ou restaurado. Cada arquivo e seu checksum ficam
# registrados em public.escalas_schema_migrations.
#
# Cada migration deve conter SQL transacional (sem BEGIN/COMMIT).
# Se um comando falhar, a transacao e revertida e o instalador
# para antes de iniciar a nova aplicacao.
# ============================================================

run_database_migrations() {
    step "Aplicando migrations do banco de dados"

    local migrations_dir="$BASE_DIR/migrations"
    local migration_file migration_name checksum previous_checksum applied_count=0
    local -a migration_files=()

    [ -d "$migrations_dir" ] || erro "Diretorio de migrations nao encontrado: $migrations_dir"

    # Carrega usuario, container e nome do banco usados nesta instalacao.
    source "$APP_DIR/.env"

    if ! docker exec "$POSTGRES_CONTAINER_NAME" psql \
        -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        -c 'CREATE TABLE IF NOT EXISTS public.escalas_schema_migrations (
                version varchar(255) PRIMARY KEY,
                checksum char(64) NOT NULL,
                applied_at timestamptz NOT NULL DEFAULT now()
            );' >/dev/null; then
        erro "Nao foi possivel criar/verificar o historico de migrations."
    fi

    shopt -s nullglob
    migration_files=("$migrations_dir"/*.sql)
    shopt -u nullglob

    for migration_file in "${migration_files[@]}"; do
        migration_name="${migration_file##*/}"

        # Nome restrito para evitar interpolacao insegura em SQL.
        if [[ ! "$migration_name" =~ ^[0-9]{4}_[a-z0-9_]+\.sql$ ]]; then
            erro "Nome invalido de migration: $migration_name"
        fi

        checksum=$(sha256sum "$migration_file" | awk '{print $1}')

        if ! previous_checksum=$(docker exec "$POSTGRES_CONTAINER_NAME" \
            psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
            -Atqc "SELECT checksum FROM public.escalas_schema_migrations WHERE version = '$migration_name'"); then
            erro "Falha ao consultar historico da migration $migration_name."
        fi

        if [ -n "$previous_checksum" ]; then
            if [ "$previous_checksum" != "$checksum" ]; then
                erro "Migration ja aplicada foi modificada: $migration_name. Nao altere arquivos versionados."
            fi
            log "Migration ja aplicada: $migration_name"
            continue
        fi

        log "Aplicando migration: $migration_name"

        # BEGIN/COMMIT explicitos tambem funcionam com SQL via stdin.
        # ON_ERROR_STOP interrompe psql; conexao encerrada reverte a transacao.
        # Migration e registro no historico sao confirmados juntos.
        if ! {
            printf 'BEGIN;\n'
            cat "$migration_file"
            printf '\nINSERT INTO public.escalas_schema_migrations (version, checksum) VALUES (\047%s\047, \047%s\047);\n' "$migration_name" "$checksum"
            printf 'COMMIT;\n'
        } | docker exec -i "$POSTGRES_CONTAINER_NAME" psql \
            -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
            erro "Falha na migration $migration_name. Transacao revertida; instalacao interrompida."
        fi

        applied_count=$((applied_count + 1))
        log "Migration aplicada: $migration_name"
    done

    sucesso "Migrations verificadas. Novas migrations aplicadas: $applied_count."
}
