#!/bin/bash
# ============================================================
# Escalas Deploy - comparacao integral de schemas PostgreSQL
# Referencia: Escalas.backup da release atual.
# Analise ocorre ANTES de cleanup, build ou alteracoes no banco.
# ============================================================

schema_cleanup() {
    if [ -n "$SCHEMA_TEMP_CONTAINER" ]; then
        docker rm -f "$SCHEMA_TEMP_CONTAINER" >/dev/null 2>&1 || true
    fi
    if [ -n "$SCHEMA_TEMP_DIR" ]; then
        rm -rf "$SCHEMA_TEMP_DIR"
    fi
}

schema_fail() {
    echo "ERRO: $*" >&2
    exit 1
}

schema_dump() {
    local container="$1" database="$2" output="$3" dump_user="$POSTGRES_USER"\n    [ "$container" != "$SCHEMA_TEMP_CONTAINER" ] || dump_user=postgres
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$container" pg_dump \
        --schema-only --no-owner --no-privileges \
        --exclude-table=public.escalas_schema_migrations -U "$dump_user" \
        -h 127.0.0.1 -p "$( [ "$container" = "$SCHEMA_TEMP_CONTAINER" ] && echo "$SCHEMA_PORT" || echo 5432 )" -d "$database" \
        > "$output" || schema_fail "Falha ao extrair o schema de $database."
    # Cabecalhos e versoes da ferramenta nao fazem parte da estrutura.
    sed -i '/^-- Dumped from database version /d; /^-- Dumped by pg_dump version /d; /^-- PostgreSQL database dump/d; /^-- PostgreSQL database dump complete/d; /^--$/d; /^\\\\restrict /d; /^\\\\unrestrict /d' "$output"
}

schema_reference_prepare() {
    SCHEMA_TEMP_DIR=$(mktemp -d /tmp/escalas-schema.XXXXXXXX)
    chmod 700 "$SCHEMA_TEMP_DIR"
    SCHEMA_TEMP_CONTAINER="escalas-schema-$BASHPID"
    SCHEMA_PORT=5433

    log "Baixando backup de referencia da release $BACKUP_RELEASE_VERSION..."
    wget -q -O "$SCHEMA_TEMP_DIR/Escalas.backup" "$BACKUP_DOWNLOAD_URL" \
        || schema_fail "Nao foi possivel baixar $BACKUP_DOWNLOAD_URL"
    [ -s "$SCHEMA_TEMP_DIR/Escalas.backup" ] || schema_fail "Backup de referencia vazio."

    # Compartilha somente o namespace de rede com o container existente.
    # Os dados e o processo do PostgreSQL temporario sao independentes.
    docker run -d --rm --name "$SCHEMA_TEMP_CONTAINER" \
        --network "container:$POSTGRES_CONTAINER_NAME" \
        -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -e POSTGRES_DB=escalas_schema_ref \
        postgres:17 -c port="$SCHEMA_PORT" -c listen_addresses=127.0.0.1 \
        >/dev/null || schema_fail "Falha ao iniciar PostgreSQL temporario."

    local attempt
    for attempt in $(seq 1 45); do
        if docker exec "$SCHEMA_TEMP_CONTAINER" \
            pg_isready -h 127.0.0.1 -p "$SCHEMA_PORT" -U postgres -d escalas_schema_ref >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    docker exec "$SCHEMA_TEMP_CONTAINER" \
        pg_isready -h 127.0.0.1 -p "$SCHEMA_PORT" -U postgres -d escalas_schema_ref \
        >/dev/null 2>&1 || schema_fail "PostgreSQL de referencia nao iniciou."

    log "Restaurando SOMENTE a estrutura do backup no banco temporario..."
    docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$SCHEMA_TEMP_CONTAINER" \
        pg_restore --exit-on-error --schema-only --no-owner --no-privileges \
        -h 127.0.0.1 -p "$SCHEMA_PORT" -U postgres -d escalas_schema_ref \
        < "$SCHEMA_TEMP_DIR/Escalas.backup" \
        || schema_fail "Restauracao do schema de referencia falhou."
}

