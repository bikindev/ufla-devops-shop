# ==========================================================
# Estágio 1: Builder (compilação e instalação das dependências)
# ==========================================================
FROM python:3.12-alpine AS builder

WORKDIR /build

# Instala ferramentas necessárias para eventuais compilações de pacotes C
RUN apk add --no-cache gcc musl-dev libffi-dev

COPY requirements.txt .

# Cria um virtualenv isolado e instala as dependências sem cache de rodas
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# ==========================================================
# Estágio 2: Runtime Final (imagem enxuta de produção)
# ==========================================================
FROM python:3.12-alpine AS runner

WORKDIR /app

# Variáveis para otimizar execução do Python em containers
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Cria usuário e grupo não-root 'appuser'
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia apenas o ambiente virtual pronto do estágio builder
COPY --from=builder /opt/venv /opt/venv

# Copia o código da aplicação e arquivos estáticos
COPY app/ ./app/
COPY static/ ./static/

# Cria pasta para dados (SQLite) e ajusta permissões para o usuário não-root
RUN chown -R appuser:appgroup /app

# Altera para o usuário não-root
USER appuser

# Healthcheck interno usando urllib do Python padrão (sem necessidade de curl)
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"]

# Porta documentada
EXPOSE 8000

# Exec form para receber sinais do SO (SIGTERM) direto no uvicorn
CMD ["uvicorn", "app:api", "--host", "0.0.0.0", "--port", "8000"]
