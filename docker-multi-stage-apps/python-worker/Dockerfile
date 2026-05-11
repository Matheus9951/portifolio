# ============================================================
# Dockerfile — Python Worker com multi-stage build
# Usa imagem slim para reduzir tamanho e superfície de ataque
# ============================================================

# ── Stage 1: Builder — instala dependências ──────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

# Instalar dependências de build
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependências Python em diretório isolado
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runner — imagem final mínima ────────────────────
FROM python:3.12-slim AS runner

# Criar usuário não-root
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# Copiar dependências instaladas do stage builder
COPY --from=builder /install /usr/local

# Copiar código da aplicação
COPY --chown=appuser:appgroup app/ ./app/

# Usar usuário não-root
USER appuser

EXPOSE 8000

# Health check para o FastAPI
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
