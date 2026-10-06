#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/ufla-shop"
APP_USER="ufla-shop"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Verificando dependências de sistema..."
sudo apt-get update -y
sudo apt-get install -y python3-venv postgresql redis-server nginx openssl curl

echo "==> Garantindo serviços de infraestrutura ativos..."
sudo systemctl enable --now postgresql redis-server

echo "==> Criando usuário de sistema '${APP_USER}' caso não exista..."
id -u "${APP_USER}" &>/dev/null || sudo useradd -r -s /usr/sbin/nologin -d "${APP_DIR}" "${APP_USER}"

echo "==> Configurando arquivo de ambiente (/etc/ufla-shop.env)..."
if [ ! -f /etc/ufla-shop.env ]; then
    sudo tee /etc/ufla-shop.env > /dev/null << 'EOF'
DATABASE_URL=postgresql://loja:6666@localhost:5432/loja
REDIS_URL=redis://localhost:6379/0
EOF
    sudo chmod 600 /etc/ufla-shop.env
    sudo chown "${APP_USER}:${APP_USER}" /etc/ufla-shop.env
fi

echo "==> Sincronizando arquivos da aplicação em ${APP_DIR}..."
sudo mkdir -p "${APP_DIR}"
sudo cp -r "${CURRENT_DIR}/app" "${APP_DIR}/"
[ -d "${CURRENT_DIR}/static" ] && sudo cp -r "${CURRENT_DIR}/static" "${APP_DIR}/" || true
sudo cp "${CURRENT_DIR}/requirements.txt" "${APP_DIR}/"
sudo mkdir -p "${APP_DIR}/scripts"
sudo cp "${CURRENT_DIR}/scripts/backup.sh" "${APP_DIR}/scripts/"
sudo chmod +x "${APP_DIR}/scripts/backup.sh"

echo "==> Configurando virtualenv e dependências..."
if [ ! -d "${APP_DIR}/.venv" ]; then
    sudo python3 -m venv "${APP_DIR}/.venv"
fi
sudo "${APP_DIR}/.venv/bin/pip" install --upgrade pip
sudo "${APP_DIR}/.venv/bin/pip" install -r "${APP_DIR}/requirements.txt"

echo "==> Ajustando permissões de diretório..."
sudo chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"

echo "==> Gerando certificado TLS autoassinado..."
if [ ! -f /etc/ssl/certs/ufla-shop.crt ] || [ ! -f /etc/ssl/private/ufla-shop.key ]; then
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/ufla-shop.key \
        -out /etc/ssl/certs/ufla-shop.crt \
        -subj "/CN=localhost"
    sudo chmod 600 /etc/ssl/private/ufla-shop.key
fi

echo "==> Configurando Nginx..."
sudo cp "${CURRENT_DIR}/nginx/loja.conf" /etc/nginx/sites-available/loja.conf
sudo ln -sf /etc/nginx/sites-available/loja.conf /etc/nginx/sites-enabled/loja.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx || sudo systemctl restart nginx

echo "==> Instalando units e timer do systemd..."
sudo cp "${CURRENT_DIR}/systemd/ufla-shop.service" /etc/systemd/system/
sudo cp "${CURRENT_DIR}/systemd/ufla-shop-backup.service" /etc/systemd/system/
sudo cp "${CURRENT_DIR}/systemd/ufla-shop-backup.timer" /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable ufla-shop.service
sudo systemctl restart ufla-shop.service
sudo systemctl enable --now ufla-shop-backup.timer

echo "==> Executando healthcheck em http://localhost:8000/ready..."
SUCCESS=0
for i in {1..10}; do
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ready || true)
    if [ "${STATUS_CODE}" -eq 200 ]; then
        echo "Aplicação operacional e pronta (tentativa ${i})!"
        SUCCESS=1
        break
    fi
    echo "Tentativa ${i}/10 falhou (Status: ${STATUS_CODE}). Aguardando 1s..."
    sleep 1
done

if [ "${SUCCESS}" -ne 1 ]; then
    echo "ERRO: O healthcheck não respondeu com código 200 após 10 tentativas."
    exit 1
fi
