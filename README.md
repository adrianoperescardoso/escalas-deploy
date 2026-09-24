# Escalas Deploy

> Instalador automatizado para aplicações GeneXus .NET em servidores
> Ubuntu utilizando Docker.

## Visão Geral

O **Escalas Deploy** automatiza todo o processo de implantação da
aplicação Escalas em um servidor Ubuntu limpo.

Ao executar um único comando, o instalador prepara o servidor, instala
as dependências, configura o PostgreSQL, decide se o banco de dados deve
ser restaurado, prepara a aplicação, constrói a imagem Docker e inicializa
todos os serviços necessários.

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
   ├── Decisão e restauração opcional do banco
   ├── Preparação da aplicação
   ├── Build da imagem Docker
   ├── Docker Compose
   ├── Inicialização da aplicação
   └── PG Back Web e agendamento de backups
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
       07 Restauração opcional do banco de dados
       08 Preparação da aplicação
       09 Build da imagem Docker
       10 Configuração do Docker Compose
       11 Inicialização da aplicação
       12 Configuração do PG Back Web e da tarefa de backup
       13 Exibição das informações finais

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

## Comportamento da restauração do banco

-   Na primeira instalação, quando ainda não existem dados locais do
    PostgreSQL, o backup da release é restaurado automaticamente.
-   Quando um banco existente é encontrado, o instalador pergunta se o
    usuário deseja restaurá-lo.
-   Ao responder `N` ou apenas pressionar Enter, o banco atual é preservado
    e somente os artefatos da aplicação são atualizados.
-   Ao responder `S`, o backup da release é restaurado e substitui os dados
    atuais do banco.
-   Quando a restauração é escolhida e já existe um backup local, o instalador
    pergunta se o usuário deseja baixar o backup da release e substituir o
    arquivo existente. Ao responder `N` ou pressionar Enter, o backup local é
    mantido. Ao responder `S`, o novo arquivo é baixado e validado antes da
    substituição.

## Acesso ao PostgreSQL

-   Durante a instalação, o usuário pode escolher se deseja disponibilizar o
    PostgreSQL para acesso externo.
-   Ao responder `N` ou apenas pressionar Enter, a porta `5432` não é publicada
    no servidor e somente a aplicação consegue acessar o banco pela rede Docker.
-   Ao responder `S`, a porta configurada em `POSTGRES_PORT` é publicada para
    acesso externo. Essa opção exige firewall e uma senha forte em produção.

## PG Back Web

O instalador inclui o PG Back Web 0.5.2 no mesmo `docker-compose.yml` da
aplicação e do PostgreSQL. Ele cria o banco de configuração `pgbackweb`,
um usuário próprio para esse banco, um usuário de leitura para o banco
`escalas` e a conta inicial de administração da interface. Cadastra também
uma tarefa de backup local uma vez ao dia, às 02h (`0 2 * * *`, fuso
`America/Porto_Velho`), com retenção de 60 dias. Se houver uma tarefa horária
criada pelo instalador anterior, ela será atualizada para a frequência diária.
Os arquivos ficam em
`/opt/escalas/pgbackweb/backups/escalas` no servidor.

**Credenciais:** `/opt/escalas/pgbackweb/.env` (acessível ao administrador
do servidor, permissão `600`). O arquivo lista os usuários, as senhas e
as strings de conexão do banco de configuração e do banco Escalas, além
do e-mail e da senha da interface web e da chave de criptografia.
Preserve esse arquivo com o banco `pgbackweb`: perdê-lo pode impedir o
acesso à interface e às conexões salvas. Não publique nem envie seu conteúdo
para o repositório.

Após o cadastro do administrador, a interface é publicada em
`http://<IP-da-VM>:8085`. Para futuras instalações, o arquivo de
credenciais e a tarefa cadastrada são reaproveitados. Os backups do
banco `escalas` não incluem automaticamente o banco de configuração
`pgbackweb`; inclua esse banco e o arquivo de credenciais em sua estratégia
de recuperação do servidor.

Se já existir um PG Back Web instalado separadamente em `/opt/pgbackweb`,
o instalador perguntará se deseja substituí-lo (o padrão é cancelar).
Ao confirmar, ele arquiva a instalação anterior em
`/opt/pgbackweb-antes-integracao-<data>` e, quando encontra seu banco de
configuração no PostgreSQL do EscalasPro, salva um dump antes de criar o
novo banco. A conta e a tarefa antigas não são importadas: o instalador
cria uma configuração nova e guarda as credenciais correspondentes em
`/opt/escalas/pgbackweb/.env`. Os backups anteriores permanecem no arquivo
preservado, mas não aparecerão automaticamente na nova interface. Se o
banco de configuração anterior estiver em outro PostgreSQL, a migração
desse banco deve ser tratada separadamente antes de confirmar a substituição.
O caminho exato do arquivo anterior aparece no resumo final e fica registrado
em `/opt/escalas/pgbackweb/INSTALACAO_ANTERIOR.txt`, junto com os caminhos
das credenciais antigas, dos backups e do dump do banco antigo, quando gerado.
O administrador do servidor pode restaurar esse dump em um banco de teste
para consultar os dados anteriores, sem alterar o novo banco `pgbackweb`.

------------------------------------------------------------------------

# Resultado Esperado

Ao término da instalação o ambiente estará preparado com:

-   Docker Engine instalado.
-   Docker Compose configurado.
-   PostgreSQL em execução.
-   PG Back Web integrado ao Compose, com conta inicial e backup agendado.
-   Banco restaurado na primeira instalação ou preservado durante uma
    atualização, conforme a escolha do usuário.
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
-   [x] Preservação opcional do banco durante atualizações
-   [x] Parametrização da aplicação
-   [x] Build da imagem Docker
-   [x] Configuração do Docker Compose
-   [x] Inicialização da aplicação
-   [x] Integração do PG Back Web ao instalador e configuração do backup automático

## Próximas versões

-   [ ] Atualização automática
-   [ ] Rollback
-   [ ] Health Check
-   [ ] HTTPS
