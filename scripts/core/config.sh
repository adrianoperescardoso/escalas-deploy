#!/bin/bash

# ============================================================
# Escalas Deploy - Configuração
# ============================================================
#
# Centraliza todas as configurações utilizadas pelo projeto.
#
# Este arquivo não deve conter funções. Sua única
# responsabilidade é definir constantes e variáveis de
# configuração utilizadas durante a instalação.
#
# ============================================================

# ============================================================
# Informações gerais da aplicação
# ============================================================

APP_NAME="escalas"
PROJECT_NAME="escalas"
APP_DIR="/opt/${APP_NAME}"
LOG_FILE="/tmp/install-${APP_NAME}.log"

DEVELOPMENT_MODE=true

# ============================================================
# GitHub Releases
# ============================================================

GITHUB_OWNER="adrianoperescardoso"
GITHUB_REPOSITORY="escalas-deploy"
RELEASE_VERSION="v1.0.0-beta"

# ============================================================
# Backup do PostgreSQL
# ============================================================

BACKUP_FILE_NAME="Escalas.backup"

BACKUP_DOWNLOAD_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/releases/download/${RELEASE_VERSION}/${BACKUP_FILE_NAME}"

BACKUP_LOCAL_DIR="${APP_DIR}/assets/backup"
BACKUP_LOCAL_FILE="${BACKUP_LOCAL_DIR}/${BACKUP_FILE_NAME}"

# ============================================================
# Artefatos da aplicação
# ============================================================

APPLICATION_PACKAGE_NAME="DeploymentUnit1_20260616181805.zip"

APPLICATION_DOWNLOAD_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/releases/download/${RELEASE_VERSION}/${APPLICATION_PACKAGE_NAME}"

APPLICATION_ASSETS_DIR="${APP_DIR}/assets/application"
APPLICATION_LOCAL_FILE="${APPLICATION_ASSETS_DIR}/${APPLICATION_PACKAGE_NAME}"

APPLICATION_BUILD_DIR="${APP_DIR}/build/application"

# ============================================================
# Imagem Docker
# ============================================================

APPLICATION_IMAGE_NAME="escalas-app"
APPLICATION_IMAGE_TAG="1.0.0-beta"

APPLICATION_IMAGE="${APPLICATION_IMAGE_NAME}:${APPLICATION_IMAGE_TAG}"

APPLICATION_DOCKERFILE="${BASE_DIR}/docker/app/Dockerfile"

# ============================================================
# Controle da instalação
# ============================================================

TOTAL_STEPS=25
CURRENT_STEP=0