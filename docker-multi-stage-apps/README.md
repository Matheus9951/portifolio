# 🐳 Docker Multi-Stage Builds — Imagens Otimizadas para Produção

Exemplos práticos de Dockerfiles com multi-stage build para reduzir o tamanho das imagens e melhorar a segurança em produção.

## 🎯 Por que multi-stage?

| Abordagem | Tamanho da imagem | Segurança |
|-----------|-------------------|-----------|
| Imagem simples (node:18) | ~1.1 GB | Baixa (inclui compilador, npm, etc.) |
| Multi-stage (distroless) | ~150 MB | Alta (apenas o binário final) |

**Resultado: imagem 7x menor e sem ferramentas de ataque na imagem final.**

## 📁 Projetos

| Pasta | Stack | Tamanho final |
|-------|-------|---------------|
| `node-api/` | Node.js 20 + Express | ~150 MB |
| `python-worker/` | Python 3.12 + FastAPI | ~120 MB |
| `nginx-proxy/` | Nginx com config customizada | ~25 MB |

## 🔐 Boas práticas aplicadas

- ✅ Multi-stage build (builder → runner)
- ✅ Usuário não-root na imagem final
- ✅ Imagem base distroless/alpine
- ✅ `.dockerignore` para excluir arquivos desnecessários
- ✅ Layers otimizados (dependências antes do código)
- ✅ Health check declarado no Dockerfile
- ✅ Sem secrets no build (use `--secret` ou variáveis em runtime)
