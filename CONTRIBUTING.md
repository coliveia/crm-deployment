# Contribuindo para CRM+ Deployment

## 📋 Diretrizes

### Commits
- Use mensagens claras e descritivas
- Prefixos: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`
- Exemplo: `feat: add prometheus monitoring`

### Branches
- `main` - Produção (protegida)
- `develop` - Desenvolvimento
- `feature/*` - Novas funcionalidades
- `fix/*` - Correções de bugs
- `docs/*` - Documentação

### Pull Requests
- Descreva as mudanças claramente
- Referencie issues relacionadas
- Aguarde revisão antes de merge

### Segurança
- **NUNCA** commit credenciais ou senhas
- **NUNCA** commit arquivos do wallet
- Use `.gitignore` para arquivos sensíveis
- Use Secrets do GitHub para CI/CD

## 🔄 Workflow

1. Clone o repositório
2. Crie uma branch: `git checkout -b feature/sua-feature`
3. Faça as mudanças
4. Commit: `git commit -m "feat: descrição"`
5. Push: `git push origin feature/sua-feature`
6. Abra um Pull Request

## 📝 Estrutura de Commits

```
feat: adicionar novo Helm Chart
fix: corrigir configuração de recursos
docs: atualizar guia de deployment
chore: atualizar dependências
refactor: reorganizar estrutura de pastas
```

## 🧪 Testes Antes de Commit

```bash
# Validar YAML
yamllint helm-charts/*/templates/*.yaml

# Validar Helm
helm lint helm-charts/crm-backend/
helm lint helm-charts/crm-bff/
helm lint helm-charts/crm-frontend/

# Validar scripts
shellcheck scripts/deploy.sh
```

## 📚 Documentação

- Atualize `README.md` para mudanças gerais
- Atualize `DEPLOYMENT_GUIDE.md` para mudanças de procedimento
- Adicione comentários em arquivos complexos

## 🐛 Reportando Issues

Inclua:
- Descrição clara do problema
- Passos para reproduzir
- Comportamento esperado vs. atual
- Ambiente (Azure, Kubernetes version, etc.)

## 📞 Contato

Para dúvidas, abra uma issue ou entre em contato com o time de DevOps.
