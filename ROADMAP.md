# Roadmap - Escalas Deploy

## Objetivo

Automatizar a implantação da aplicação Escalas em servidores Ubuntu utilizando Docker, proporcionando uma instalação simples, padronizada e reproduzível.

---

# MVP 1.0 — Concluído

A primeira versão do projeto foi concluída com sucesso, contemplando todo o fluxo de implantação da aplicação.

## Infraestrutura

- [x] Estrutura inicial do projeto
- [x] Preparação automática do servidor Ubuntu
- [x] Instalação do Docker Engine
- [x] Instalação do Docker Compose
- [x] Criação da estrutura de diretórios

## Banco de Dados

- [x] Inicialização do PostgreSQL via Docker
- [x] Validação da conexão com o PostgreSQL
- [x] Download automático do backup
- [x] Restauração automática do banco de dados
- [x] Validação da restauração

## Aplicação

- [x] Download automático dos artefatos
- [x] Parametrização do `appsettings.json`
- [x] Parametrização do `connection.gam`
- [x] Build automático da imagem Docker
- [x] Configuração do Docker Compose
- [x] Inicialização da aplicação

## Finalização

- [x] Exibição das informações do PostgreSQL
- [x] Exibição da URL de acesso
- [x] README validado
- [x] Testes realizados em ambiente Ubuntu limpo

---

# Próxima Etapa — Organização e Documentação

Agora que o MVP foi concluído, o foco passa a ser a melhoria da qualidade do projeto.

- [ ] Revisar toda a estrutura do projeto
- [ ] Revisar todos os scripts
- [ ] Tornar os comentários mais didáticos
- [ ] Padronizar mensagens de log
- [ ] Revisar o `install.sh`
- [ ] Revisar todos os arquivos da pasta `scripts/core`
- [ ] Revisar todas as etapas da pasta `scripts/steps`
- [ ] Reestruturar o `README.md`
- [ ] Revisar toda a documentação
- [ ] Executar uma validação final em uma VM Ubuntu limpa

---

# Backlog

## Funcionalidades

- [ ] Atualização automática da aplicação
- [ ] Backup automático do PostgreSQL
- [ ] Rollback automático
- [ ] Configuração via arquivo `.env`
- [ ] Health Check da aplicação

## Infraestrutura

- [ ] GitHub Actions
- [ ] ShellCheck
- [ ] Makefile
- [ ] Traefik
- [ ] Harbor
- [ ] Keycloak
- [ ] Portainer

## Observabilidade

- [ ] Grafana
- [ ] Prometheus