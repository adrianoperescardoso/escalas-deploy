# ============================================================
# Imagem base
# ------------------------------------------------------------
# Utiliza a imagem oficial do ASP.NET 8 Runtime, responsável
# por executar aplicações .NET em ambiente Linux.
# ============================================================

FROM mcr.microsoft.com/dotnet/aspnet:8.0

# ============================================================
# Metadados da imagem
# ------------------------------------------------------------
# Informações úteis para identificar quem mantém a imagem e
# qual aplicação ela representa.
# ============================================================

LABEL maintainer="Adriano Peres Cardoso"
LABEL application="Sistema Escalas"

# ============================================================
# Variáveis de ambiente
# ------------------------------------------------------------
# ASPNETCORE_URLS:
#   Define em qual porta a aplicação ficará disponível.
#
# DOTNET_SYSTEM_GLOBALIZATION_INVARIANT:
#   Habilita suporte completo à localização, acentuação,
#   datas e moedas.
#
# TZ:
#   Define o fuso horário do container.
#
# LANG:
#   Define o idioma padrão utilizado pelo sistema.
# ============================================================

ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV TZ=America/Porto_Velho
ENV LANG=pt_BR.UTF-8

# ============================================================
# Diretório de trabalho
# ------------------------------------------------------------
# Todos os comandos seguintes serão executados dentro de /app.
# Também será o diretório onde a aplicação ficará armazenada.
# ============================================================

WORKDIR /app

# ============================================================
# Instalação de dependências
# ------------------------------------------------------------
# libgdiplus
#   Necessária para recursos gráficos utilizados pelo GeneXus.
#
# gettext
#   Disponibiliza o comando "envsubst", utilizado para substituir
#   variáveis de ambiente dentro dos arquivos de configuração.
#
# tzdata
#   Permite configurar corretamente o fuso horário.
#
# curl
#   Ferramenta utilizada para testes e futuras verificações
#   de saúde (Health Check).
#
# Ao final, remove o cache do apt para reduzir o tamanho
# da imagem Docker.
# ============================================================

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libgdiplus \
       gettext \
       tzdata \
       curl \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Copia todos os arquivos da aplicação para dentro do container.
# ============================================================

COPY . .

# ============================================================
# Cria um usuário específico para executar a aplicação.
#
# Evita executar a aplicação como usuário root, aumentando
# significativamente a segurança do container.
# ============================================================

RUN groupadd -r appusers \
    && useradd -r -g appusers appuser \
    && chown -R appuser:appusers /app

USER appuser

# ============================================================
# Porta utilizada pela aplicação.
#
# Esta porta será posteriormente publicada pelo Docker Compose,
# permitindo acesso à aplicação através do navegador.
# ============================================================

EXPOSE 8080

# ============================================================
# Inicialização da aplicação
# ------------------------------------------------------------
# Antes de iniciar o sistema, o comando envsubst substitui
# automaticamente variáveis de ambiente dentro dos arquivos:
#
#   - appsettings.json
#   - connection.gam (quando existir)
#
# Isso permite reutilizar a mesma imagem Docker em diferentes
# ambientes (Desenvolvimento, Homologação e Produção),
# alterando apenas as variáveis de ambiente.
# ============================================================

ENTRYPOINT ["/bin/sh", "-c", "\
envsubst < /app/appsettings.json > /app/appsettings_temp.json && \
mv /app/appsettings_temp.json /app/appsettings.json && \
if [ -f /app/connection.gam ]; then \
    envsubst < /app/connection.gam > /app/connection_temp.gam && \
    mv /app/connection_temp.gam /app/connection.gam; \
fi && \
exec \"$@\"", "--"]

# ============================================================
# Executa a aplicação GeneXus.
#
# O arquivo GxNetCoreStartup.dll é o ponto de entrada
# responsável por iniciar todo o sistema.
# ============================================================

CMD ["dotnet", "bin/GxNetCoreStartup.dll"]