schema_diff_plan() {
    local cli_image="escalas-pg-schema-diff:1.0.9"
    local from_dsn to_dsn temp_dsn
    from_dsn="host=127.0.0.1 port=5432 dbname=$POSTGRES_DB user=$POSTGRES_USER password=$POSTGRES_PASSWORD sslmode=disable"
    to_dsn="host=127.0.0.1 port=$SCHEMA_PORT dbname=escalas_schema_ref user=postgres password=$POSTGRES_PASSWORD sslmode=disable"
    temp_dsn="host=127.0.0.1 port=$SCHEMA_PORT dbname=postgres user=postgres password=$POSTGRES_PASSWORD sslmode=disable"

    docker image inspect "$cli_image" >/dev/null 2>&1 || \
        docker build -q -t "$cli_image" -f "$BASE_DIR/docker/schema-diff/Dockerfile" "$BASE_DIR/docker/schema-diff" \
        >/dev/null || schema_fail "Nao foi possivel preparar a ferramenta pg-schema-diff."

    # A validacao do plano usa bancos descartaveis no PostgreSQL temporario.
    docker run --rm --network "container:$POSTGRES_CONTAINER_NAME" "$cli_image" \
        plan --from-dsn "$from_dsn" --to-dsn "$to_dsn" --temp-db-dsn "$temp_dsn" \
        --output-format sql > "$SCHEMA_TEMP_DIR/migration.sql" \
        || schema_fail "Falha ao gerar plano completo de diferencas."

    # Dumps integrais capturam inclusive objetos nao suportados pelo motor
    # de migration. Nesse caso, falhar fechado em vez de prosseguir.
    schema_dump "$POSTGRES_CONTAINER_NAME" "$POSTGRES_DB" "$SCHEMA_TEMP_DIR/current.sql"
    schema_dump "$SCHEMA_TEMP_CONTAINER" escalas_schema_ref "$SCHEMA_TEMP_DIR/reference.sql"

    diff -u "$SCHEMA_TEMP_DIR/current.sql" "$SCHEMA_TEMP_DIR/reference.sql" \
        > "$SCHEMA_TEMP_DIR/schema.diff" || true
}


schema_validate_plan_in_sandbox() {
    # Verifica o plano em um clone APENAS estrutural do banco atual,
    # no mesmo PostgreSQL descartavel que contem o schema de referencia.
    # A validacao nao garante compatibilidade com dados reais.
    local scratch_db="escalas_schema_plan_test"
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$SCHEMA_TEMP_CONTAINER" \
        createdb -h 127.0.0.1 -p "$SCHEMA_PORT" -U postgres "$scratch_db" \
        || schema_fail "Falha ao criar banco de validacao temporario."
    docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$SCHEMA_TEMP_CONTAINER" \
        psql -X -v ON_ERROR_STOP=1 -1 -h 127.0.0.1 -p "$SCHEMA_PORT" \
        -U postgres -d "$scratch_db" < "$SCHEMA_TEMP_DIR/current.sql" \
        >/dev/null || schema_fail "Nao foi possivel reconstruir o schema atual no sandbox."

    docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$SCHEMA_TEMP_CONTAINER" \
        psql -X -v ON_ERROR_STOP=1 -1 -h 127.0.0.1 -p "$SCHEMA_PORT" \
        -U postgres -d "$scratch_db" < "$SCHEMA_TEMP_DIR/migration.sql" \
        >/dev/null || schema_fail "Plano SQL nao executou no sandbox. Revisao tecnica obrigatoria."

    schema_dump "$SCHEMA_TEMP_CONTAINER" "$scratch_db" "$SCHEMA_TEMP_DIR/validated.sql"
    if ! diff -q "$SCHEMA_TEMP_DIR/validated.sql" "$SCHEMA_TEMP_DIR/reference.sql" >/dev/null; then
        diff -u "$SCHEMA_TEMP_DIR/validated.sql" "$SCHEMA_TEMP_DIR/reference.sql" || true
        schema_fail "Plano nao reproduz o schema integral da release no sandbox. Atualizacao bloqueada."
    fi
    log "Plano validado no sandbox: schemas equivalentes apos aplicacao."
}

