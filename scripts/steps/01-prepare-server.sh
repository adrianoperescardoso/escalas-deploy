#!/bin/bash

# ============================================================
# Escalas Deploy - Preparação do Servidor
# ============================================================
#
# Responsável por preparar o servidor Ubuntu para receber a
# aplicação.
#
# Esta etapa garante que o ambiente esteja pronto para as
# próximas fases da instalação, realizando:
#
# - validação de permissões;
# - validação do sistema operacional;
# - validação de conectividade;
# - preparação do APT/dpkg;
# - atualização dos pacotes;
# - instalação das dependências básicas;
# - configuração do repositório oficial do Docker;
# - instalação do Docker Engine;
# - instalação do Docker Compose;
# - validação do serviço Docker.
#
# ============================================================

prepare_server() {

    # --------------------------------------------------------
    # Validação das permissões
    # --------------------------------------------------------

    step "Validando permissões"

    # O instalador precisa ser executado com privilégios de
    # administrador para instalar pacotes e configurar serviços.
    if [ "$(id -u)" -ne 0 ]; then
        erro "Execute este script como root ou utilizando sudo. Exemplo: sudo ./install.sh"
    fi

    # --------------------------------------------------------
    # Validação do sistema operacional
    # --------------------------------------------------------

    step "Validando sistema operacional"

    # Verifica se o sistema disponibiliza o arquivo de
    # identificação da distribuição Linux.
    if [ ! -f /etc/os-release ]; then
        erro "Não foi possível identificar o sistema operacional."
    fi

    # Carrega as informações do sistema operacional.
    . /etc/os-release

    # O instalador foi desenvolvido exclusivamente para Ubuntu.
    if [ "${ID}" != "ubuntu" ]; then
        erro "Este instalador foi desenvolvido para Ubuntu Server. Sistema identificado: ${ID}"
    fi

    log "Sistema identificado: Ubuntu ${VERSION_ID} (${VERSION_CODENAME:-sem-codename})"

    # --------------------------------------------------------
    # Validação de conectividade
    # --------------------------------------------------------

    step "Validando conectividade"

    # Verifica se o servidor consegue acessar o repositório
    # oficial do Docker.
    log "Validando acesso ao repositório oficial do Docker..."

    if ! curl -fsSL --connect-timeout 10 https://download.docker.com >/dev/null; then
        erro "Não foi possível acessar https://download.docker.com. Verifique internet, DNS, proxy ou firewall."
    fi

    # --------------------------------------------------------
    # Preparação do APT e do dpkg
    # --------------------------------------------------------

    step "Preparando APT e dpkg"

    # Aguarda outros processos que possam estar utilizando
    # o gerenciador de pacotes.
    aguardar_apt_livre

    # Corrige instalações interrompidas anteriormente.
    corrigir_dpkg

    # --------------------------------------------------------
    # Atualização dos pacotes
    # --------------------------------------------------------

    step "Atualizando pacotes do sistema"

    # Atualiza a lista de pacotes disponíveis.
    apt-get update -y

    # --------------------------------------------------------
    # Instalação das dependências básicas
    # --------------------------------------------------------

    step "Instalando dependências básicas"

    # Instala ferramentas utilizadas durante o processo de
    # instalação e administração do ambiente.
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

    # --------------------------------------------------------
    # Configuração do repositório oficial do Docker
    # --------------------------------------------------------

    step "Configurando repositório oficial do Docker"

    # Cria o diretório que armazenará a chave GPG do Docker.
    install -m 0755 -d /etc/apt/keyrings

    # Baixa a chave oficial apenas quando ela ainda não existir.
    if [ ! -f /etc/apt/keyrings/docker.asc ]; then

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            -o /etc/apt/keyrings/docker.asc

    fi

    # Permite que o APT leia a chave GPG.
    chmod a+r /etc/apt/keyrings/docker.asc

    # Registra o repositório oficial do Docker.
    cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # Atualiza novamente a lista de pacotes para incluir
    # o repositório recém-configurado.
    apt-get update -y

    # --------------------------------------------------------
    # Instalação do Docker
    # --------------------------------------------------------

    step "Instalando Docker Engine e Docker Compose"

    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # --------------------------------------------------------
    # Inicialização do Docker
    # --------------------------------------------------------

    step "Habilitando e iniciando Docker"

    # Configura o Docker para iniciar automaticamente com
    # o sistema operacional.
    systemctl enable docker

    # Inicia o serviço imediatamente.
    systemctl start docker

    # --------------------------------------------------------
    # Validação da instalação
    # --------------------------------------------------------

    step "Validando instalação do Docker"

    docker --version || erro "Docker não foi instalado corretamente."

    docker compose version || erro "Docker Compose não foi instalado corretamente."

    if ! systemctl is-active --quiet docker; then
        erro "O serviço Docker não está ativo."
    fi

    sucesso "Preparação do servidor concluída com sucesso."

}