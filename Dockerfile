# ==========================================================
# Estágio 1: Builder (compilação no Alpine)
# ==========================================================
FROM python:3.12-alpine AS builder

WORKDIR /build

# Ferramentas mínimas para compilação
RUN apk add --no-cache gcc musl-dev libffi-dev

COPY requirements.txt .

# Cria o virtualenv, instala pacotes sem cache e faz uma limpeza interna profunda
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt && \
    # Remove o próprio pip, setuptools e wheel do venv final para economizar espaço
    /opt/venv/bin/pip uninstall -y pip setuptools wheel && \
    # Remove arquivos de teste, caches e documentações deixadas pelas dependências
    find /opt/venv -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/venv -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/venv -type f -name "*.pyc" -delete

# ==========================================================
# Estágio 2: Runtime Final (Alpine mínimo)
# ==========================================================
FROM python:3.12-alpine AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Cria usuário não-root 'appuser'
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia apenas o venv limpo e enxuto
COPY --from=builder /opt/venv /opt/venv

# Copia estritamente os diretórios do projeto
COPY app/ ./app/
COPY static/ ./static/

# Concede permissão da pasta ao usuário não-root
RUN chown -R appuser:appgroup /app

USER appuser

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"]

EXPOSE 8000

CMD ["uvicorn", "app:api", "--host", "0.0.0.0", "--port", "8000"]