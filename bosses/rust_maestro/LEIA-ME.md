# Maestro Ferrugem

Regente mecânico das Oficinas da Meia-Noite (Área 3). A luta está jogável pela tenda
do Maestro no mapa da Área 3 (`DoorMaestro`), em solo e em dupla, no PC e no celular.

## Decisões com o usuário (19/10/2026)

- Ordem da Área 3: o Maestro é o segundo chefão, depois da Madame Carretel. Seu
  Contrapeso, Mudança de Cenário e O Palco Insaciável continuam "Em breve".
- Arte: o boneco é o desenho-base `art/p01_base.png` recortado em peças e animado
  por código (aprovado). Os efeitos dos ataques são desenhados por código.
- Cenário: provisório, feito em código (aprovado), até chegar o cenário pintado.
- Ataques e fases: proposta aprovada sem mudanças, incluindo o compasso visível
  (metrônomo marcando o ritmo da luta).
- Decisões registradas neste LEIA-ME, porque `docs/` não vai para o git.

## A luta

1250 PV em três fases. Ele rege num compasso de 100 batidas por minuto (`BEAT` = 0,6 s):
cada ataque dura um número inteiro de tempos, e o respiro entre ataques é um tempo.
Assim todo golpe cai na batida do metrônomo do palco, que zera no começo de cada
ataque nos dois PCs. Os avisos duram de 0,9 a 1,2 s, como na Madame.

| Fase | Ataques |
|---|---|
| 1. Afinação | Pauta, Batutada, Metrônomo |
| 2. Crescendo (o órgão das costas acorda e solta vapor) | Ondas graves, Colcheias, Pauta + Ondas |
| 3. Fortíssimo (tudo 12% mais rápido) | Tubos de órgão, Pauta + Colcheias, Batutada + Ondas |

- **Pauta:** três linhas acendem: chão, meio e alto. As notas saem da beira direita, uma
  por tempo, e crescem um tempo antes de sair (nessa hora ainda não machucam). Para
  desviar: pular a nota do chão, abaixar ou pular a do meio, não pular na hora da alta.
  Acordes só em pares que têm saída (chão + meio: um pulo passa; meio + alto: abaixar
  passa). Uma nota turquesa aceita parry. A pauta simples sempre tem as três alturas.
- **Batutada:** o leque à frente dele fica marcado, e o golpe da batuta varre do ombro até
  o chão na frente dele. Cada golpe solta uma lâmina de som que corre pelo chão (pular).
- **Metrônomo:** um peso serrilhado desce do teto e balança de parede a parede, duas
  passadas no compasso. Ele passa baixo no meio do palco (pular) e alto perto das paredes.
  O caminho fica pontilhado no aviso.
- **Ondas graves:** os tubos das costas sopram, e três ondas correm pelo chão, uma a cada
  dois tempos (pular cada uma).
- **Colcheias:** pares de notas ligadas caem onde cada jogador estava, depois ao lado e
  depois do outro lado. A marca no chão aparece antes.
- **Tubos de órgão:** sai vapor do chão sob cada jogador e a coluna fica marcada. Dois
  tempos depois, sobe um tubo até o alto que sopra som. Não dá para pular: é preciso sair
  de baixo. São duas rodadas.
- **Combos:** o segundo perigo começa um tempo depois do primeiro. Na Pauta + Ondas, notas
  e ondas têm a mesma velocidade, e por isso nunca sai nota alta na mesma coluna de uma
  onda (pular a onda daria de cara com a nota).
- **Reverência (fase 3):** toda música termina com ele se curvando. A caixa de música do
  colete abre com o aro claro dos pontos fracos e, enquanto está aberta, é a única parte
  que leva tiro, com dano dobrado.

Valem as mesmas proteções da Madame:

- A parede só limita o jogador, e os tiros atravessam (`components/boss/arena_shots_pass_walls.gd`,
  agora compartilhado pelas duas lutas).
- Os alvos travam no aviso.
- Tiro recebido só dá um brilho de 0,07 s, sem trocar a pose.
- Cancelar, aparar ou vencer desliga os perigos.
- O saco de ataques garante a pauta em toda fase.

## Arquivos

- `rust_maestro_boss.gd`: cérebro (fases, compasso, alvos, dano dobrado na caixa).
- `maestro_actor.gd`: boneco articulado (peças, poses, regência no compasso, vapor dos
  tubos, caixa de música). As peças vêm de `tools/cut_maestro_rig.py`. Para refazer:
  `python3 tools/cut_maestro_rig.py`.
- `maestro_attack.gd`: linhas do tempo de todos os ataques, combos e trocas de fase.
- `maestro_threat.gd`: cada perigo desenhado por código, com a colisão só na parte sólida.
- `maestro_arena.gd` e `shaders/maestro_stage.gdshader`: palco provisório (parede de
  oficina, assoalho, órgão de fundo apagado, cortinas e o metrônomo do compasso).
- `rust_maestro_visual.tscn`: desenho-base inteiro (prévia da arte em `tools/maestro_art_preview.tscn`).

## Testes

- `tests/test_maestro.tscn`: porta, vida/fases, compasso, nenhum ponto parado seguro
  (6 posições × 3 alturas × 3 fases), cada ataque desenha e machuca, alcance da batuta,
  aviso travado, parry, combos, reverência com tiro de verdade, vitória, derrota, toque
  e parado atirando nos dois cantos.
- `tests/test_maestro_online.tscn`: rodar com `TEST_SCENE=res://tests/test_maestro_online.tscn sh tests/run_online.sh [ruim]`.
- Entrou também em `test_boss_smoke` e `test_safe_spots`.
- Fotos: `tools/maestro_fight_capture.tscn` (precisa de janela), salvas em `build/qa/maestro/fight/`.

## Próximos passos possíveis

- Cenário pintado (escrevo o prompt quando for a hora).
- Folhas de animação desenhadas, para trocar o boneco recortado onde ficar duro.
