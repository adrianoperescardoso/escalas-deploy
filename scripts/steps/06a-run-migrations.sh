#!/bin/bash
# Aplica plano gerado contra o backup real da release, nunca SQL fixo.
run_database_migrations() {
    step "Aplicando migrations de schema"
    if [ "$RESTORE_DATABASE" = true ]; then
        log "Banco restaurado do backup de referencia. Nenhuma migration adicional."
        return
    fi
    if [ "$SCHEMA_HAS_DIFFERENCES" != true ]; then
        log "Schema ja compativel."
        return
    fi
    [ "$SCHEMA_MIGRATION_APPROVED" = true ] || erro "Migracao nao autorizada."
    [ -s "$SCHEMA_TEMP_DIR/migration.sql" ] || erro "Plano SQL vazio."

    source "$APP_DIR/.env"
    # Preserva a proposta aprovada para auditoria e diagnostico.
    local audit_dir="$APP_DIR/logs/migrations"
    local audit_id
    audit_id="$(date +%Y%m%d-%H%M%S)-${RELEASE_VERSION}"
    mkdir -p "$audit_dir"
    cp "$SCHEMA_TEMP_DIR/migration.sql" "$audit_dir/$audit_id.sql"
    cp "$SCHEMA_TEMP_DIR/schema.diff" "$audit_dir/$audit_id.diff"
    chmod 600 "$audit_dir/$audit_id.sql" "$audit_dir/$audit_id.diff"
    log "Plano e diferencas arquivados em: $audit_dir/$audit_id"
    log "Executando plano aprovado em transacao unica..."
    if ! docker exec -i "$POSTGRES_CONTAINER_NAME" psql -X -v ON_ERROR_STOP=1 \
        -1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        < "$SCHEMA_TEMP_DIR/migration.sql"; then
        erro "Falha ao aplicar plano. Transacao revertida. Atualizacao interrompida."
    fi
    # Compara novamente todo o schema, sem depender do sandbox removido.
    schema_dump "$POSTGRES_CONTAINER_NAME" "$POSTGRES_DB" "$SCHEMA_TEMP_DIR/current-after.sql"
    schema_normalize "$SCHEMA_TEMP_DIR/current-after.sql" "$SCHEMA_TEMP_DIR/current-after.normalized.sql"
    diff -u "$SCHEMA_TEMP_DIR/current-after.normalized.sql" "$SCHEMA_TEMP_DIR/reference.normalized.sql" > "$SCHEMA_TEMP_DIR/schema.diff" || true
    if [ -s "$SCHEMA_TEMP_DIR/schema.diff" ]; then
        echo "Ainda ha diferencas estruturais:"
        cat "$SCHEMA_TEMP_DIR/schema.diff"
        erro "A estrutura nao ficou identica a referencia. Instalacao interrompida."
    fi
    sucesso "Banco validado contra o schema integral da release."
}
