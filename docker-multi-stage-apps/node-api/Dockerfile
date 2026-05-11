# ============================================================
# Dockerfile — Node.js API com multi-stage build
# Stage 1: instala dependências e builda
# Stage 2: imagem mínima apenas com o necessário para rodar
# ============================================================

# ── Stage 1: Builder ─────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar apenas os arquivos de dependências primeiro
# (aproveita cache do Docker — só reinstala se package.json mudar)
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm ci --only=production && npm cache clean --force

# Copiar o código fonte
COPY src/ ./src/

# ── Stage 2: Runner (imagem final mínima) ────────────────────
FROM node:20-alpine AS runner

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

WORKDIR /app

# Copiar apenas o necessário do stage builder
COPY --from=builder --chown=nodeuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodeuser:nodejs /app/src ./src
COPY --chown=nodeuser:nodejs package.json ./

# Usar o usuário não-root
USER nodeuser

# Expor porta da aplicação
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Comando de inicialização
CMD ["node", "src/server.js"]
