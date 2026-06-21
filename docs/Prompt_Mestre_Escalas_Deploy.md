# Prompt Mestre — Projeto Escalas Deploy

## Objetivo

Este documento tem como objetivo fornecer todo o contexto necessário para dar continuidade ao desenvolvimento do projeto **Escalas Deploy** em uma nova conversa, preservando as decisões arquiteturais já tomadas e a forma de trabalho adotada.

Sempre considere este documento como o contexto inicial antes de responder qualquer solicitação relacionada ao projeto.

---

# Sobre o projeto

O Escalas Deploy é um instalador automatizado desenvolvido para implantar aplicações GeneXus .NET em servidores Ubuntu utilizando Docker.

O objetivo é permitir que uma aplicação seja instalada em uma máquina totalmente limpa, realizando automaticamente toda a preparação do ambiente.

O usuário final não deve precisar possuir conhecimentos avançados sobre Linux, Docker, PostgreSQL ou GeneXus.

---

# Objetivo do MVP

O MVP possui como objetivo automatizar completamente a instalação da aplicação.

Ao executar o instalador, espera-se que ele seja capaz de:

- preparar o servidor;
- instalar Docker;
- instalar Docker Compose;
- criar a estrutura de diretórios;
- baixar os artefatos da aplicação;
- restaurar o banco PostgreSQL;
- parametrizar automaticamente os arquivos gerados pelo GeneXus;
- construir a imagem Docker;
- criar o docker-compose;
- iniciar a aplicação;
- apresentar ao final todas as informações necessárias para acesso ao ambiente.

---

# Estado atual do projeto

Atualmente o projeto já implementa:

- Preparação automática do Ubuntu.
- Instalação do Docker Engine.
- Instalação do Docker Compose.
- Criação da estrutura de diretórios.
- Download automático dos artefatos através do GitHub Releases.
- Reutilização dos artefatos quando já existirem localmente.
- Restauração automática do PostgreSQL.
- Parametrização automática do appsettings.json.
- Parametrização automática do connection.gam.
- Consulta automática da chave do GAM diretamente no banco restaurado.
- Build automático da imagem Docker da aplicação.
- Geração automática do docker-compose.yml.
- Inicialização do PostgreSQL.
- Inicialização da aplicação.
- Exibição da URL de acesso.
- Exibição dos dados do banco.
- README validado com sucesso em uma VM Ubuntu limpa.

O MVP encontra-se funcional.

---

# Tecnologias utilizadas

- Bash
- Docker
- Docker Compose
- PostgreSQL
- Ubuntu Server
- GitHub Releases
- GeneXus .NET

---

# Estrutura do projeto

O projeto encontra-se organizado em:

- docker
- docs
- scripts/core
- scripts/steps
- templates
- tmp
- install.sh
- README.md

A responsabilidade de cada diretório deve permanecer clara.

---

# Decisões arquiteturais

As decisões abaixo já foram tomadas e não devem ser alteradas sem necessidade.

## GitHub Releases

Os artefatos da aplicação são distribuídos através das Releases do GitHub.

O repositório Git contém apenas o código do instalador.

---

## Parametrização dos arquivos GeneXus

O GeneXus gera arquivos contendo configurações fixas.

O instalador é responsável por transformá-los em arquivos parametrizados para que possam ser utilizados em qualquer ambiente.

Atualmente são parametrizados:

- appsettings.json
- connection.gam

---

## Docker Compose

Toda a comunicação entre a aplicação e o PostgreSQL deve ocorrer utilizando Docker Compose.

Evitar configurações específicas para um ambiente.

---

## README

O README é suficiente para instalação do projeto em uma VM limpa.

Não existe necessidade, neste momento, de criar um bootstrap adicional.

---

# Forma de trabalho

Estas regras devem ser seguidas durante todo o desenvolvimento.

## Uma tarefa por vez

Sempre concluir completamente uma tarefa antes de iniciar outra.

Evitar trabalhar em múltiplos assuntos simultaneamente.

---

## Discussão antes da implementação

Quando existir mais de uma alternativa arquitetural, discutir primeiro.

Implementar somente após a decisão.

---

## Arquivos completos

Sempre que houver alteração em um arquivo, devolver o arquivo completo.

Nunca devolver apenas trechos.

---

## Sem suposições

Nunca assumir comportamento de um arquivo que não foi enviado.

Sempre basear a resposta nos arquivos disponibilizados.

---

## Código didático

Priorizar código simples.

Os comentários devem explicar principalmente o motivo da implementação.

Evitar comentários redundantes.

---

## Commits

Realizar um commit para cada funcionalidade ou melhoria implementada.

---

## Melhorias futuras

Caso seja identificada alguma melhoria que não faça parte da tarefa atual, apenas registrá-la para discussão futura.

Não mudar o foco da implementação.

---

# Forma esperada das respostas

As respostas devem ser:

- objetivas;
- técnicas;
- completas;
- fundamentadas.

Evitar:

- abrir novos assuntos;
- sugerir implementações futuras durante uma tarefa em andamento;
- mudar de direção durante uma implementação.

Antes de responder, analisar toda a situação e apresentar uma solução completa.

Evitar responder em partes quando for possível entregar uma solução definitiva.

---

# Backlog atual

Próximos passos do projeto.

1. Revisar todos os scripts.
2. Tornar todos os comentários mais didáticos.
3. Padronizar os logs.
4. Revisar install.sh.
5. Revisar scripts/core.
6. Revisar todas as etapas (01 a 10).
7. Revisar a organização da estrutura do projeto.
8. Revisar a documentação.
9. Executar uma validação final em uma VM Ubuntu limpa.
10. Encerrar oficialmente o MVP.

Cada item deverá ser concluído antes do próximo ser iniciado.

---

# Considerações finais

O objetivo desta conversa não é reinventar o projeto.

O objetivo é continuar exatamente do ponto em que ele parou, respeitando todas as decisões já tomadas.

Sempre priorizar:

- simplicidade;
- clareza;
- manutenção;
- organização;
- consistência arquitetural.

Antes de responder qualquer solicitação, analisar todo o contexto e entregar a melhor solução possível, evitando respostas fragmentadas ou mudanças de direção durante a implementação.