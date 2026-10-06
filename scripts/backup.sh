#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups/ufla-shop"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/loja-${TIMESTAMP}.sql.gz"

# Garante que o diretório de destino exista
mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

# Executa o dump comprimido
# Usa DATABASE_URL do EnvironmentFile carregado pelo systemd
if [ -n "${DATABASE_URL:-}" ]; then
  pg_dump "${DATABASE_URL}" | gzip > "${BACKUP_FILE}"
else
  pg_dump -U loja -h localhost loja | gzip > "${BACKUP_FILE}"
fi

# Notifica o syslog/journal com nome e tamanho
FILE_SIZE=$(ls -lh "${BACKUP_FILE}" | awk '{print $5}')
logger -t backup "Backup gerado com sucesso: ${BACKUP_FILE} (Tamanho: ${FILE_SIZE})"

# Rotação: mantém apenas os 7 arquivos mais recentes e remove o excedente
find "${BACKUP_DIR}" -maxdepth 1 -name "loja-*.sql.gz" -type f -printf '%T@ %p\n' \
  | sort -rn \
  | awk 'NR > 7 {print $2}' \
  | xargs -r rm -f
