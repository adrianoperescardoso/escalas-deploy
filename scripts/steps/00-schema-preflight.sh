#!/bin/bash
# Analise sem alteracoes no banco, executada antes de parar containers.
# A referencia atual abrange public.turnos.turnossigla; outras colunas
# so entram no controle quando forem adicionadas explicitamente.

get_turnos_sigla_type() {
    local env_file="$APP_DIR/.env"
    [ -f "$env_file" ] || erro "Configuracao do banco nao encontrada: $env_file"
    source "$env_file"

    local type
    if ! type=$(docker exec "$POSTGRES_CONTAINER_NAME" \
        psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Atqc \
        "SELECT data_type || ':' || character_maximum_length
           FROM information_schema.columns
          WHERE table_schema='public' AND table_name='turnos'
            AND column_name='turnossigla'"); then
        erro "Nao foi possivel consultar a estrutura do PostgreSQL existente."
    fi
    printf '%s' "$type"
}

preflight_schema_changes() {
    SCHEMA_MIGRATION_APPROVED=false

    # A primeira instalacao / restauracao sera validada depois do restore.
    if [ "$RESTORE_DATABASE" = true ]; then
        log "Restauracao selecionada: a estrutura do backup sera conferida apos o restore."
        return
    fi

    command -v docker >/dev/null || erro "Docker indisponivel para comparar o banco existente."
    local existing_type
    existing_type=$(get_turnos_sigla_type)

    echo
    echo "=============================================="
    echo " Comparacao estrutural - versao $RELEASE_VERSION"
    echo "=============================================="

    case "$existing_type" in
        "character varying:4")
            echo "public.turnos.turnossigla: varchar(4) - compativel."
            echo "Nenhuma correcao conhecida e necessaria."
            ;;
        "character varying:2")
            echo "Foram encontradas diferencas estruturais:"
            echo "  Tabela: public.turnos"
            echo "  Coluna: turnossigla"
            echo "  Atual: varchar(2)"
            echo "  Necessario: varchar(4)"
            echo "  Correcao: ampliar o limite, preservando os registros."
            echo
            if confirmar "Autoriza corrigir a estrutura do banco antes da atualizacao?"; then
                SCHEMA_MIGRATION_APPROVED=true
                log "Correcao estrutural autorizada."
            else
                erro "Atualizacao cancelada. A nova versao exige varchar(4) em public.turnos.turnossigla. O banco e a aplicacao existentes nao foram alterados."
            fi
            ;;
        *)
            erro "Estrutura inesperada em public.turnos.turnossigla: '${existing_type:-coluna inexistente}'. Atualizacao bloqueada para evitar alteracoes nao previstas."
            ;;
    esac
    echo "=============================================="
}
