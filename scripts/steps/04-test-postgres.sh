#!/bin/bash

# ============================================================
# Objetivo:
# Testar a conexão com o PostgreSQL antes de executar restore.
#
# Esta etapa confirma:
# - se o container está rodando;
# - se o banco escalas existe;
# - se o usuário postgres consegue conectar;
# - se é possível executar comandos SQL;
# - se a criação, inserção, consulta e remoção de tabela funcionam.
# ============================================================

test_postgres() {
  step "Testando conexão com PostgreSQL"

  # Carrega variáveis do .env.
  source "$APP_DIR/.env"

  # Valida se o container está rodando.
  log "Validando se o container está em execução..."

  if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
    erro "Container PostgreSQL não está em execução."
  fi

  # Testa conexão informando banco, usuário e senha.
  log "Testando conexão com o banco ${POSTGRES_DB}..."

  docker exec \
    "$POSTGRES_CONTAINER_NAME" \
    psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -c "SELECT current_database();" || erro "Falha ao conectar no banco ${POSTGRES_DB}."

  # Cria tabela temporária de teste.
  log "Criando tabela temporária de teste..."

  docker exec \
    "$POSTGRES_CONTAINER_NAME" \
    psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -c "CREATE TABLE IF NOT EXISTS teste_instalador (id SERIAL PRIMARY KEY, nome VARCHAR(100));"

  # Insere registro de teste.
  log "Inserindo registro de teste..."

  docker exec \
    "$POSTGRES_CONTAINER_NAME" \
    psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -c "INSERT INTO teste_instalador(nome) VALUES ('teste de conexao');"

  # Consulta registro de teste.
  log "Consultando registro de teste..."

  docker exec \
    "$POSTGRES_CONTAINER_NAME" \
    psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -c "SELECT * FROM teste_instalador;"

  # Remove tabela temporária.
  log "Removendo tabela temporária de teste..."

  docker exec \
    "$POSTGRES_CONTAINER_NAME" \
    psql \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -c "DROP TABLE teste_instalador;"

  sucesso "Teste de conexão com PostgreSQL concluído com sucesso."
}
