# Escalas Deploy

## Objetivo

O Escalas Deploy é um projeto responsável por automatizar toda a implantação da aplicação Escalas em um servidor Ubuntu utilizando Docker.

O objetivo é permitir que qualquer pessoa execute o instalador e tenha um ambiente completamente configurado, sem necessidade de conhecimentos avançados em Linux, Docker, PostgreSQL ou GeneXus.

---

## Funcionalidades

Atualmente o projeto realiza automaticamente:

- Preparação do Ubuntu Server
- Instalação do Docker Engine
- Instalação do Docker Compose
- Criação da estrutura de diretórios
- Download dos artefatos da aplicação
- Restauração automática do banco PostgreSQL
- Parametrização automática do `appsettings.json`
- Parametrização automática do `connection.gam`
- Build da imagem Docker da aplicação
- Configuração do Docker Compose
- Inicialização da aplicação
- Validação do ambiente
- Exibição das informações de acesso ao final da instalação

---

## Estrutura do projeto

```text
escalas-deploy
│
├── app
├── docker
├── docs
├── scripts
│   ├── core
│   ├── lib
│   └── steps
├── sql
├── templates
├── tmp
├── install.sh
├── README.md
└── ROADMAP.md
```

---

# Instalação

## 1. Atualize os pacotes do sistema

```bash
sudo apt update
```

## 2. Instale o Git

```bash
sudo apt install -y git
```

## 3. Clone o projeto

```bash
git clone https://github.com/adrianoperescardoso/escalas-deploy.git
```

## 4. Acesse o diretório do projeto

```bash
cd escalas-deploy
```

## 5. Execute o instalador

```bash
sudo ./install.sh
```

Ao final da instalação serão exibidas as informações de acesso à aplicação e ao banco de dados.

---

## Requisitos

- Ubuntu Server 24.04 ou superior
- Acesso sudo
- Conexão com a Internet

---

## Roadmap

### MVP

- [x] Preparação do servidor
- [x] Instalação do Docker
- [x] Instalação do Docker Compose
- [x] Criação da estrutura de diretórios
- [x] Download dos artefatos
- [x] Restauração automática do PostgreSQL
- [x] Parametrização do appsettings.json
- [x] Parametrização do connection.gam
- [x] Build automático da imagem Docker
- [x] Configuração do Docker Compose
- [x] Inicialização automática da aplicação
- [x] Exibição das informações de acesso

### Próximas versões

- [ ] Atualização automática
- [ ] Backup automático
- [ ] Rollback
- [ ] Health Check
- [ ] HTTPS