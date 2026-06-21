#!/bin/bash

APP_NAME="escalas"
PROJECT_NAME="escalas"
APP_DIR="/opt/${APP_NAME}"
LOG_FILE="/tmp/install-${APP_NAME}.log"

DEVELOPMENT_MODE=true

# ==========================================================
# GitHub Release
# ==========================================================

GITHUB_OWNER="adrianoperescardoso"
GITHUB_REPOSITORY="escalas-deploy"
RELEASE_VERSION="v1.0.0-beta"

# ==========================================================
# Backup PostgreSQL
# ==========================================================

BACKUP_FILE_NAME="Escalas.backup"
BACKUP_DOWNLOAD_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/releases/download/${RELEASE_VERSION}/${BACKUP_FILE_NAME}"

BACKUP_LOCAL_DIR="${APP_DIR}/assets/backup"
BACKUP_LOCAL_FILE="${BACKUP_LOCAL_DIR}/${BACKUP_FILE_NAME}"

# ==========================================================
# Pacote da aplicação
# ==========================================================

APPLICATION_PACKAGE_NAME="DeploymentUnit1_20260616181805.zip"
APPLICATION_DOWNLOAD_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/releases/download/${RELEASE_VERSION}/${APPLICATION_PACKAGE_NAME}"

APPLICATION_ASSETS_DIR="${APP_DIR}/assets/application"
APPLICATION_LOCAL_FILE="${APPLICATION_ASSETS_DIR}/${APPLICATION_PACKAGE_NAME}"

APPLICATION_BUILD_DIR="${APP_DIR}/build/application"

# ==========================================================
# Imagem Docker da aplicação
# ==========================================================

APPLICATION_IMAGE_NAME="escalas-app"
APPLICATION_IMAGE_TAG="1.0.0-beta"
APPLICATION_IMAGE="${APPLICATION_IMAGE_NAME}:${APPLICATION_IMAGE_TAG}"

APPLICATION_DOCKERFILE="${BASE_DIR}/docker/app/Dockerfile"

# ==========================================================
# Controle da instalação
# ==========================================================

TOTAL_STEPS=23
CURRENT_STEP=0

init_logging() {
  rm -f "$LOG_FILE" 2>/dev/null || true
  touch "$LOG_FILE"

  exec > >(tee -a "$LOG_FILE")
  exec 2>&1
}

print_header() {
  echo "========================================"
  echo " Instalador - $APP_NAME"
  echo " Projeto Docker Compose: $PROJECT_NAME"
  echo " Diretório: $APP_DIR"
  echo " Modo desenvolvimento: $DEVELOPMENT_MODE"
  echo " Release GitHub: $RELEASE_VERSION"
  echo " Imagem aplicação: $APPLICATION_IMAGE"
  echo " Log: $LOG_FILE"
  echo "========================================"
}

log() {
  echo
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo
}

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))

  echo
  echo "========================================"
  echo "[$CURRENT_STEP/$TOTAL_STEPS] $1"
  echo "========================================"
  echo
}

erro() {
  echo
  echo "========================================"
  echo "ERRO: $1"
  echo "Log da instalação: $LOG_FILE"
  echo "========================================"
  echo
  exit 1
}

sucesso() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
  echo
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

confirmar() {
  local mensagem="$1"

  read -r -p "$mensagem [s/N]: " resposta

  case "$resposta" in
    s|S|sim|SIM|Sim)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

print_summary() {
  echo
  echo "========================================"
  echo " Resumo da instalação"
  echo "========================================"
  echo "Aplicação              : $APP_NAME"
  echo "Projeto Docker Compose : $PROJECT_NAME"
  echo "Diretório              : $APP_DIR"
  echo "Modo desenvolvimento   : $DEVELOPMENT_MODE"
  echo "Release GitHub         : $RELEASE_VERSION"
  echo "Imagem aplicação       : $APPLICATION_IMAGE"
  echo "Docker                 : $(docker --version 2>/dev/null || echo 'não instalado')"
  echo "Docker Compose         : $(docker compose version 2>/dev/null || echo 'não instalado')"
  echo "Log                    : $LOG_FILE"
  echo "========================================"
  echo
}