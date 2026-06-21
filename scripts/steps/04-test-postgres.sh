#!/bin/bash

# ============================================================
# Escalas Deploy - Teste do PostgreSQL
# ============================================================
#
# Responsável por validar o funcionamento do PostgreSQL após
# sua inicialização.
#
# Esta etapa confirma:
# - se o container está em execução;
# - se é possível conectar ao banco de dados;
# - se comandos SQL podem ser executados;
# - se operações de criação, inserção, consulta e remoção
#   funcionam corretamente.
#
# O objetivo é garantir que o banco esteja apto para receber
# a restauração dos dados nas próximas etapas.
# ============================================================

test_postgres() {

    step "Testando conexão com PostgreSQL"

    # Carrega as variáveis definidas no arquivo .env.
    source "$APP_DIR/.env"

    # --------------------------------------------------------
    # Validação do container
    # --------------------------------------------------------

    log "Validando se o container está em execução..."

    if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
        erro "Container PostgreSQL não está em execução."
    fi

    # --------------------------------------------------------
    # Teste de conexão
    # --------------------------------------------------------

    log "Testando conexão com o banco ${POSTGRES_DB}..."

    docker exec         "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -c "SELECT current_database();"         || erro "Falha ao conectar no banco ${POSTGRES_DB}."

    # --------------------------------------------------------
    # Teste de escrita
    # --------------------------------------------------------

    log "Criando tabela temporária de teste..."

    docker exec         "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -c "CREATE TABLE IF NOT EXISTS teste_instalador (id SERIAL PRIMARY KEY, nome VARCHAR(100));"

    log "Inserindo registro de teste..."

    docker exec         "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -c "INSERT INTO teste_instalador(nome) VALUES ('teste de conexao');"

    # --------------------------------------------------------
    # Teste de leitura
    # --------------------------------------------------------

    log "Consultando registro de teste..."

    docker exec         "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -c "SELECT * FROM teste_instalador;"

    # --------------------------------------------------------
    # Limpeza do ambiente
    # --------------------------------------------------------

    log "Removendo tabela temporária de teste..."

    docker exec         "$POSTGRES_CONTAINER_NAME"         psql         -U "$POSTGRES_USER"         -d "$POSTGRES_DB"         -c "DROP TABLE teste_instalador;"

    sucesso "Teste de conexão com PostgreSQL concluído com sucesso."
}
