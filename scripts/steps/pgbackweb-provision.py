#!/usr/bin/env python3
"""Configura o PG Back Web 0.5.2 pelos formulários da própria aplicação.

Estes caminhos web são internos: manter a imagem fixada e testar ao atualizá-la.
Nenhuma senha é enviada à saída do instalador ou à linha de comando.
"""

import http.cookiejar
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path


def credentials(path):
    result = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            result[key] = value.strip('"')
    return result


def query(container, postgres_user, database, sql):
    result = subprocess.run(
        ["docker", "exec", container, "psql", "-X", "-At", "-U", postgres_user,
         "-d", database, "-c", sql],
        check=True, text=True, capture_output=True,
    )
    return result.stdout.strip()


def post(opener, base, path, fields):
    request = urllib.request.Request(
        base + path,
        data=urllib.parse.urlencode(fields).encode("utf-8"),
        headers={"HX-Request": "true", "Content-Type": "application/x-www-form-urlencoded"},
    )
    with opener.open(request, timeout=15) as response:
        response.read()


def main():
    env_file, container, postgres_user, base = sys.argv[1:]
    env = credentials(env_file)
    opener = urllib.request.build_opener(
        urllib.request.ProxyHandler({}),
        urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    if query(container, postgres_user, "pgbackweb", "SELECT count(*) FROM users") == "0":
        post(opener, base, "/auth/create-first-user", {
            "name": env["PBW_ADMIN_NAME"],
            "email": env["PBW_ADMIN_EMAIL"],
            "password": env["PBW_ADMIN_PASSWORD"],
            "password_confirmation": env["PBW_ADMIN_PASSWORD"],
        })
        if query(container, postgres_user, "pgbackweb", "SELECT count(*) FROM users") != "1":
            raise RuntimeError("não foi possível criar o administrador web")
        print("Administrador web criado.")

    db_count = query(container, postgres_user, "pgbackweb",
                     "SELECT count(*) FROM databases WHERE name = 'EscalasPro'")
    backup_count = query(container, postgres_user, "pgbackweb",
                         "SELECT count(*) FROM backups WHERE name = 'EscalasPro - backup horario'")
    desired_backup_count = query(container, postgres_user, "pgbackweb", """
        SELECT count(*) FROM backups b JOIN databases d ON d.id = b.database_id
        WHERE b.name = 'EscalasPro - backup horario' AND d.name = 'EscalasPro'
          AND b.is_local AND b.is_active AND b.cron_expression = '0 * * * *'
          AND b.time_zone = 'America/Porto_Velho' AND b.dest_dir = '/escalas'
          AND b.retention_days = 60 AND NOT b.opt_data_only AND NOT b.opt_schema_only
    """)
    if backup_count != "0" and desired_backup_count != backup_count:
        raise RuntimeError("a tarefa existente tem parâmetros diferentes; revise-a na interface")
    if db_count != "0" and backup_count != "0":
        print("Banco e tarefa de backup já cadastrados; configurações preservadas.")
        return

    post(opener, base, "/auth/login", {
        "email": env["PBW_ADMIN_EMAIL"], "password": env["PBW_ADMIN_PASSWORD"],
    })
    with opener.open(base + "/dashboard", timeout=15) as response:
        if "/dashboard" not in response.geturl():
            raise RuntimeError("login do administrador falhou; confira as credenciais guardadas")

    if db_count == "0":
        post(opener, base, "/dashboard/databases", {
            "name": "EscalasPro", "version": "17",
            "connection_string": env["ESCALAS_BACKUP_CONN_STRING"],
        })
        db_count = query(container, postgres_user, "pgbackweb",
                         "SELECT count(*) FROM databases WHERE name = 'EscalasPro'")
        if db_count != "1":
            raise RuntimeError("não foi possível cadastrar o banco EscalasPro")
        print("Conexão com EscalasPro cadastrada.")

    if backup_count == "0":
        database_id = query(container, postgres_user, "pgbackweb",
                            "SELECT id FROM databases WHERE name = 'EscalasPro'")
        fields = {
            "name": "EscalasPro - backup horario", "database_id": database_id,
            "is_local": "true", "cron_expression": "0 * * * *",
            "time_zone": "America/Porto_Velho", "is_active": "true",
            "dest_dir": "/escalas", "retention_days": "60",
        }
        for option in ("data_only", "schema_only", "clean", "if_exists", "create", "no_comments"):
            fields["opt_" + option] = "false"
        post(opener, base, "/dashboard/backups", fields)
        found = query(container, postgres_user, "pgbackweb", """
            SELECT count(*) FROM backups WHERE name = 'EscalasPro - backup horario'
              AND is_active AND is_local AND cron_expression = '0 * * * *'
              AND retention_days = 60 AND dest_dir = '/escalas'
        """)
        if found != "1":
            raise RuntimeError("não foi possível ativar a tarefa de backup")
        print("Backup horário ativado com retenção de 60 dias.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Exceções de rede podem incluir URL/credenciais. Não as grave no log.
        print(f"Falha na configuração inicial do PG Back Web: {type(error).__name__}: "
              f"{error if isinstance(error, RuntimeError) else 'verifique o serviço e o log da aplicação'}",
              file=sys.stderr)
        sys.exit(1)
