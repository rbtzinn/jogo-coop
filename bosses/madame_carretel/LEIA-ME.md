# Arte animada — Madame Carretel

Esta pasta contém a cena visual e36quadros de9animações:
espera/piscar, tesoura, fita métrica, agulhas, tecido, dano,
transformação do vestido mecânico, ataque mecânico e derrota.

Para conferir no Godot, abra `res://tools/carretel_animation_preview.tscn` e aperteF6.
Use os botões ou as setas para escolher a sequência; Espaço pausa/continua,
Enter repete eA alterna a demonstração automática.

`carretel_visual.tscn` usa AnimatedSprite2D/SpriteFrames e oferece `play(nome)`
para futura integração com a luta. Os quadros são PNGs1024×1024 com alfa,
ancorados no mesmo ponto dos pés. A espera repete; ataques seguram o quadro final.
Há pose de aviso, execução e recuperação nas sequências de ataque.

Fontes e versões anteriores: `docs/referencias/pecas/oficinas/carretel/`.
Preparação: `tools/cut_carretel_art.gd` (separa por contorno, não corta na grade).
Prompts: `docs/prompts/carretel_animacoes_geracao.md`.
Teste: `tools/test_carretel_animation.gd`.

## Efeitos dos ataques

Também há 24 quadros de 6 sequências próprias em `art/effects/`:
agulha normal, agulha de aparar (turquesa/borda clara/estrela), arco de corte,
fita ondulante, cortina que abre/recolhe e botão mecânico com quatro furos.
As folhas foram feitas separadamente com Imagegen integrado. O botão recebeu
uma revisão para manter os quatro furos em toda a animação.

Abra `res://tools/carretel_attack_preview.tscn` e aperteF6 para a encenação
completa, com a personagem e os efeitos sincronizados. Todos os ataques têm
aviso de 0,85–1 segundo, execução visível e recuperação sem efeitos residuais.
As agulhas percorrem o palco; a fita estende/recolhe; a cortina permanece presa
ao mesmo trilho; os botões giram em trajetórias curvas.

Controles: setas/botões escolhem; Espaço pausa; Enter repete; A automático;
L troca o fundo claro/escuro; F alterna o filtro de filme, sem alterar a
configuração gráfica salva.

`carretel_attack_visual.tscn` oferece `play_attack(nome)`, `seek(tempo)`,
`paused`, e sinais `phase_changed`/`finished`. É uma camada visual reutilizável;
não aplica dano nem contém colisões de combate. Não usar a área transparente
dos PNGs ou os avisos como hitbox na futura luta: a colisão precisa acompanhar
a parte sólida visível do ataque, com pequenas folgas justas.

Fontes: `docs/referencias/pecas/oficinas/carretel/efeitos/`.
Prompts: `docs/prompts/carretel_efeitos_geracao.md`.
Preparação: `tools/cut_carretel_effects.gd` (separa no vazio real, preservando
partículas, alfa, pivô e escala uniforme por sequência, com mais de 20px de margem).
Teste: `tools/test_carretel_attacks.gd`.
Capturas/GIF: `build/qa/carretel/attacks/`.

As cenas `carretel_*_visual` são prévias de arte sem dano. A luta completa está
em `madame_carretel_fight.tscn`, descrita abaixo.

## Cenário clean

`carretel_arena.tscn` contém uma única pintura estática em `art/arena/atelier_clean.png`:
parede azul-acinzentada suave, molduras restritas às bordas e piso de madeira contínuo.
Não há móveis, adereços, objetos pendurados, partículas, animação ambiente ou camada
de primeiro plano. A arena fica atrás da personagem e dos ataques. A escala é uniforme,
sem esticar a pintura, com o piso alinhado aos pés em y=930.

Para conferir, abra `res://tools/carretel_arena_preview.tscn` e aperte F6.
A prévia começa sem interface para deixar toda a arena livre. H revela/oculta os
controles; setas trocam o ataque, Espaço pausa, Enter repete, A alterna o automático,
L compara com um fundo claro e F alterna o filtro de filme sem mudar configurações salvas.
A prévia anterior de efeitos permanece disponível com o fundo neutro.

Fonte e primeira versão: `docs/referencias/cenarios/carretel/`.
Prompt e revisão (Imagegen integrado): `docs/prompts/carretel_cenario_clean.md`.
Teste: `tools/test_carretel_arena.gd`.
Capturas/GIF: `build/qa/carretel/arena/`.

O cenário também é usado pela luta jogável.

## Luta implementada

Entre pela Madame Carretel no mapa das Oficinas (Área3). A luta utiliza os sistemas
normais de solo/dupla, BossBrain/BossSync, barra de vida, parry, derrota/recomeço,
nota, ingressos e retorno ao mapa. Os outros bosses não foram modificados.

São1250PV, em três fases: Tirando as Medidas, Prova de Roupa e Manequim de Guerra.
Na fase mecânica, os três botões ganham um aro claro durante a janela de fraqueza
e recebem dano dobrado. A regra de dano em solo é a mesma dos outros bosses.

Proteções contra ficar parado em um abrigo:

- A área cenográfica atrás dela não é acessível nem andando, pulando ou dando dash.
- Agulhas miram posições de todos os jogadores vivos, inclusive cantos e altura do pulo.
- O saco de ataques garante agulhas em TODAS as fases; não depende de sorte ilimitada.
- Fitas/cortes percorrem o chão até a borda esquerda; cortinas e botões usam os alvos do host.
- Avisos de0,9–1s travam o alvo antes do golpe: sair da marca continua sendo uma defesa justa.
- A parede só limita o jogador; não vira escudo invisível impedindo tiros nos botões.
- Corpo e projéteis deixam de machucar ao cancelar, aparar ou vencer.

O dano dos efeitos acompanha contornos opacos, não o quadrado transparente dos PNGs.
Contornos convexos estão prontos em `art/effects/carretel_collision.tres`, preparados
por `tools/prepare_carretel_collisions.gd`; não há processamento de imagens durante a
luta no celular. Pequenos detalhes de textura de até2px são fechados só na máscara física.

Windows e mobile usam a MESMA luta. Os controles de toque/tiro automático existentes
detectam a cena normalmente. Nenhum arquivo de `core/player/` foi modificado.

Teste direto no Godot: `res://tools/carretel_playtest.tscn` + F6. Este lançador usa
um save exclusivo (`carretel_playtest_solo.json`), três vidas e o equipamento inicial,
sem alterar os saves da campanha. Começa pausado: escolha Continuar para iniciar.
Nas exportações a entrada é pelo mapa.

Testes: `tests/test_carretel.tscn` (54 pontos/alturas/fases, dano real, parry físico,
tiro nos botões, vitória, derrota, toque e parado-atirando nos dois cantos),
`tests/test_carretel_online.tscn -- host/client [ruim]` e teste de todos os bosses.
Relatórios/capturas: `build/qa/carretel/`.

Versão Windows local: `build/carretel_windows/RespeitavelPublico.exe`.
O APK precisa do ambiente Android/assinatura do fluxo de publicação; este PC não possui
Java/SDK/templates Android configurados. Nenhuma versão foi publicada automaticamente.
