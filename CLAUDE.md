# Léguas

Jogo de caminhada com visual pintado em SVG (Crepúsculo austral). Spec: `docs/superpowers/specs/2026-09-25-leguas-design.md`. Estilo: `STYLE.md`.

- Rails 8 + SQLite + Hotwire + Tailwind 4. JS em `app/frontend/`.
- Conteúdo do mundo em `config/world/*.yml`, arte em SVG em `app/assets/images/art/`. Nada disso vai pro banco.
- Progresso é sempre calculado da soma das caminhadas (`User::Journey`). Nunca grave posição/XP.
- TDD sempre: `bin/rails test`, `bin/rails test:system`.
- Testes de lógica usam o mundo pequeno de `test/world/` (fora de `test/fixtures`, porque `fixtures :all` carrega subpastas).
