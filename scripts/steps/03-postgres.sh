#!/bin/bash

# ============================================================
# Objetivo:
# Configurar e inicializar o PostgreSQL da aplicação.
#
# Nesta etapa:
# - gera o arquivo .env usado pelo Docker Compose;
# - grava as variáveis do PostgreSQL;
# - grava as variáveis GeneXus GX_CONNECTION_*;
# - gera um docker-compose.yml temporário apenas com PostgreSQL;
# - baixa a imagem do PostgreSQL;
# - inicia o container do banco;
# - aguarda o banco ficar disponível;
# - valida a conexão básica.
#
# Observação importante:
# O mesmo arquivo .env será usado depois pelo serviço da aplicação.
# O Docker Compose injeta essas variáveis dentro do container,
# e o Dockerfile usa envsubst para substituir os placeholders
# ${GX_CONNECTION_*} dentro do appsettings.json.
# ============================================================

generate_env_file() {
    step "Gerando arquivo .env"

    ENV_FILE="$APP_DIR/.env"

    if [ -f "$ENV_FILE" ]; then
        log "Arquivo .env já existe. Mantendo configuração atual."
        return
    fi

    log "Criando arquivo .env..."

    cat > "$ENV_FILE" <<EOF
APP_NAME=${APP_NAME}
PROJECT_NAME=${PROJECT_NAME}

POSTGRES_IMAGE=postgres:17
POSTGRES_CONTAINER_NAME=${APP_NAME}-postgres
POSTGRES_PORT=5432

POSTGRES_DB=escalas
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

APP_PORT=8080
APP_IMAGE=${APPLICATION_IMAGE}

# ==========================================================
# Variáveis de conexão da aplicação GeneXus
# ==========================================================
# Essas variáveis serão carregadas pelo Docker Compose no
# container da aplicação.
#
# Durante a inicialização do container, o comando envsubst
# trocará os placeholders do appsettings.json por estes valores.
# ==========================================================

GX_CONNECTION_DEFAULT_DB=escalas
GX_CONNECTION_DEFAULT_DATASOURCE=postgres
GX_CONNECTION_DEFAULT_USER=postgres
GX_CONNECTION_DEFAULT_PASSWORD=postgres
GX_CONNECTION_DEFAULT_PORT=5432

GX_CONNECTION_GAM_DB=escalas
GX_CONNECTION_GAM_DATASOURCE=postgres
GX_CONNECTION_GAM_USER=postgres
GX_CONNECTION_GAM_PASSWORD=postgres
GX_CONNECTION_GAM_PORT=5432
EOF

    chmod 600 "$ENV_FILE"

    log "Arquivo .env criado."
}

generate_docker_compose_postgres() {
    step "Gerando docker-compose.yml"

    COMPOSE_FILE="$APP_DIR/docker-compose.yml"

    log "Criando docker-compose.yml..."

    cat > "$COMPOSE_FILE" <<'EOF'
name: escalas

services:

  postgres:
    image: ${POSTGRES_IMAGE}
    container_name: ${POSTGRES_CONTAINER_NAME}
    restart: unless-stopped

    env_file:
      - .env

    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

    ports:
      - "${POSTGRES_PORT}:5432"

    volumes:
      - ./postgres/data:/var/lib/postgresql/data

    healthcheck:
      test: ["CMD-SHELL","pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 10
EOF

    chmod 644 "$COMPOSE_FILE"

    log "docker-compose.yml criado."
}

pull_postgres_image() {
    step "Baixando imagem PostgreSQL"

    cd "$APP_DIR"

    source "$APP_DIR/.env"

    log "Baixando imagem: ${POSTGRES_IMAGE}"

    docker compose -p "$PROJECT_NAME" pull postgres
}

start_postgres() {
    step "Inicializando PostgreSQL"

    cd "$APP_DIR"

    source "$APP_DIR/.env"

    log "Subindo container PostgreSQL..."

    if ! docker compose -p "$PROJECT_NAME" up -d --force-recreate postgres; then
        erro "Não foi possível iniciar o PostgreSQL. Verifique se a porta ${POSTGRES_PORT} já está em uso."
    fi
}

wait_postgres() {
    step "Aguardando PostgreSQL ficar disponível"

    source "$APP_DIR/.env"

    local tentativas=30
    local contador=1

    while [ "$contador" -le "$tentativas" ]; do
        if docker exec \
            "$POSTGRES_CONTAINER_NAME" \
            pg_isready \
            -U "$POSTGRES_USER" \
            -d "$POSTGRES_DB" >/dev/null 2>&1; then

            log "PostgreSQL disponível."
            return
        fi

        echo "Tentativa ${contador}/${tentativas}..."
        sleep 3
        contador=$((contador + 1))
    done

    docker logs "$POSTGRES_CONTAINER_NAME" || true

    erro "PostgreSQL não ficou disponível dentro do tempo esperado."
}

validate_postgres_basic() {
    step "Validando PostgreSQL"

    source "$APP_DIR/.env"

    log "Validando se o container está em execução..."

    if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
        erro "Container PostgreSQL não está em execução."
    fi

    log "Executando consulta SQL básica..."

    docker exec \
        "$POSTGRES_CONTAINER_NAME" \
        psql \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        -c "SELECT version();" >/dev/null

    sucesso "PostgreSQL validado."
}

show_postgres_info() {
    source "$APP_DIR/.env"

    local HOST_IP
    local STATUS

    HOST_IP=$(hostname -I | awk '{print $1}')
    STATUS=$(docker inspect -f '{{.State.Status}}' "$POSTGRES_CONTAINER_NAME" 2>/dev/null || echo "desconhecido")

    echo
    echo "============================================================"
    echo " PostgreSQL instalado com sucesso"
    echo "============================================================"
    printf "%-20s %s\n" "Container:" "$POSTGRES_CONTAINER_NAME"
    printf "%-20s %s\n" "Imagem:" "$POSTGRES_IMAGE"
    printf "%-20s %s\n" "Status:" "$STATUS"

    echo
    echo "============================================================"
    echo " Dados para conexão (DBeaver)"
    echo "============================================================"
    printf "%-20s %s\n" "Host:" "$HOST_IP"
    printf "%-20s %s\n" "Porta:" "$POSTGRES_PORT"
    printf "%-20s %s\n" "Database:" "$POSTGRES_DB"
    printf "%-20s %s\n" "Usuário:" "$POSTGRES_USER"
    printf "%-20s %s\n" "Senha:" "$POSTGRES_PASSWORD"

    echo
    echo "============================================================"
    echo " Persistência dos dados"
    echo "============================================================"
    printf "%-20s %s\n" "Diretório:" "$APP_DIR/postgres/data"

    echo
    echo "============================================================"
}

setup_postgres() {
    generate_env_file
    generate_docker_compose_postgres
    pull_postgres_image
    start_postgres
    wait_postgres
    validate_postgres_basic
}