# Roadmap - Escalas Deploy

## Objetivo do MVP

Disponibilizar um ambiente funcional do Sistema Escalas para que a equipe de testes possa acessar a aplicação e validar os fluxos do sistema.

---

## MVP - Versão 1.0

### Sprint 01 - Infraestrutura Base

- [x] Estrutura inicial do projeto
- [x] Instalação do Docker
- [x] Instalação do Docker Compose
- [x] Criação da estrutura de diretórios
- [x] Instalação do PostgreSQL via Docker
- [x] Validação interna do PostgreSQL
- [x] Exibição dos dados de conexão
- [x] Teste de conexão via DBeaver
- [x] Versionamento no GitHub

### Sprint 02 - Restore do Banco

- [ ] Restaurar automaticamente o backup do PostgreSQL
- [ ] Validar se a restauração foi concluída com sucesso
- [ ] Exibir resultado do restore no resumo da instalação

### Sprint 03 - Aplicação

- [ ] Baixar a imagem Docker da aplicação
- [ ] Apontar a aplicação para o banco PostgreSQL
- [ ] Iniciar a aplicação
- [ ] Exibir URL de acesso ao sistema

---

## Backlog Futuro

- [ ] Backup automático do PostgreSQL
- [ ] Atualização automática da aplicação
- [ ] Rollback
- [ ] Configuração via arquivo
- [ ] Sistema de módulos/plugins
- [ ] GitHub Actions
- [ ] ShellCheck
- [ ] Makefile
- [ ] Traefik
- [ ] Harbor
- [ ] Keycloak
- [ ] Portainer
- [ ] Grafana
- [ ] Prometheus
