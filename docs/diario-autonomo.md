# Diário do trabalho autônomo (fim de semana de 03 a 05/10/2026)

O usuário saiu na sexta (02/10) à noite e volta na segunda (05/10). Ele pediu para o Claude
seguir o roadmap sozinho, por fases, confiando nos próprios testes, e continuar quando o limite
de uso voltar. Este arquivo é o ponto de partida de cada retomada: **ler antes de continuar**.

## Regras combinadas

- Seguir o roadmap do docs/DESIGN.md na ordem, sem pular etapas.
- Decisões de design: o Claude decide sozinho, escolhe a opção mais simples e fiel ao
  docs/DESIGN.md, e registra aqui e no DESIGN.md como "decidido pelo Claude, revisar".
- Toda parte nova ganha teste automático em `tests/` (rodar sem janela:
  `Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 res://tests/<teste>.tscn`;
  o Godot fica em `C:\Godot_v4.7.2-stable_win64.exe\`). Só fazer commit com os testes passando.
- Commits pequenos, em português. Sem push.
- Arte: continua provisória (SVG / desenho por código); pedidos de arte novos vão para `docs/prompts/`.

## Feito

- 4c parte 2 (commit a864d74): Especial, Tiro EX, Grande Número, Número Perfeito, Grande Número
  em Dupla, ataques rosa. Teste: `tests/test_special.tscn` (31 verificações).
- Prompt do Codex para parry, balão e especiais: `docs/prompts/codex_parry_balao_especiais.md`.

## Próximos passos

1. Teste automático online (host + cliente em dois processos sem janela) para o Especial.
2. 4d — Nota e save.
3. 4e — Acabamento online.
4. Etapa 5 — Primeira área (mapa de seleção, mais chefões, fase de plataforma).

## O que o usuário precisa testar na segunda

(Lista acumulada; cada etapa acrescenta a sua.)
