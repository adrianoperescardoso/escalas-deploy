#!/bin/bash

# ============================================================
# Escalas Deploy - Estrutura de Diretórios
# ============================================================
#
# Responsável por criar a estrutura de diretórios utilizada
# durante a instalação da aplicação.
#
# Esta etapa cria:
#
# - diretório principal da aplicação;
# - diretório para backups;
# - diretório para logs;
# - estrutura de dados do PostgreSQL;
# - diretório de configurações.
#
# Ao final, também ajusta permissões e valida se toda a
# estrutura foi criada corretamente.
#
# ============================================================

prepare_folders() {

    step "Criando estrutura de diretórios da aplicação"

    # --------------------------------------------------------
    # Diretório principal
    # --------------------------------------------------------

    log "Criando diretório principal..."

    mkdir -p "$APP_DIR"

    # --------------------------------------------------------
    # Backup
    # --------------------------------------------------------

    log "Criando diretório de backup..."

    mkdir -p "$APP_DIR/backup"

    # --------------------------------------------------------
    # Logs
    # --------------------------------------------------------

    log "Criando diretório de logs..."

    mkdir -p "$APP_DIR/logs"

    # --------------------------------------------------------
    # PostgreSQL
    # --------------------------------------------------------

    log "Criando estrutura do PostgreSQL..."

    mkdir -p "$APP_DIR/postgres"
    mkdir -p "$APP_DIR/postgres/data"
    mkdir -p "$APP_DIR/postgres/backup"

    # --------------------------------------------------------
    # Configurações
    # --------------------------------------------------------

    log "Criando diretório de configurações..."

    mkdir -p "$APP_DIR/config"

    # --------------------------------------------------------
    # Permissões
    # --------------------------------------------------------

    log "Ajustando proprietário dos diretórios..."

    chown -R root:root "$APP_DIR"

    log "Ajustando permissões..."

    chmod -R 755 "$APP_DIR"

    # --------------------------------------------------------
    # Validação
    # --------------------------------------------------------

    log "Validando estrutura criada..."

    [ -d "$APP_DIR" ] || erro "Diretório principal não foi criado."
    [ -d "$APP_DIR/backup" ] || erro "Diretório de backup não foi criado."
    [ -d "$APP_DIR/logs" ] || erro "Diretório de logs não foi criado."
    [ -d "$APP_DIR/postgres" ] || erro "Diretório do PostgreSQL não foi criado."
    [ -d "$APP_DIR/postgres/data" ] || erro "Diretório postgres/data não foi criado."
    [ -d "$APP_DIR/postgres/backup" ] || erro "Diretório postgres/backup não foi criado."
    [ -d "$APP_DIR/config" ] || erro "Diretório de configurações não foi criado."

    sucesso "Estrutura de diretórios criada com sucesso."

}