#!/bin/bash
# Validacao da estrutura e aplicacao da migration conhecida.
# Nenhum ALTER e executado sem a autorizacao no preflight.
run_database_migrations() {
    step "Validando compatibilidade do banco de dados"

    local actual migration_name="0001_ampliar_sigla_turnos.sql"
    local sql="$BASE_DIR/migrations/$migration_name"
    local checksum old_checksum
    source "$APP_DIR/.env"

    [ -f "$sql" ] || erro "Migration nao encontrada: $sql"
    actual=$(get_turnos_sigla_type)

    case "$actual" in
        "character varying:4")
            log "Estrutura compativel: public.turnos.turnossigla varchar(4)."
            return
            ;;
        "character varying:2")
            if [ "${SCHEMA_MIGRATION_APPROVED:-false}" != true ]; then
                erro "Correcao necessaria mas nao autorizada. Atualizacao interrompida."
            fi
            ;;
        *)
            erro "Estrutura inesperada: '${actual:-coluna inexistente}'. Nao e seguro prosseguir."
            ;;
    esac

    # A tabela de historico e criada apenas apos a aprovacao.
    if ! docker exec "$POSTGRES_CONTAINER_NAME" psql -X -v ON_ERROR_STOP=1 \
        -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c \
        'CREATE TABLE IF NOT EXISTS public.escalas_schema_migrations (
             version varchar(255) PRIMARY KEY,
             checksum char(64) NOT NULL,
             applied_at timestamptz NOT NULL DEFAULT now()
         );' >/dev/null; then
        erro "Falha ao preparar historico de migrations."
    fi

    checksum=$(sha256sum "$sql" | awk '{print $1}')
    if ! old_checksum=$(docker exec "$POSTGRES_CONTAINER_NAME" \
        psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        -Atqc "SELECT checksum FROM public.escalas_schema_migrations WHERE version='$migration_name'"); then
        erro "Falha ao consultar historico de migrations."
    fi
    if [ -n "$old_checksum" ]; then
        erro "Migration consta como aplicada mas a coluna ainda e varchar(2); verificacao manual necessaria."
    fi

    log "Aplicando alteracao autorizada: public.turnos.turnossigla varchar(2) -> varchar(4)"
    if ! {
        printf 'BEGIN;\n'
        cat "$sql"
        printf "\nINSERT INTO public.escalas_schema_migrations (version, checksum) VALUES ('%s', '%s');\n" "$migration_name" "$checksum"
        printf 'COMMIT;\n'
    } | docker exec -i "$POSTGRES_CONTAINER_NAME" psql -X -v ON_ERROR_STOP=1 \
        -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
        erro "Migration falhou. Transacao revertida. Atualizacao interrompida."
    fi

    actual=$(get_turnos_sigla_type)
    [ "$actual" = "character varying:4" ] || erro "Validacao pos-migration falhou: $actual"
    sucesso "Estrutura atualizada para varchar(4) e validada."
}
