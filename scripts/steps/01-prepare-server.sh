#!/bin/bash

# ============================================================
# Objetivo:
# Preparar o Ubuntu Server para executar a aplicação em Docker.
#
# Esta etapa faz:
# - validação de permissão root/sudo;
# - validação do Ubuntu;
# - validação de conectividade;
# - correção de dpkg pendente;
# - atualização de pacotes;
# - instalação de pacotes básicos;
# - configuração do repositório oficial Docker;
# - instalação do Docker Engine;
# - instalação do Docker Compose;
# - inicialização e validação do serviço Docker.
# ============================================================

aguardar_apt_livre() {
  # Aguarda caso outro processo esteja usando o apt/dpkg.
  log "Verificando se o APT está livre..."

  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "APT/dpkg está em uso por outro processo. Aguardando 5 segundos..."
    sleep 5
  done
}

corrigir_dpkg() {
  # Corrige instalações interrompidas anteriormente.
  log "Verificando estado do dpkg..."

  if dpkg --audit | grep -q .; then
    echo "dpkg possui pendências. Corrigindo..."
    dpkg --configure -a
    apt-get install -f -y
  else
    echo "dpkg está íntegro."
  fi
}

prepare_server() {
  step "Validando permissões"

  # O instalador precisa ser executado como root.
  if [ "$(id -u)" -ne 0 ]; then
    erro "Execute este script como root ou usando sudo. Exemplo: sudo ./install.sh"
  fi

  step "Validando sistema operacional"

  # Verifica se o arquivo de identificação do sistema existe.
  if [ ! -f /etc/os-release ]; then
    erro "Não foi possível identificar o sistema operacional."
  fi

  # Carrega informações do sistema operacional.
  . /etc/os-release

  # Garante que o sistema é Ubuntu.
  if [ "${ID}" != "ubuntu" ]; then
    erro "Este instalador foi preparado para Ubuntu Server. Sistema identificado: ${ID}"
  fi

  echo "Sistema identificado: Ubuntu ${VERSION_ID} (${VERSION_CODENAME:-sem-codename})"

  step "Validando conectividade"

  # Valida acesso ao repositório Docker, que será usado na instalação.
  log "Validando acesso ao repositório Docker..."

  if ! curl -fsSL --connect-timeout 10 https://download.docker.com >/dev/null; then
    erro "Não foi possível acessar https://download.docker.com. Verifique internet, DNS, proxy ou firewall."
  fi

  step "Preparando APT e dpkg"

  # Aguarda apt/dpkg ficar livre.
  aguardar_apt_livre

  # Corrige dpkg caso uma instalação anterior tenha sido interrompida.
  corrigir_dpkg

  step "Atualizando pacotes do sistema"

  # Atualiza índice de pacotes.
  apt-get update -y

  step "Instalando dependências básicas"

  # Instala ferramentas básicas para administração e instalação.
  apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    vim \
    wget \
    unzip \
    net-tools \
    htop \
    jq \
    nano \
    tar

  step "Configurando repositório oficial do Docker"

  # Cria diretório onde ficará a chave GPG do Docker.
  install -m 0755 -d /etc/apt/keyrings

  # Baixa chave GPG oficial do Docker caso ainda não exista.
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc
  fi

  # Ajusta permissão de leitura da chave.
  chmod a+r /etc/apt/keyrings/docker.asc

  # Cria arquivo de repositório Docker para o Ubuntu atual.
  cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  # Atualiza índice de pacotes já incluindo Docker.
  apt-get update -y

  step "Instalando Docker Engine e Docker Compose"

  # Instala Docker Engine, CLI, containerd, buildx e compose plugin.
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  step "Habilitando e iniciando Docker"

  # Habilita Docker para iniciar automaticamente com o servidor.
  systemctl enable docker

  # Inicia o serviço Docker agora.
  systemctl start docker

  step "Validando instalação do Docker"

  # Valida comando docker.
  docker --version || erro "Docker não foi instalado corretamente."

  # Valida docker compose.
  docker compose version || erro "Docker Compose não foi instalado corretamente."

  # Valida status do serviço Docker.
  if ! systemctl is-active --quiet docker; then
    erro "O serviço Docker não está ativo."
  fi

  sucesso "Etapa de preparação do servidor concluída com sucesso."
}
