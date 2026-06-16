#!/bin/bash

# ============================================================
# Escalas Deploy - Bootstrap
# ============================================================
# Objetivo:
# Centralizar todos os imports do projeto.
# O install.sh carrega apenas este arquivo.
# ============================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "$BASE_DIR/scripts/core/common.sh"
source "$BASE_DIR/scripts/core/cleanup.sh"

source "$BASE_DIR/scripts/steps/01-prepare-server.sh"
source "$BASE_DIR/scripts/steps/02-prepare-folders.sh"
source "$BASE_DIR/scripts/steps/03-postgres.sh"
source "$BASE_DIR/scripts/steps/04-test-postgres.sh"
source "$BASE_DIR/scripts/steps/05-download-assets.sh"