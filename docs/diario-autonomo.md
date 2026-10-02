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
- 4e — Acabamento online: aviso de saída na hora, parceiro que volta alcança a fase/vida do chefão, teste online com pontos de encontro (estável, também com internet ruim). `sh tests/run_all.sh` roda tudo.
- 5a — Mapa do parque (`levels/circus_map/`, tendas em `components/stage/map_door.gd`): menu abre o mapa, entrar nas tendas, "Voltar ao mapa", save ao chegar, online começa pelo mapa. Teste: `tests/test_map.tscn` e o online. Prompt de arte: `docs/prompts/codex_mapa.md`.
- 5b — Irmãos Malabaristas (`bosses/jugglers/`): luta completa, mecânica de duas vidas / tontura / cura, barras por irmão. Cérebro genérico de chefão em `components/boss/boss_brain.gd`. Testes: `tests/test_jugglers.tscn`, `tests/test_boss_smoke.tscn` (roda as duas lutas inteiras). Fotos sem jogar: `tests/screenshots.tscn` (com janela). Prompt de arte: `docs/prompts/codex_malabaristas.md`.

## Próximos passos

1. 5c — Corrida no Trem do Circo (fase de plataforma, docs/bosses.md "Área 1"): correr e atirar em cima dos vagões em movimento. Precisa de câmera que anda (as lutas têm arena fixa) e de inimigos pequenos (componente novo). Ligar na tenda DoorTrain do mapa; ao chegar no fim, registrar vitória no save (level_id "train").
2. 5d — Mágico, 5e — Loja.

## O que o usuário precisa testar na segunda

(Lista acumulada; cada etapa acrescenta a sua.)

1. **Especial** (Testar sozinho; F1 enche as estrelas): I / V / Y com 1 estrela solta o Rolhão (rolha gigante que atravessa o leão; no ar o personagem fica pairando um instante). Com 5 estrelas: palhaço = Torta na Cara (ergue e arremessa na direção da mira), acrobata = Salto Mortal (Tab troca de personagem; salta girando por cima do leão). Os dois ficam invencíveis durante o golpe.
2. **Grande Número em Dupla**: com as duas barras cheias (F1), solta o do palhaço, aperta Tab e solta o da acrobata em menos de 1 s: aparece "Grande Número em Dupla!" e a Torta de Ouro explode no leão.
3. **Objetos rosa novos**: onda rosa da Chicotada (fase 1), onda rosa da Patada (fase 2), brasas rosa nos Pulos (fase 3). Pular por cima e apertar pulo de novo encostando: estoura e ganha estrela.
4. **Online com o parceiro**: o mesmo; o Número Perfeito (os dois dando parry no mesmo objeto rosa quase juntos) dá 2 estrelas para cada um.
5. **Configurações > Controles**: linha nova "Especial", dá para trocar a tecla.
. **Online**: o parceiro sair pelo menu e entrar de novo no meio da luta: ele volta vendo o chefão na fase e com a vida certas.
