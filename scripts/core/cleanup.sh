#!/bin/bash

# ============================================================
# Objetivo:
# Preparar o ambiente antes de uma nova execução do instalador.
#
# Em modo desenvolvimento:
# - derruba containers do projeto Docker Compose;
# - remove containers órfãos;
# - remove container PostgreSQL antigo, se existir;
# - limpa dados anteriores do PostgreSQL;
# - permite rodar o install.sh várias vezes durante os testes.
# ============================================================

cleanup_previous_execution() {
  step "Verificando instalação anterior"

  if [ ! -d "$APP_DIR" ]; then
    log "Nenhuma instalação anterior encontrada."
    return
  fi

  log "Instalação anterior encontrada em: $APP_DIR"

  if [ "$DEVELOPMENT_MODE" = true ]; then
    cleanup_development_mode
  else
    cleanup_production_mode
  fi
}

cleanup_development_mode() {
  log "Modo desenvolvimento ativo. Preparando ambiente limpo."

  if [ -f "$APP_DIR/docker-compose.yml" ]; then
    log "Executando docker compose down do projeto $PROJECT_NAME..."

    cd "$APP_DIR"
    docker compose -p "$PROJECT_NAME" down --remove-orphans || true
  fi

  log "Removendo containers antigos conhecidos, se existirem..."

  docker rm -f "${APP_NAME}-postgres" 2>/dev/null || true
  docker rm -f "${PROJECT_NAME}-postgres" 2>/dev/null || true
  docker rm -f "minha-app-postgres" 2>/dev/null || true

  if [ -d "$APP_DIR/postgres/data" ]; then
    log "Limpando dados anteriores do PostgreSQL..."
    rm -rf "$APP_DIR/postgres/data"/*
  fi

  log "Ambiente anterior limpo para nova execução."
}

cleanup_production_mode() {
  echo
  echo "Foi encontrada uma instalação anterior em:"
  echo "$APP_DIR"
  echo

  echo "Escolha uma opção:"
  echo "1) Atualizar instalação existente sem remover dados"
  echo "2) Reinstalar do zero removendo containers e dados"
  echo "3) Cancelar"
  echo

  read -r -p "Opção [1/2/3]: " opcao

  case "$opcao" in
    1)
      log "Usuário escolheu atualizar instalação existente."
      ;;
    2)
      if confirmar "ATENÇÃO: isso removerá containers e dados locais do PostgreSQL. Deseja continuar?"; then
        reinstall_from_zero
      else
        erro "Operação cancelada pelo usuário."
      fi
      ;;
    3)
      erro "Instalação cancelada pelo usuário."
      ;;
    *)
      erro "Opção inválida."
      ;;
  esac
}

reinstall_from_zero() {
  log "Reinstalando ambiente do zero."

  if [ -f "$APP_DIR/docker-compose.yml" ]; then
    cd "$APP_DIR"
    docker compose -p "$PROJECT_NAME" down --remove-orphans || true
  fi

  docker rm -f "${APP_NAME}-postgres" 2>/dev/null || true
  docker rm -f "${PROJECT_NAME}-postgres" 2>/dev/null || true

  if [ -d "$APP_DIR/postgres/data" ]; then
    rm -rf "$APP_DIR/postgres/data"/*
  fi

  log "Ambiente removido para reinstalação."
}
