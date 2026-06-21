# Prompt Mestre --- Projeto Escalas Deploy

## Objetivo

Este documento tem como objetivo fornecer todo o contexto necessário
para dar continuidade ao desenvolvimento do projeto **Escalas Deploy**
em uma nova conversa, preservando as decisões arquiteturais já tomadas e
a forma de trabalho adotada.

Sempre considere este documento como o contexto inicial antes de
responder qualquer solicitação relacionada ao projeto.

------------------------------------------------------------------------

# Sobre o projeto

O Escalas Deploy é um instalador automatizado desenvolvido para
implantar aplicações GeneXus .NET em servidores Ubuntu utilizando
Docker.

O objetivo é permitir que uma aplicação seja instalada em uma máquina
totalmente limpa, realizando automaticamente toda a preparação do
ambiente.

O usuário final não deve precisar possuir conhecimentos avançados sobre
Linux, Docker, PostgreSQL ou GeneXus.

------------------------------------------------------------------------

# Objetivo do MVP

O MVP foi concluído com sucesso e automatiza todo o processo de
implantação da aplicação.

Ao executar o instalador, ele é capaz de:

-   preparar o servidor;
-   instalar Docker;
-   instalar Docker Compose;
-   criar a estrutura de diretórios;
-   baixar os artefatos da aplicação;
-   restaurar o banco PostgreSQL;
-   parametrizar automaticamente os arquivos gerados pelo GeneXus;
-   construir a imagem Docker;
-   criar o docker-compose;
-   iniciar a aplicação;
-   apresentar ao final todas as informações necessárias para acesso ao
    ambiente.

------------------------------------------------------------------------

# Estado atual do projeto

Atualmente o projeto já implementa:

-   Preparação automática do Ubuntu.
-   Instalação do Docker Engine.
-   Instalação do Docker Compose.
-   Criação da estrutura de diretórios.
-   Download automático dos artefatos através do GitHub Releases.
-   Reutilização dos artefatos quando já existirem localmente.
-   Restauração automática do PostgreSQL.
-   Parametrização automática do appsettings.json.
-   Parametrização automática do connection.gam.
-   Consulta automática da chave do GAM diretamente no banco restaurado.
-   Build automático da imagem Docker da aplicação.
-   Geração automática do docker-compose.yml.
-   Inicialização do PostgreSQL.
-   Inicialização da aplicação.
-   Exibição da URL de acesso.
-   Exibição dos dados do banco.
-   README reestruturado como documentação principal do projeto.

O MVP encontra-se concluído e funcional.

------------------------------------------------------------------------

# Tecnologias utilizadas

-   Bash
-   Docker
-   Docker Compose
-   PostgreSQL
-   Ubuntu Server
-   GitHub Releases
-   GeneXus .NET

------------------------------------------------------------------------

# Estrutura do projeto

-   docker
-   docs
-   scripts/core
-   scripts/steps
-   install.sh
-   README.md
-   ROADMAP.md

A responsabilidade de cada diretório deve permanecer clara.

------------------------------------------------------------------------

# Decisões arquiteturais

## GitHub Releases

Os artefatos da aplicação são distribuídos através das Releases do
GitHub.

O repositório Git contém apenas o código do instalador.

## Parametrização dos arquivos GeneXus

O instalador é responsável por transformar os arquivos gerados pelo
GeneXus em arquivos reutilizáveis para qualquer ambiente.

Atualmente são parametrizados:

-   appsettings.json
-   connection.gam

## Docker Compose

Toda a comunicação entre a aplicação e o PostgreSQL deve ocorrer
utilizando Docker Compose.

## README

O README é a documentação principal do projeto e deve apresentar a visão
geral, arquitetura, fluxo do instalador, estrutura do projeto e
instruções de instalação.

------------------------------------------------------------------------

# Forma de trabalho

## Uma tarefa por vez

Sempre concluir completamente uma tarefa antes de iniciar outra.

## Discussão antes da implementação

Quando existir mais de uma alternativa arquitetural, discutir primeiro.

## Entender antes de alterar

Antes de modificar qualquer arquivo, compreender sua responsabilidade
dentro do projeto e somente então realizar alterações.

## Arquivos completos

Sempre devolver o arquivo completo quando houver alterações.

## Sem suposições

Nunca assumir comportamento de arquivos não analisados.

## Código didático

Priorizar código simples e comentários que expliquem o motivo da
implementação.

## Documentação

README, ROADMAP e demais documentos devem refletir exatamente o estado
atual do projeto.

## Commits

Realizar um commit para cada funcionalidade ou melhoria implementada.

## Melhorias futuras

Registrar melhorias como backlog, sem alterar o foco da tarefa atual.

------------------------------------------------------------------------

# Forma esperada das respostas

As respostas devem ser objetivas, técnicas, completas e fundamentadas.

Evitar:

-   abrir novos assuntos;
-   mudar de direção durante a implementação;
-   responder com base em suposições.

------------------------------------------------------------------------

# Backlog atual

1.  Revisar todos os scripts.
2.  Tornar todos os comentários mais didáticos.
3.  Padronizar os logs.
4.  Revisar o install.sh.
5.  Revisar scripts/core.
6.  Revisar todas as etapas da instalação.
7.  Revisar a organização da estrutura do projeto.
8.  Revisar toda a documentação.
9.  Executar validação final em uma VM Ubuntu limpa.
10. Publicar a versão 1.0.

------------------------------------------------------------------------

# Considerações finais

O objetivo desta conversa não é reinventar o projeto.

O objetivo é evoluí-lo preservando sua arquitetura, simplicidade,
organização e consistência.

Antes de responder qualquer solicitação, analisar o contexto completo e
entregar uma solução definitiva, evitando respostas fragmentadas.
