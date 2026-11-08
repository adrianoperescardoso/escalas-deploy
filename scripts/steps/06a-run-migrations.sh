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
    log "Executando plano aprovado em transacao unica..."
    if ! docker exec -i "$POSTGRES_CONTAINER_NAME" psql -X -v ON_ERROR_STOP=1 \
        -1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        < "$SCHEMA_TEMP_DIR/migration.sql"; then
        erro "Falha ao aplicar plano. Transacao revertida. Atualizacao interrompida."
    fi
    # Regera a comparacao apos a aplicacao para encontrar diffs remanescentes.
    schema_diff_plan
    if [ -s "$SCHEMA_TEMP_DIR/schema.diff" ]; then
        echo "Ainda ha diferencas estruturais:"
        cat "$SCHEMA_TEMP_DIR/schema.diff"
        erro "A estrutura nao ficou identica a referencia. Instalacao interrompida."
    fi
    sucesso "Banco validado contra o schema integral da release."
}