preflight_schema_changes() {
    SCHEMA_MIGRATION_APPROVED=false
    SCHEMA_HAS_DIFFERENCES=false
    SCHEMA_TEMP_DIR=""
    SCHEMA_TEMP_CONTAINER=""

    if [ "$RESTORE_DATABASE" = true ]; then
        log "Backup sera restaurado: comparacao do banco anterior nao se aplica."
        return
    fi

    source "$APP_DIR/.env"
    command -v docker >/dev/null 2>&1 || schema_fail "Docker nao encontrado."
    [ "$(docker inspect -f '{{.State.Running}}' "$POSTGRES_CONTAINER_NAME" 2>/dev/null)" = "true" ] \
        || schema_fail "Container do PostgreSQL deve estar ativo para comparar os schemas."

    # Garante remocao de container e arquivos temporarios tambem em recusas/erros.
    trap schema_cleanup EXIT
    schema_reference_prepare
    schema_diff_plan

    echo
    echo "======================================================"
    echo " Comparacao integral de schemas - $RELEASE_VERSION"
    echo "======================================================"
    echo "Referencia : $BACKUP_RELEASE_VERSION / $BACKUP_FILE_NAME"
    echo "Destino    : $POSTGRES_DB ($POSTGRES_CONTAINER_NAME)"
    echo

    if [ ! -s "$SCHEMA_TEMP_DIR/schema.diff" ]; then
        echo "Nenhuma diferenca de schema detectada."
        docker rm -f "$SCHEMA_TEMP_CONTAINER" >/dev/null 2>&1 || true
        SCHEMA_TEMP_CONTAINER=""
        return
    fi

    SCHEMA_HAS_DIFFERENCES=true
    echo "Diferencas estruturais detectadas (diff de pg_dump):"
    cat "$SCHEMA_TEMP_DIR/schema.diff"
    echo
    echo "SQL de migracao proposto:"
    cat "$SCHEMA_TEMP_DIR/migration.sql"

    # O plano deve cobrir o delta; se nao houver statements, ha
    # objetos nao tratados e nao podemos atualizar silenciosamente.
    if ! grep -Eq 'Statement [0-9]+' "$SCHEMA_TEMP_DIR/migration.sql"; then
        schema_fail "Diferencas encontradas, mas o motor nao gerou um plano. Revisao tecnica obrigatoria."
    fi

    # Em modo automatico somente comandos transacionais e nao destrutivos.
    # Operacoes perigosas precisam de tratamento tecnico versionado.
    if grep -Eiq '(^|[[:space:]])(DROP[[:space:]]+(TABLE|COLUMN|SCHEMA|TYPE)|TRUNCATE|CREATE[[:space:]]+INDEX[[:space:]]+CONCURRENTLY|DROP[[:space:]]+INDEX[[:space:]]+CONCURRENTLY|ALTER[[:space:]]+TYPE[[:space:]].*ADD[[:space:]]+VALUE)' "$SCHEMA_TEMP_DIR/migration.sql"; then
        schema_fail "Plano contem operacoes destrutivas ou nao transacionais. Revisao tecnica obrigatoria."
    fi

    schema_validate_plan_in_sandbox

    if confirmar "Deseja aplicar todas as correcoes estruturais exibidas?"; then
        SCHEMA_MIGRATION_APPROVED=true
        # O instalador recria o container PostgreSQL em seguida. O sandbox
        # deve ser removido antes disso; preservamos dumps/plano em disco.
        docker rm -f "$SCHEMA_TEMP_CONTAINER" >/dev/null 2>&1 || schema_fail "Falha ao encerrar banco temporario."
        SCHEMA_TEMP_CONTAINER=""
    else
        schema_fail "Atualizacao cancelada: o novo release exige as alteracoes exibidas. O banco existente nao foi alterado."
    fi
}
