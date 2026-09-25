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

# Atualiza o próprio instalador antes de carregar qualquer etapa. Se o código
# mudar, reexecuta o arquivo atualizado para não misturar versões na execução.
update_installer_before_start() {
    [ "${ESCALAS_INSTALL_REEXEC:-0}" = 1 ] && return 0
    [ -e "$BASE_DIR/.git" ] || return 0

    command -v git >/dev/null 2>&1 || {
        echo "ERRO: Git não está disponível para atualizar o instalador." >&2
        return 1
    }

    local owner branch previous_head current_head
    local -a git_command=(git)
    owner=$(stat -c %U "$BASE_DIR")
    if [ "$EUID" -eq 0 ] && [ "$owner" != root ]; then
        git_command=(sudo -H -u "$owner" git)
    fi

    branch=$("${git_command[@]}" -C "$BASE_DIR" branch --show-current)
    if [ "$branch" != main ]; then
        echo "Atualização automática ignorada na branch ${branch:-sem branch}."
        return 0
    fi

    if [ -n "$("${git_command[@]}" -C "$BASE_DIR" status --porcelain)" ]; then
        echo "ERRO: há alterações locais no escalas-deploy. Revise-as antes de instalar." >&2
        return 1
    fi

    previous_head=$("${git_command[@]}" -C "$BASE_DIR" rev-parse HEAD)
    echo "Verificando atualizações do instalador na branch main..."
    "${git_command[@]}" -C "$BASE_DIR" pull --ff-only origin main || {
        echo "ERRO: não foi possível atualizar o instalador. Nenhuma etapa de instalação foi iniciada." >&2
        return 1
    }
    current_head=$("${git_command[@]}" -C "$BASE_DIR" rev-parse HEAD)

    if [ "$previous_head" != "$current_head" ]; then
        echo "Instalador atualizado; iniciando a versão nova..."
        export ESCALAS_INSTALL_REEXEC=1
        exec "$BASE_DIR/install.sh" "$@"
    fi
}

update_installer_before_start "$@"

# Carrega toda a infraestrutura necessária para execução do
# instalador (configurações, funções utilitárias e etapas).
source "$BASE_DIR/scripts/core/bootstrap.sh"

main() {

    # Inicializa o sistema de logs e apresenta o cabeçalho.
    init_logging
    print_header

    # Uma instalação manual antiga exige migração antes de parar a aplicação.
    preflight_pgbackweb

    # Define se o banco será restaurado antes de qualquer limpeza.
    # Em instalações existentes, o padrão é preservar os dados.
    define_database_restore_mode

    # Define se o PostgreSQL poderá ser acessado externamente.
    # A opção padrão é manter o banco somente na rede Docker.
    define_postgres_exposure_mode

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

    if [ "$RESTORE_DATABASE" = true ]; then
        restore_database
    fi

    # A chave do GAM é necessária tanto após uma restauração quanto
    # quando o banco existente é preservado.
    configure_gam_connection_key

    # Prepara bancos, usuários e credenciais antes de gerar o Compose completo.
    prepare_pgbackweb

    # Prepara a aplicação e constrói sua imagem Docker.
    prepare_application
    build_application_image

    # Configura o ambiente Docker e inicia a aplicação.
    configure_compose
    start_application
    configure_pgbackweb

    # Exibe as informações do PostgreSQL.
    show_postgres_info

    # Apresenta a tela final da instalação com destaque para a URL.
    print_summary
}

main "$@"
