#!/bin/bash

# ============================================================
# Escalas Deploy - Bootstrap
# ============================================================
#
# Responsável por carregar toda a infraestrutura necessária
# para execução do instalador.
#
# O install.sh importa apenas este arquivo, que por sua vez
# carrega os arquivos compartilhados (core) e todas as etapas
# da instalação na ordem em que serão executadas.
#
# ============================================================

# Diretório raiz do projeto.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ============================================================
# Arquivos compartilhados
# ============================================================

source "$BASE_DIR/scripts/core/config.sh"
source "$BASE_DIR/scripts/core/common.sh"
source "$BASE_DIR/scripts/core/cleanup.sh"

# ============================================================
# Etapas do instalador
# ============================================================

source "$BASE_DIR/scripts/steps/01-prepare-server.sh"
source "$BASE_DIR/scripts/steps/02-prepare-folders.sh"
source "$BASE_DIR/scripts/steps/03-postgres.sh"
source "$BASE_DIR/scripts/steps/04-test-postgres.sh"
source "$BASE_DIR/scripts/steps/05-download-assets.sh"
source "$BASE_DIR/scripts/steps/06-restore-database.sh"
source "$BASE_DIR/scripts/steps/07-prepare-application.sh"
source "$BASE_DIR/scripts/steps/08-build-app-image.sh"
source "$BASE_DIR/scripts/steps/09-configure-compose.sh"
source "$BASE_DIR/scripts/steps/10-start-application.sh"