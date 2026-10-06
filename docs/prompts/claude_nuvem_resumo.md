# Resumo para continuar numa sessão nova do Claude (05/10/2026)

Ler antes: `CLAUDE.md`, `docs/DESIGN.md` e `docs/REMAP_VISUAL.md`. Conversa, documentação e commits em
português do Brasil; código em inglês. O usuário é o diretor e testador; ao fim de cada tarefa, dizer
exatamente o que testar na Godot. Decisões de design: perguntar uma de cada vez, com recomendação.

## Como está o jogo
- Área 1 completa: mapa, Domador, Malabaristas, Trem do Circo, Grande Mágico, loja e Camarim, sozinho e online.
- Menu: "Jogar sozinho" (um personagem só, save à parte; Tab no mapa troca; o "Testar sozinho" está guardado e
  escondido: `SHOW_TEST_MODE` em `core/ui/main_menu.gd`),
  Hospedar e Entrar. Pausa nas lutas tem "Voltar ao mapa".
- Testes: `sh tests/run_all.sh` (todas as lutas, loja, mapa, trem, itens, jogar sozinho, modo de teste e online normal e com
  rede ruim). Último resultado: tudo passando.

## O que foi feito hoje (ver `git log`)
- Tela de carregamento animada; mapa da Área 1 refeito várias vezes. Hoje ele é o **mapa ampliado em quatro
  partes** (`levels/world/art/park_0*.png`), com câmera que segue a dupla e mostra uma região por vez, área
  andável vinda de uma máscara da terra pintada (`levels/world/art/park_walk.png`, gerada por
  `tools/blender/park_walk_mask.py`), alargada uns 20 px e com a beira lisa; quem bate na beira escorrega.
  Velocidade no mapa 4,6 m/s. Personagens do mapa usam os PNGs da luta (`core/world/map_sprite.gd`), com o
  desenho deslizando entre os passos da física.
- Malabaristas: totem 30% maior e monociclo mais baixo (pegam quem está na tábua); os irmãos em cima do
  monociclo ganharam desenho (folha do ChatGPT, `bosses/jugglers/art/unicycle/`).
- Leque de Confete vai mais longe: 0,55 s ≈ 830 px, leque de ±8,6° (era 0,3 s ≈ 450 px e ±12°).
- HUD das lutas (`core/ui/fight_hud.gd`): ingresso maior, corações e estrelas maiores e com contraste; a
  estrela carregando enche de baixo para cima; com as 5 cheias, brilho atrás delas.

## Pendências (por ordem)
1. **Pedidos de arte ao ChatGPT** (ele tem acesso ao projeto): `docs/prompts/chatgpt_armas_trem_itens.md`
   (A: pistolas e tiros; B: fase do Trem; C: ícones dos 17 itens) e o Pedido 2 de
   `docs/prompts/chatgpt_monociclo.md` (o monociclo em peças). Quando chegarem: conferir, normalizar e ligar
   no jogo sem mudar números da luta.
2. Feedback do usuário sobre o andar no mapa, o HUD novo e o Leque de Confete.
3. Ideias sugeridas ao usuário: som e música (não existe nada ainda), recortes do mapa para os personagens
   passarem atrás do arco e dos lampiões, imagens maiores do mapa, animações que faltam aos personagens (pulo,
   dash, abaixado, dano), design da Área 2.

## Cuidados
- Godot 4.7.2 com renderizador Compatibility (PC fraco). No PC do usuário: Godot em
  `C:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`, Blender 4.5 em
  `C:/Users/roberto.gabriel/.codex/tools/blender-4.5.14-windows-x64/blender.exe`. Não chamar `python` no PC
  do usuário (abre a loja da Microsoft e trava). Na nuvem esses programas podem não existir: aí não dá para
  rodar os testes nem gerar imagens; avisar o usuário.
- O `git push` mostra um erro inofensivo de "geometric repack" (refs do Codex); o push funciona.
- Arquivos soltos que são do usuário e não entram nos commits: `core/world/models/clown_xadrez.png.import`,
  `docs/referencias/remap_conceitos/` (exceto `mapa_amplo_4partes/`) e `monociclo_candidata.png`.
