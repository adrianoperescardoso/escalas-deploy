#!/usr/bin/env python3
"""Normaliza somente diferenças de representação dos dumps PostgreSQL.

Mantém DDL completo, incluindo constraints, índices, triggers e funções.
Remove cabeçalhos variáveis e nomes de constraints NOT NULL inline, pois
a obrigatoriedade permanece representada por NOT NULL nas duas versões.
Nunca usar este arquivo normalizado para restaurar/migrar: somente diff.
"""
import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("Uso: normalize-schema.py entrada.sql saida.sql")

inline_named_not_null = re.compile(
    r'\s+CONSTRAINT\s+(?:"(?:[^"]|"")*"|[A-Za-z_][A-Za-z_0-9$]*)'
    r'\s+NOT NULL(?=,?\s*$)',
    flags=re.IGNORECASE,
)
normalized = []
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    if re.match(r"^\\(?:restrict|unrestrict)\s", line):
        continue
    if line.startswith((
        "-- Dumped from database version",
        "-- Dumped by pg_dump version",
        "-- PostgreSQL database dump",
    )):
        continue
    if line.startswith("    ") and " CONSTRAINT " in line.upper() and " NOT NULL" in line.upper():
        line = inline_named_not_null.sub(" NOT NULL", line)
    if not line.strip():
        continue
    normalized.append(line.rstrip())

Path(sys.argv[2]).write_text("\n".join(normalized) + "\n", encoding="utf-8")
