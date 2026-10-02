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
- Teste online automático (host + cliente sem janela): `sh tests/run_online.sh`. Todos os testes: `sh tests/run_all.sh`.
- 4d — Nota e save: `core/combat/fight_grade.gd`, `core/save/save_game.gd` (autoload SaveGame), cartaz com nota. Teste: `tests/test_grade_save.tscn`.

## Próximos passos

1. 4e — Acabamento online: revisar o que ainda não sincroniza (balão saindo da tela, troca de fase com o cliente atrasado, parceiro que cai a conexão no meio da luta, "Tentar de novo" online) e cobrir com o teste online.
2. Etapa 5 — Primeira área (mapa de seleção, mais chefões, fase de plataforma).

## O que o usuário precisa testar na segunda

(Lista acumulada; cada etapa acrescenta a sua.)

1. **Especial** (Testar sozinho; F1 enche as estrelas): I / V / Y com 1 estrela solta o Rolhão (rolha gigante que atravessa o leão; no ar o personagem fica pairando um instante). Com 5 estrelas: palhaço = Torta na Cara (ergue e arremessa na direção da mira), acrobata = Salto Mortal (Tab troca de personagem; salta girando por cima do leão). Os dois ficam invencíveis durante o golpe.
2. **Grande Número em Dupla**: com as duas barras cheias (F1), solta o do palhaço, aperta Tab e solta o da acrobata em menos de 1 s: aparece "Grande Número em Dupla!" e a Torta de Ouro explode no leão.
3. **Objetos rosa novos**: onda rosa da Chicotada (fase 1), onda rosa da Patada (fase 2), brasas rosa nos Pulos (fase 3). Pular por cima e apertar pulo de novo encostando: estoura e ganha estrela.
4. **Online com o parceiro**: o mesmo; o Número Perfeito (os dois dando parry no mesmo objeto rosa quase juntos) dá 2 estrelas para cada um.
5. **Configurações > Controles**: linha nova "Especial", dá para trocar a tecla.
6. **Nota**: vencer o Domador mostra o cartaz com a nota (C/B/A/S), tempo, vida, parries, estrelas e "+3 ingressos para cada um" (só na 1ª vitória; depois só se melhorar a nota).
