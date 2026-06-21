#!/bin/bash

# ============================================================
# Objetivo:
# Criar a estrutura de diretórios da aplicação.
#
# Esta etapa prepara:
# - diretório principal em /opt/escalas;
# - pasta para backup geral da aplicação;
# - pasta para logs;
# - estrutura do PostgreSQL;
# - pasta de configurações.
# ============================================================

prepare_folders() {

    step "Criando estrutura de diretórios da aplicação"

    # Cria diretório principal da aplicação.
    log "Criando diretório principal: $APP_DIR"
    mkdir -p "$APP_DIR"

    # Diretório para backups gerais da aplicação.
    log "Criando diretório de backup..."
    mkdir -p "$APP_DIR/backup"

    # Diretório para logs.
    log "Criando diretório de logs..."
    mkdir -p "$APP_DIR/logs"

    # Estrutura do PostgreSQL.
    log "Criando estrutura do PostgreSQL..."
    mkdir -p "$APP_DIR/postgres"
    mkdir -p "$APP_DIR/postgres/data"
    mkdir -p "$APP_DIR/postgres/backup"

    # Diretório reservado para arquivos de configuração.
    log "Criando diretório de configurações..."
    mkdir -p "$APP_DIR/config"

    # Ajusta proprietário.
    log "Ajustando proprietário dos diretórios..."
    chown -R root:root "$APP_DIR"

    # Ajusta permissões.
    log "Ajustando permissões..."
    chmod -R 755 "$APP_DIR"

    # Validação.
    log "Validando estrutura criada..."

    [ -d "$APP_DIR" ] || erro "Diretório principal não foi criado."
    [ -d "$APP_DIR/backup" ] || erro "Diretório backup não foi criado."
    [ -d "$APP_DIR/logs" ] || erro "Diretório logs não foi criado."
    [ -d "$APP_DIR/postgres" ] || erro "Diretório postgres não foi criado."
    [ -d "$APP_DIR/postgres/data" ] || erro "Diretório postgres/data não foi criado."
    [ -d "$APP_DIR/postgres/backup" ] || erro "Diretório postgres/backup não foi criado."
    [ -d "$APP_DIR/config" ] || erro "Diretório config não foi criado."

    sucesso "Estrutura de diretórios criada com sucesso."

}