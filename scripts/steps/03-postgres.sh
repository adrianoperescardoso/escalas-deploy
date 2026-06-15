#!/bin/bash

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
APP_IMAGE=registry.seudominio.com/${APP_NAME}:latest
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

    echo
    echo "========================================"
    echo " PostgreSQL instalado"
    echo "========================================"
    echo "Container : $POSTGRES_CONTAINER_NAME"
    echo "Imagem    : $POSTGRES_IMAGE"
    echo "Banco     : $POSTGRES_DB"
    echo "Usuário   : $POSTGRES_USER"
    echo "Senha     : $POSTGRES_PASSWORD"
    echo "Porta     : $POSTGRES_PORT"
    echo "Dados     : $APP_DIR/postgres/data"
    echo "========================================"
    echo
}

setup_postgres() {
    generate_env_file
    generate_docker_compose_postgres
    pull_postgres_image
    start_postgres
    wait_postgres
    validate_postgres_basic
    show_postgres_info
}
