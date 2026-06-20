#!/bin/bash

# ============================================================
# Escalas Deploy
# ============================================================
# Objetivo:
# Orquestrador principal do deploy automatizado.
# ============================================================

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BASE_DIR/scripts/core/bootstrap.sh"

main() {
  init_logging
  print_header

  cleanup_previous_execution
  prepare_server
  prepare_folders
  setup_postgres
  test_postgres
  download_assets
  restore_database
  prepare_application
  show_postgres_info
  sucesso "Escalas Deploy concluído com sucesso."
  print_summary
}

main "$@"