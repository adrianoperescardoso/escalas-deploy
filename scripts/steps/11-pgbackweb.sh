#!/bin/bash

# Instala o PG Back Web 0.5.2 no mesmo projeto Compose da aplicação.
# O arquivo de credenciais é criado uma vez e preservado nas atualizações.

preflight_pgbackweb() {
    if [ -d /opt/pgbackweb ] && [ -f "$PG_BACK_WEB_ENV_FILE" ]; then
        erro "Foram encontradas duas instalações do PG Back Web. Identifique a instalação ativa antes de substituí-la."
    fi
    if [ -d /opt/pgbackweb ]; then
        echo
        echo "Foi encontrada uma instalação anterior do PG Back Web em /opt/pgbackweb."
        echo "Ao substituir, seus arquivos e, se estiver no PostgreSQL do EscalasPro,"
        echo "uma cópia do banco de configuração serão arquivados."
        echo "A nova interface terá outro usuário e senha."
        if confirmar "Deseja substituir a instalação anterior?"; then
            local services
            services=$(cd /opt/pgbackweb && docker compose config --services) \
                || erro "Não foi possível ler o Compose anterior. Instalação anterior preservada."
            grep -qx pgbackweb <<<"$services" \
                || erro "O Compose anterior não contém o serviço pgbackweb. Instalação anterior preservada."
            PG_BACK_WEB_REPLACE_LEGACY=true
        else
            erro "Instalação anterior preservada. Nenhuma alteração foi feita no PG Back Web."
        fi
    fi

    # Detecta também instalações anteriores cujo Compose não está mais no disco.
    if [ "${PG_BACK_WEB_REPLACE_LEGACY:-false}" != true ] \
        && [ ! -f "$PG_BACK_WEB_ENV_FILE" ] && command -v docker >/dev/null 2>&1 \
        && docker inspect "${APP_NAME}-postgres" >/dev/null 2>&1; then
        local previous_database
        previous_database=$(docker exec "${APP_NAME}-postgres" sh -c \
            'psql -X -At -U "$POSTGRES_USER" -d postgres -c "SELECT count(*) FROM pg_database WHERE datname = '\''pgbackweb'\''"' \
            2>/dev/null) || erro "Não foi possível verificar a existência do banco pgbackweb antes da instalação."
        [ "$previous_database" = 0 ] || erro "O banco pgbackweb já existe sem o arquivo $PG_BACK_WEB_ENV_FILE. Migre as credenciais antes de continuar."
    fi
}

replace_legacy_pgbackweb() {
    [ "${PG_BACK_WEB_REPLACE_LEGACY:-false}" = true ] || return 0

    # Confirma que será possível parar apenas o serviço antigo, sem parar
    # o PostgreSQL compartilhado com o EscalasPro.
    local archive metadata_exists

    archive="/opt/pgbackweb-antes-integracao-$(date +%Y%m%d-%H%M%S)"
    [ ! -e "$archive" ] || erro "Já existe o arquivo de preservação $archive."

    metadata_exists=$(docker exec "$POSTGRES_CONTAINER_NAME" sh -c \
        'psql -X -At -U "$POSTGRES_USER" -d postgres -c "SELECT count(*) FROM pg_database WHERE datname = '\''pgbackweb'\''"') \
        || erro "Não foi possível verificar o banco anterior do PG Back Web."

    if [ "$metadata_exists" = 1 ]; then
        # Antes de parar o serviço, testa o dump e guarda-o junto aos arquivos
        # antigos. O banco só será substituído após a cópia ser verificada.
        docker exec "$POSTGRES_CONTAINER_NAME" sh -c \
            'pg_dump -Fc -U "$POSTGRES_USER" -d pgbackweb' \
            > /opt/pgbackweb/pgbackweb-antes-integracao.dump \
            || erro "Falha ao preservar o banco pgbackweb. A instalação anterior foi mantida."
        chmod 600 /opt/pgbackweb/pgbackweb-antes-integracao.dump
        docker exec -i "$POSTGRES_CONTAINER_NAME" pg_restore -l \
            < /opt/pgbackweb/pgbackweb-antes-integracao.dump >/dev/null \
            || erro "O dump anterior não passou na verificação. A instalação anterior foi mantida."
    fi

    (cd /opt/pgbackweb && docker compose stop pgbackweb) \
        || erro "Não foi possível parar o PG Back Web anterior. Dados anteriores preservados."
    mv /opt/pgbackweb "$archive" \
        || erro "Não foi possível arquivar a instalação anterior. Banco anterior preservado."
    chmod 700 "$archive"
    [ -f "$archive/.env" ] && chmod 600 "$archive/.env"

    if [ "$metadata_exists" = 1 ]; then
        docker exec "$POSTGRES_CONTAINER_NAME" sh -c \
            'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE pgbackweb WITH (FORCE)"' >/dev/null \
            || erro "Não foi possível substituir o banco pgbackweb. Restaure-o a partir de $archive."
    fi

    # Usuários SQL antigos serão reaproveitados com novas senhas, sem imprimir
    # nenhuma delas. O diretório arquivado contém as credenciais anteriores.
    PBW_LEGACY_ARCHIVE="$archive"
    PBW_LEGACY_DATABASE_DUMP="$metadata_exists"
    log "Instalação anterior preservada em $archive."
}

prepare_pgbackweb() {
    step "Preparando banco e credenciais do PG Back Web"

    replace_legacy_pgbackweb
    source "$APP_DIR/.env"
    install -d -m 700 "$PG_BACK_WEB_DIR"
    install -d -m 700 "$PG_BACK_WEB_DIR/backups"

    if [ -n "${PBW_LEGACY_ARCHIVE:-}" ]; then
        local reference_file="${PG_BACK_WEB_DIR}/INSTALACAO_ANTERIOR.txt"
        {
            echo "Diretório da instalação anterior: $PBW_LEGACY_ARCHIVE"
            echo "Credenciais anteriores (se existirem): $PBW_LEGACY_ARCHIVE/.env"
            echo "Backups anteriores (se existirem): $PBW_LEGACY_ARCHIVE/backups"
            if [ "$PBW_LEGACY_DATABASE_DUMP" = 1 ]; then
                echo "Dump do banco pgbackweb anterior: $PBW_LEGACY_ARCHIVE/pgbackweb-antes-integracao.dump"
                echo "Para analisar os dados antigos, restaure esse dump em um banco de teste."
            else
                echo "Banco pgbackweb anterior não encontrado no PostgreSQL do EscalasPro."
                echo "Verifique a conexão antiga no arquivo de credenciais anterior."
            fi
        } > "$reference_file"
        chmod 600 "$reference_file"
        log "Caminhos da instalação anterior registrados em $reference_file."
    fi

    if [ ! -f "$PG_BACK_WEB_ENV_FILE" ]; then
        # Evita assumir o controle de uma instalação anterior sem suas credenciais.
        local existing
        existing=$(docker exec "$POSTGRES_CONTAINER_NAME" psql -X -At \
            -U "$POSTGRES_USER" -d postgres -c \
            "SELECT count(*) FROM pg_database WHERE datname = 'pgbackweb'" | tr -d '[:space:]')
        [ "$existing" = 0 ] || erro "O banco pgbackweb já existe, mas $PG_BACK_WEB_ENV_FILE não existe. Migre as credenciais antes de continuar."

        if [ "${PG_BACK_WEB_REPLACE_LEGACY:-false}" != true ]; then
            existing=$(docker exec "$POSTGRES_CONTAINER_NAME" psql -X -At \
                -U "$POSTGRES_USER" -d postgres -c \
                "SELECT count(*) FROM pg_roles WHERE rolname IN ('pgbackweb', 'escalas_backup')" | tr -d '[:space:]')
            [ "$existing" = 0 ] || erro "Há usuários de backup existentes sem o arquivo de credenciais. Migre-os antes de continuar."
        fi

        # A senha do administrador web também é gerada e guardada aqui.
        # Nunca imprima o conteúdo: init_logging grava toda a saída em arquivo.
        umask 077
        python3 - "$PG_BACK_WEB_ENV_FILE" <<'PY'
import secrets
import sys
from pathlib import Path

path = Path(sys.argv[1])
metadata_password = secrets.token_hex(24)
backup_password = secrets.token_hex(24)
admin_password = secrets.token_hex(24)
key = secrets.token_hex(32)
with path.open('x', encoding='utf-8') as file:
    file.write('PBW_METADATA_USER=pgbackweb\n')
    file.write(f'PBW_METADATA_PASSWORD={metadata_password}\n')
    file.write('ESCALAS_BACKUP_USER=escalas_backup\n')
    file.write(f'ESCALAS_BACKUP_PASSWORD={backup_password}\n')
    file.write('PBW_ADMIN_NAME="Administrador EscalasPro"\n')
    file.write('PBW_ADMIN_EMAIL=admin@escalaspro.example\n')
    file.write(f'PBW_ADMIN_PASSWORD={admin_password}\n')
    file.write(f'PBW_ENCRYPTION_KEY={key}\n')
    file.write('TZ=America/Porto_Velho\n')
    file.write('PBW_POSTGRES_CONN_STRING='
               f'postgresql://pgbackweb:{metadata_password}@postgres:5432/pgbackweb?sslmode=disable\n')
    file.write('ESCALAS_BACKUP_CONN_STRING='
               f'postgresql://escalas_backup:{backup_password}@postgres:5432/escalas?sslmode=disable\n')
PY
    fi

    chmod 600 "$PG_BACK_WEB_ENV_FILE"
    # shellcheck disable=SC1090
    source "$PG_BACK_WEB_ENV_FILE"

    [[ "$PBW_METADATA_PASSWORD" =~ ^[a-f0-9]{48}$ ]] || erro "Senha pgbackweb inválida no arquivo de credenciais."
    [[ "$ESCALAS_BACKUP_PASSWORD" =~ ^[a-f0-9]{48}$ ]] || erro "Senha escalas_backup inválida no arquivo de credenciais."
    [[ "$PBW_ENCRYPTION_KEY" =~ ^[a-f0-9]{64}$ ]] || erro "Chave de criptografia inválida no arquivo de credenciais."

    # A senha é enviada pelo stdin do psql, nunca pela linha de comando.
    docker exec -i "$POSTGRES_CONTAINER_NAME" sh -c \
        'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres' >/dev/null <<SQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pgbackweb') THEN
        CREATE ROLE pgbackweb LOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'escalas_backup') THEN
        CREATE ROLE escalas_backup LOGIN;
    END IF;
END
\$\$;
ALTER ROLE pgbackweb LOGIN PASSWORD '${PBW_METADATA_PASSWORD}';
ALTER ROLE escalas_backup LOGIN PASSWORD '${ESCALAS_BACKUP_PASSWORD}';
SQL

    local metadata_exists
    metadata_exists=$(docker exec "$POSTGRES_CONTAINER_NAME" psql -X -At \
        -U "$POSTGRES_USER" -d postgres -c \
        "SELECT count(*) FROM pg_database WHERE datname = 'pgbackweb'" | tr -d '[:space:]')
    if [ "$metadata_exists" = 0 ]; then
        docker exec -i "$POSTGRES_CONTAINER_NAME" sh -c \
            'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres' >/dev/null \
            <<<'CREATE DATABASE pgbackweb OWNER pgbackweb;'
    fi

    docker exec -i "$POSTGRES_CONTAINER_NAME" sh -c \
        'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null <<SQL
GRANT CONNECT ON DATABASE escalas TO escalas_backup;
GRANT USAGE ON SCHEMA gam, public TO escalas_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA gam, public TO escalas_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA gam, public TO escalas_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE "$POSTGRES_USER" IN SCHEMA gam, public GRANT SELECT ON TABLES TO escalas_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE "$POSTGRES_USER" IN SCHEMA gam, public GRANT SELECT ON SEQUENCES TO escalas_backup;
SQL

    log "Banco pgbackweb e usuário de leitura do EscalasPro preparados. Credenciais: $PG_BACK_WEB_ENV_FILE"
}

configure_pgbackweb() {
    step "Configurando usuário e backup no PG Back Web"

    source "$APP_DIR/.env"
    local local_url="http://${PBW_BIND_IP:-127.0.0.1}:8085"
    local attempt
    for attempt in $(seq 1 30); do
        if curl -fsS --max-time 3 "$local_url/api/v1/health" >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    curl -fsS --max-time 3 "$local_url/api/v1/health" >/dev/null \
        || erro "PG Back Web não respondeu em $local_url."

    python3 "$BASE_DIR/scripts/steps/pgbackweb-provision.py" \
        "$PG_BACK_WEB_ENV_FILE" "$POSTGRES_CONTAINER_NAME" "$POSTGRES_USER" "$local_url" \
        || erro "Não foi possível configurar o PG Back Web. Credenciais preservadas em $PG_BACK_WEB_ENV_FILE."

    # Publica a interface na rede da VM somente após a criação do usuário.
    if ! grep -q '^PBW_BIND_IP=' "$APP_DIR/.env"; then
        local host_ip
        host_ip=$(get_host_ip)
        [ -n "$host_ip" ] || erro "Não foi possível identificar o IP da VM para publicar o PG Back Web."
        update_env_variable PBW_BIND_IP "$host_ip"
        cd "$APP_DIR"
        docker compose -p "$PROJECT_NAME" up -d --no-deps pgbackweb
    fi

    sucesso "PG Back Web configurado. Credenciais em $PG_BACK_WEB_ENV_FILE."
}
