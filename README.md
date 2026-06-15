# Escalas Deploy

## Objetivo

O Escalas Deploy é um projeto responsável por automatizar toda a implantação da aplicação Escalas em um servidor Ubuntu utilizando Docker.

O objetivo é permitir que qualquer pessoa execute apenas um comando e tenha um ambiente completamente configurado, sem necessidade de conhecimentos avançados em Linux, Docker ou PostgreSQL.

---

## Funcionalidades

Atualmente o projeto realiza:

- Preparação do Ubuntu Server
- Instalação do Docker Engine
- Instalação do Docker Compose
- Criação da estrutura de diretórios
- Configuração do ambiente (.env)
- Criação do docker-compose
- Instalação do PostgreSQL
- Validação do banco de dados

---

## Estrutura do projeto

```
escalas-deploy
│
├── app
├── docker
├── docs
├── install.sh
├── scripts
│   ├── core
│   ├── lib
│   └── steps
├── sql
└── templates
```

---

## Como executar

Dar permissão de execução:

```bash
chmod +x install.sh scripts/core/*.sh scripts/steps/*.sh
```

Executar:

```bash
sudo ./install.sh
```

---

## Requisitos

- Ubuntu Server 24.04 ou superior
- Acesso sudo
- Conexão com a Internet

---

## Roadmap

- [x] Preparação do servidor
- [x] Instalação do Docker
- [x] Instalação do PostgreSQL
- [ ] Restore automático do banco
- [ ] Deploy da aplicação
- [ ] Atualização automática
- [ ] Backup automático
- [ ] Rollback
- [ ] Health Check
- [ ] HTTPS