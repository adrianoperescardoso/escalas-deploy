#!/bin/bash

# ============================================================
# Escalas Deploy
# ============================================================
#
# Arquivo responsável por iniciar o processo de instalação.
#
# Este script atua como o orquestrador principal do projeto,
# executando cada etapa da instalação na ordem correta.
#
# Toda a lógica de negócio está implementada nos scripts da
# pasta "scripts". Este arquivo apenas coordena a execução
# dessas etapas, tornando o fluxo de instalação simples,
# organizado e fácil de compreender.
#
# ============================================================

set -Eeuo pipefail

# Diretório raiz do projeto.
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega toda a infraestrutura necessária para execução do
# instalador (configurações, funções utilitárias e etapas).
source "$BASE_DIR/scripts/core/bootstrap.sh"

main() {

    # Inicializa o sistema de logs e apresenta o cabeçalho.
    init_logging
    print_header

    # Remove instalações anteriores que possam interferir
    # na nova execução.
    cleanup_previous_execution

    # Prepara o servidor e cria a estrutura de diretórios.
    prepare_server
    prepare_folders

    # Configura o PostgreSQL e valida a conexão.
    setup_postgres
    test_postgres

    # Obtém os artefatos da aplicação e restaura o banco.
    download_assets
    restore_database

    # Prepara a aplicação e constrói sua imagem Docker.
    prepare_application
    build_application_image

    # Configura o ambiente Docker e inicia a aplicação.
    configure_compose
    start_application

    # Exibe as informações do PostgreSQL.
    show_postgres_info

    # Apresenta a tela final da instalação com destaque para a URL.
    print_summary
}

main "$@"