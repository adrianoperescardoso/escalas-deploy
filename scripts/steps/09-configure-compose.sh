#!/bin/bash

# ============================================================
# Objetivo:
# Configurar o docker-compose.yml com PostgreSQL e aplicação.
#
# Esta etapa:
# - gera o docker-compose.yml final;
# - mantém PostgreSQL e aplicação na mesma rede Docker;
# - configura a aplicação para depender do PostgreSQL.
#
# Esta etapa NÃO inicia a aplicação.
# ============================================================

configure_compose() {
    step "Configurando Docker Compose da aplicação"

    generate_docker_compose_full
    validate_docker_compose_full

    sucesso "Docker Compose configurado com sucesso."
}

generate_docker_compose_full() {

    log "Gerando docker-compose.yml completo..."

    COMPOSE_FILE="$APP_DIR/docker-compose.yml"

    cat > "$COMPOSE_FILE" <<EOF
name: ${PROJECT_NAME}

services:

  postgres:
    image: \${POSTGRES_IMAGE}
    container_name: \${POSTGRES_CONTAINER_NAME}
    restart: unless-stopped

    env_file:
      - .env

    environment:
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}

    ports:
      - "\${POSTGRES_PORT}:5432"

    volumes:
      - ./postgres/data:/var/lib/postgresql/data

    healthcheck:
      test: ["CMD-SHELL","pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 10

  app:
    image: ${APPLICATION_IMAGE}
    container_name: ${APP_NAME}-app
    restart: unless-stopped

    depends_on:
      postgres:
        condition: service_healthy

    env_file:
      - .env

    environment:
      ASPNETCORE_URLS: http://+:8080
      TZ: America/Porto_Velho

      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: \${POSTGRES_DB}
      DB_USER: \${POSTGRES_USER}
      DB_PASSWORD: \${POSTGRES_PASSWORD}

    ports:
      - "\${APP_PORT}:8080"
EOF

    chmod 644 "$COMPOSE_FILE"

    log "docker-compose.yml completo gerado."
}

validate_docker_compose_full() {

    log "Validando docker-compose.yml..."

    cd "$APP_DIR"

    if ! docker compose -p "$PROJECT_NAME" config >/dev/null; then
        erro "docker-compose.yml inválido."
    fi

    echo
    echo "============================================================"
    echo " Docker Compose configurado"
    echo "============================================================"
    echo "Arquivo : $APP_DIR/docker-compose.yml"
    echo "Serviços: postgres, app"
    echo "Imagem  : $APPLICATION_IMAGE"
    echo "Porta   : APP_PORT -> 8080"
    echo "============================================================"
    echo
}