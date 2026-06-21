# Escalas Deploy

> Instalador automatizado para aplicações GeneXus .NET em servidores
> Ubuntu utilizando Docker.

## Visão Geral

O **Escalas Deploy** automatiza todo o processo de implantação da
aplicação Escalas em um servidor Ubuntu limpo.

Ao executar um único comando, o instalador prepara o servidor, instala
as dependências, configura o PostgreSQL, restaura o banco de dados,
prepara a aplicação, constrói a imagem Docker e inicializa todos os
serviços necessários.

O objetivo é tornar o processo de implantação **simples, padronizado,
reproduzível e confiável**, dispensando conhecimentos avançados em
Linux, Docker, PostgreSQL ou GeneXus.

------------------------------------------------------------------------

# Objetivos

-   Automatizar a implantação da aplicação.
-   Padronizar instalações.
-   Eliminar configurações manuais.
-   Reduzir erros operacionais.
-   Facilitar futuras manutenções.

------------------------------------------------------------------------

# Arquitetura da Solução

``` text
Usuário
   │
   ▼
install.sh
   │
   ├── Limpeza da execução anterior
   ├── Preparação do servidor
   ├── Estrutura de diretórios
   ├── PostgreSQL
   ├── Download dos artefatos
   ├── Restauração do banco
   ├── Preparação da aplicação
   ├── Build da imagem Docker
   ├── Docker Compose
   └── Inicialização da aplicação
```

------------------------------------------------------------------------

# Fluxo do Instalador

    Etapa Descrição
  ------- ------------------------------------
       01 Limpeza de instalações anteriores
       02 Preparação do servidor
       03 Criação da estrutura de diretórios
       04 Configuração do PostgreSQL
       05 Teste de conexão com o banco
       06 Download dos artefatos
       07 Restauração do banco de dados
       08 Preparação da aplicação
       09 Build da imagem Docker
       10 Configuração do Docker Compose
       11 Inicialização da aplicação
       12 Exibição das informações finais

------------------------------------------------------------------------

# Estrutura do Projeto

``` text
escalas-deploy/
├── docker/          Arquivos para construção da imagem Docker
├── docs/            Documentação do projeto
├── scripts/
│   ├── core/        Funções compartilhadas
│   └── steps/       Etapas executadas pelo instalador
├── install.sh       Orquestrador principal
├── README.md
└── ROADMAP.md
```

------------------------------------------------------------------------

# Tecnologias

-   Bash
-   Docker
-   Docker Compose
-   PostgreSQL
-   Ubuntu Server
-   GitHub Releases
-   GeneXus .NET

------------------------------------------------------------------------

# Requisitos

-   Ubuntu Server 24.04 ou superior
-   Acesso sudo
-   Conexão com a Internet

------------------------------------------------------------------------

# Instalação

``` bash
sudo apt update
sudo apt install -y git

git clone https://github.com/adrianoperescardoso/escalas-deploy.git
cd escalas-deploy

sudo ./install.sh
```

------------------------------------------------------------------------

# Resultado Esperado

Ao término da instalação o ambiente estará preparado com:

-   Docker Engine instalado.
-   Docker Compose configurado.
-   PostgreSQL em execução.
-   Banco restaurado.
-   Aplicação configurada.
-   Imagem Docker construída.
-   Containers iniciados.
-   Informações de acesso exibidas ao usuário.

------------------------------------------------------------------------

# Roadmap

## MVP

-   [x] Preparação do servidor
-   [x] Instalação do Docker
-   [x] Instalação do Docker Compose
-   [x] Estrutura de diretórios
-   [x] Download dos artefatos
-   [x] Restauração do PostgreSQL
-   [x] Parametrização da aplicação
-   [x] Build da imagem Docker
-   [x] Configuração do Docker Compose
-   [x] Inicialização da aplicação

## Próximas versões

-   [ ] Atualização automática
-   [ ] Backup automático
-   [ ] Rollback
-   [ ] Health Check
-   [ ] HTTPS
