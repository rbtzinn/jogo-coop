# Diário do trabalho autônomo (ausência do usuário de 02/10 a 05/10/2026)

O usuário saiu na sexta (02/10) à noite e volta na segunda (05/10). Todo o trabalho registrado
aqui foi feito em 02/10/2026. Ele pediu para o Claude
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
- 5c — Corrida no Trem do Circo (`levels/train/`; controlador `core/combat/run_level.gd`; câmera `components/stage/group_camera.gd`; inimigos `components/enemies/`; ingressos `components/stage/hidden_ticket.gd`). Tenda DoorTrain liberada; vitória no save (level_id "train"). Testes: `tests/test_train.tscn` e o passo 9 do teste online. Fotos: `tests/screenshots.tscn` também aceita a fase do trem. Prompt de arte: `docs/prompts/codex_trem.md`. **Sem commit**: a retomada de 02/10 pediu para não rodar git; tudo da 5c está só no disco (fazer o commit quando o git for liberado).
- 5d — O Grande Mágico Zaratan (`bosses/magician/`): luta completa (Abracadabra, Mulher Serrada, Grande Final), Blackout com holofotes (`components/fx/darkness_overlay.gd` + `shaders/darkness.gdshader`), jogo das caixas pela rede, mágico gigante, ingresso dourado ao vencer. Tenda liberada (cadeado dos outros três). Testes: `tests/test_magician.tscn`, teste de fumaça (3 lutas) e passo 10 do teste online. Prompt de arte: `docs/prompts/codex_magico.md`. **Sem commit** (mesmo motivo da 5c).
- 5e1 — Barraca e Camarim: `core/shop/catalog.gd` (itens de `dialogues/items.json`, falas de `dialogues/lojista.json`), `core/shop/shop.gd` (autoload Shop: comprar, doar, equipar; o host confere), `core/ui/shop_panel.gd`, `core/ui/dressing_room.gd` (no menu de pausa, só no mapa). Telas por cima congelam o personagem pelo grupo `blocking_ui`. O export agora inclui `dialogues/*.json` e deixa `tests/` de fora. Testes: `tests/test_shop.tscn` e passo 11 do teste online. **Sem commit** (mesmo motivo da 5c).
- 5e2 — Efeito dos itens: `core/player/player_loadout.gd` (lê o equipamento do save ao nascer), `core/player/player_duo.gd` (Catapulta, Pirâmide Humana, Rede de Segurança, boneco de fumaça), pistolas em `core/player/player_gun.gd` + `components/projectile/projectile.gd` (teleguiado, bumerangue, atravessar, explosão) e `components/projectile/area_blast.gd`, truques no dash do `Player`. O host manda a cópia do save assim que o parceiro conecta (o cliente nasce com o equipamento certo). Testes: `tests/test_items.tscn` (todos os itens) e o começo do teste online. **Sem commit** (mesmo motivo da 5c).

## Próximos passos

**Atualizado em 03/10:** a Área 1 está completa em conteúdo; agora as decisões de rotina são delegadas (ver "Autorização de 03/10/2026" abaixo) e o trabalho segue pelos marcos M1–M6 da versão 1.0 no `docs/DESIGN.md`. Próximo: revisar a D3 do Codex com captura a 60 quadros por segundo; depois D4, B6, os intermediários da corrida (E1) e o M2.

### Último resultado da bateria completa (02/10/2026, depois da 5e2)

`sh tests/run_all.sh`, terminou com código 0 (tudo passou, nenhum erro de script):

| Teste | Resultado |
|---|---|
| test_boss_smoke (Domador, Malabaristas e Mágico inteiros, todos os ataques e fases) | 0 falhas, 0 erros de script |
| test_grade_save (nota e save) | 0 falhas, 0 erros de script |
| test_items (os 17 itens) | 0 falhas, 0 erros de script |
| test_jugglers (mecânica dos irmãos) | 0 falhas, 0 erros de script |
| test_magician (caixas, Blackout, gigante, vitória) | 0 falhas, 0 erros de script |
| test_map (mapa, tendas, ida e volta da luta) | 0 falhas, 0 erros de script |
| test_shop (loja e Camarim) | 0 falhas, 0 erros de script |
| test_special (Especial e bônus em dupla) | 0 falhas, 0 erros de script |
| test_train (Trem do Circo) | 0 falhas, 0 erros de script |
| test_online, rede normal (host + cliente: mapa, Especial, dupla, Número Perfeito, vitória, Tentar de novo, queda e volta, balão, trem, caixas do Mágico, loja, equipamento) | ok, 0 falhas nos dois |
| test_online, rede ruim (ping 160 com perda de pacotes) | ok, 0 falhas nos dois |

Isso são testes automáticos; ninguém jogou de verdade ainda.

### Pendências reais

1. **Commit**: tudo desde a 5c (trem, mágico, loja, itens) está só no disco, porque a retomada de 02/10 pediu para não rodar git. Sugestão de commits separados: 5c, 5d, 5e1, 5e2 (os arquivos de cada parte estão listados acima).
2. **Revisão humana**: jogar a lista abaixo (sozinho e com o parceiro), conferir se dá para desviar de todos os ataques novos e calibrar os números (dano, tempos, preços). Revisar as decisões tomadas pelo Claude (estão no DESIGN.md, bosses.md, shop.md e combat.md): números do Especial e da nota, divisão da etapa 5, mapa lateral com tendas, mecânicas e ataques dos Malabaristas, do Trem e do Mágico, nome do lojista (Seu Bonifácio) e números dos itens.
3. **Arte**: tudo da Área 1 feito depois do Domador é provisório (desenho por código). Pedidos para o Codex prontos em `docs/prompts/` (parry/balão/especiais, mapa, Malabaristas, trem, Mágico); continuam pendentes também os pedidos antigos (Pedido 3 do leão, arte do Domador).
4. **Área 2**: ainda não tem design. Por delegação (03/10), o design dela é o marco M4, no papel antes de qualquer código.

## O que o usuário precisa testar na segunda

(Lista acumulada; cada etapa acrescenta a sua.)

1. **Especial** (Testar sozinho; F1 enche as estrelas): I / V / Y com 1 estrela solta o Rolhão (rolha gigante que atravessa o leão; no ar o personagem fica pairando um instante). Com 5 estrelas: palhaço = Torta na Cara (ergue e arremessa na direção da mira), acrobata = Salto Mortal (Tab troca de personagem; salta girando por cima do leão). Os dois ficam invencíveis durante o golpe.
2. **Grande Número em Dupla**: com as duas barras cheias (F1), solta o do palhaço, aperta Tab e solta o da acrobata em menos de 1 s: aparece "Grande Número em Dupla!" e a Torta de Ouro explode no leão.
3. **Objetos rosa novos**: onda rosa da Chicotada (fase 1), onda rosa da Patada (fase 2), brasas rosa nos Pulos (fase 3). Pular por cima e apertar pulo de novo encostando: estoura e ganha estrela.
4. **Online com o parceiro**: o mesmo; o Número Perfeito (os dois dando parry no mesmo objeto rosa quase juntos) dá 2 estrelas para cada um.
5. **Configurações > Controles**: linha nova "Especial", dá para trocar a tecla.
6. **Nota**: vencer o Domador mostra o cartaz com a nota (C/B/A/S), tempo, vida, parries, estrelas e "+3 ingressos para cada um" (só na 1ª vitória; depois só se melhorar a nota).
7. **Online**: o parceiro sair pelo menu e entrar de novo no meio da luta: ele volta vendo o chefão na fase e com a vida certas.
8. **Mapa**: "Testar sozinho" e "Hospedar" abrem o parque. Andar até a tenda do Domador e apertar Atirar (J / X) entra na luta; depois de vencer, "Voltar ao mapa" mostra a nota carimbada na tenda e os ingressos no topo. Todas as tendas abrem (Domador, Malabaristas, Trem e a Barraca de Curiosidades, que é a loja), menos o Mágico, que fica fechado até vencer os outros três.
9. **Irmãos Malabaristas** (tenda azul do mapa): bater só num irmão deixa ele tonto e, 3 s depois, o outro joga uma bola de cura rosa (dá para estourar com parry). Para trocar de fase, os dois precisam cair juntos (o ideal é cada jogador focar um). Fase 2 em totem, fase 3 no monociclo gigante. Conferir se dá para desviar de tudo: abaixar na Troca de Lugar e nas claves baixas, pedestal no Totem e no Monociclo.
10. **Trem do Circo** (tenda verde do mapa): correr para a direita pelos tetos dos vagões; cair no vão tira 1 vida e volta no vagão; quando piscar "ABAIXE!" na direita, segurar Baixo (a ponte passa por cima); achar os 3 ingressos dourados (um em cima do vão entre o 3º e o 4º vagão, um na pilha de caixotes, um acima do caixote do penúltimo vagão); chegar na locomotiva termina. Online, a câmera segue os dois e ninguém sai da tela.
11. **Grande Mágico** (tenda roxa; abre depois de vencer Domador, Malabaristas e Trem; para testar já, vença os três ou apague o cadeado no save): leques de cartas com buraco, coelhos pulando (pular), teleporte com estrela de aviso. Fase 2: caixas com serras (linha vermelha mostra a altura), jogo das três caixas (acompanhe a caixa em que ele entrou; a errada solta pombas) e o Blackout (fiquem perto um do outro para os holofotes crescerem). Fase 3: mágico gigante; as mãos descem onde vocês estavam (a sombra avisa), a cartola despeja tralhas varrendo o palco. Ao vencer, ele cai na cartola e aparece o ingresso dourado.
12. **Loja e Camarim** (tenda dourada "Curiosidades"): entrar abre a Barraca do Seu Bonifácio só na sua tela; comprar pede para apertar de novo (confirmação); "Dar" passa ingressos para o parceiro. No mapa, Esc > Camarim troca Pistola, Truque, Adereço e Número de dupla. O que for equipado vale ao entrar na próxima luta ou fase (efeitos no item 13).
13. **Itens** (compre na Barraca e equipe no Camarim; para testar rápido, ganhe ingressos vencendo chefões): Leque de Confete (3 confetes de perto; EX explode em volta), Clave (vai e volta; EX: chuva de claves), Bolha (teleguiada; EX: Bolhona). Truques: Fumaça (some e deixa um boneco de fumaça que engana a Patada e o leão), Bala de Canhão (o dash machuca, mas não protege), Pirueta (dash para cima/diagonal segurando a direção). Adereços: Coração de Pano (4 corações), Nariz de Buzina (o 1º golpe faz "Fom-fom!" e não tira vida), Luvas (parry mais fácil), Sapatos de Mola (pulo mais alto), Trevo (barra enche mais rápido). Dupla: Catapulta (dash encostando no parceiro), Rolha Turbinada (atirar através do parceiro), Pirâmide Humana (pular na cabeça do parceiro), Rede de Segurança (encostar no balão revive).


## Autorização de 03/10/2026: decisões delegadas e escopo da versão-alvo

O usuário mandou, por meio do Codex: "tome as melhores decisões você e me surpreenda ... não pare
segunda ... até quando o jogo finalizar ... sempre façam melhorias juntos ... fique bom e venda
legal". Também disse que sente as animações "travadas/estranhas".

**O que mudou:**
- Decisões de rotina de arte, design, gameplay e balanceamento agora são do Claude e do Codex.
- Cada decisão é registrada aqui e no `docs/DESIGN.md` como "decidido por delegação, revisar".
- O acompanhamento não para na segunda nem quando a Área 1 terminar.

**O que continua igual:**
- Sem git, sem compras ou uso pago, sem mexer em segurança ou autenticação.
- Nada de garantia de venda nem de publicação.
- Arte antiga só é trocada depois de conferida, com o original guardado.

**Escopo finito (para "melhorias" não virar crescimento sem fim):** a versão-alvo 1.0 está no
`docs/DESIGN.md` ("Versão 1.0: escopo fechado"). Marcos verificáveis, nesta ordem:

| Marco | Conteúdo |
|---|---|
| M1 | Movimento e arte da Área 1 |
| M2 | Estabilidade e acabamento |
| M3 | Som |
| M4 | Design da Área 2 no papel, antes de qualquer código |
| M5 | Área 2 |
| M6 | Final |

Nada fora desses marcos entra sem antes passar por eles.

**Decisões tomadas por delegação (03/10):**
1. **B6, o rugido em fogo**, entra na fila depois de D3 e D4. Na fase 3 é o único estado do leão que
   ainda tem as chamas soltas.
2. **A torta voando continua grande** (171 px na tela). Lê melhor como golpe máximo, e a área de dano
   combina com ela. O arremesso desenhado já solta a torta da mão.
3. **Antes de pedir mais ciclos inteiros, medir o movimento real** (piloto da corrida, abaixo). A arte
   nova passa por captura a 60 quadros por segundo com o controle, não por uma foto da folha.
4. **Som entra como marco (M3).** Hoje o jogo não tem nenhum som, e isso pesa mais na sensação de jogo
   pronto que qualquer quadro a mais.

**O que só uma pessoa avalia** (os testes automáticos não substituem):
- sensação de controle e de animação jogando;
- se dá para desviar de cada ataque;
- leitura das cores e dos objetos rosa;
- dificuldade e preços;
- online com o parceiro de verdade (playit.gg);
- se o jogo é divertido.

## Piloto de movimento: corrida da acrobata e do palhaço (03/10/2026)

Pedido do Codex: medir o movimento real antes de produzir mais ciclos.

### Ferramentas

- **Captura a 60 quadros por segundo** (`screenshots.tscn -- corrida` para a acrobata e
  `-- corrida2` para o palhaço; rodar com `--fixed-fps 60`).
  - Um roteiro de controle: parado, corre, para, corre atirando, pula correndo, dash, abaixa e corre
    para o outro lado.
  - Salva uma foto por quadro de física no tamanho real da tela.
  - Salva um `corrida.csv` com tempo, x, velocidade, chão e o quadro desenhado mostrado.
  - Sem o `--fixed-fps` a captura pulava quadros (o jogo andava 5 quadros de física por foto): a
    primeira tentativa foi descartada.
- **Medição do pé de apoio:**
  - `soles.gd` (scratchpad) mede onde cada sapato toca o chão em cada quadro da folha.
  - `slide_log.gd` cruza essa medida com o registro e diz quanto o pé de apoio anda no chão em cada
    apoio. O ideal é 0.

### Auditoria da acrobata

**O que está bom:**
- **Pernas:** alternam certo. Nos quadros 1–4 o pé de apoio é o da perna clara e nos 5–8 o da escura (corrigido em 03/10: aqui estava trocado; os nomes "pé escuro" e "pé claro" das tabelas de deslize abaixo seguem a troca antiga, mas os números não mudam); não há
  repetição do mesmo passo.
- **Cabeça:** o nariz está fixo em x 400 e mesmo tamanho nos 8. A cabeça sobe e desce uns 8 px na
  tela, um balanço natural.
- **Loop:** a volta do 8 para o 1 não pula.

**O que causava o "travado":**
1. **Cadência errada.** A 2,8 passos/s, o corpo andava 186 px por passo e o pé desenhado só 151: o pé
   escorregava uns 23% em todos os passos.
2. **Pé de apoio recuando de forma desigual.** Entre os quadros, o pé recua 96, 66, 129 e 14 px na
   folha. O pior caso: do 4 para o 5 o pé parado quase não anda.
3. **Só 8 desenhos por ciclo a 520 px/s.** Em cada quadro o corpo anda uns 35–45 px com o pé parado no
   desenho, e depois o pé volta de uma vez. Isso só se resolve com mais desenhos.
4. **Ao parar, o parado entrava num quadro qualquer** (o relógio dele era global).

**Correções** (sem mexer na velocidade, no controle, na colisão nem na rede):
- **Cadência** no `acrobat_rig.tscn`: de 2,8 para 3,57 passos/s, medida pelo tamanho do passo
  desenhado.
- **Tempo por pose** (`run_frame_weights`): 1; 1,4; 1; 0,8 por passo.
  - É uma opção nova do `CharacterRig`; a função `FrameAnimation.index_at` distribui o ciclo pelos
    pesos.
  - Os pesos saíram de uma busca simulada (`runslide.gd`) e foram conferidos na captura.
- **Parado ao parar:** agora começa sempre pelo quadro 1 (`_idle_since` no `CharacterRig`), nos dois
  personagens.

**Resultado medido nas capturas** (deslize do pé de apoio por apoio, px na tela, corrida para a
direita):

| | Pé escuro | Pé claro | Média | Pior |
|---|---|---|---|---|
| Antes | 80, 80 | 44, 85, 42 | 66 | 85 |
| Depois | 55, 57, 55, 39, 39 | 26, 67, 26, 67, 26 | 47 | 67 |

A média caiu 29% e o pior caso 21%.

**Transições conferidas nas capturas:**
- parado → corrida: entra pelo quadro 1;
- corrida → pulo → pouso → corrida: sem salto;
- corrida → dash; parado → abaixado; corrida para os dois lados.
- **Depois da correção:** corrida → parado agora começa pelo quadro 1 (antes entrava no 6).

O braço da pistola, por código, acompanha em todos.

### Palhaço

O desenho do palhaço é de corrida com voo: quadros 4 e 8 sem pé no chão, e no apoio o pé recua só uns
56 px na folha.

- **Antes:** a 3,8 passos/s e com tempos iguais, o pé deslizava 54–76 px por apoio.
- **Correção:** cadência 4,4 e pesos 0,7; 0,7; 0,7; 1,9. O apoio fica curto e o voo longo, então o
  deslize acontece no ar, onde não aparece.
- **Depois:** 20–27 px, 63% menos. Testei também 3,8 com voo de 2,2: deu o mesmo deslize, mas ficava
  mais solto no ar.
- Conferido na captura: o voo dura uns 6 quadros a 60 por segundo e dá um passo saltitante de
  palhaço.

### O que falta e só desenho resolve (pedido na fila)

**Quadros intermediários da corrida da acrobata**, 8 desenhos entre os aprovados, para chegar a
16 por ciclo.
- Metade dos 35–45 px de deriva por quadro vai embora.
- O pedido diz onde cada pé de apoio deve tocar o chão.

**O que não foi feito, de propósito:**
- Intermediários por mistura (crossfade ou morfagem automática): borram rosto e pernas.
- Prender o pé deslocando o corpo: faria o corpo trancar.

**Método híbrido** (poses desenhadas e peças/curvas para os movimentos secundários):
- Já é o que existe: o braço da pistola, por código, mira em 8 direções sobre os quadros desenhados.
- O próximo candidato é a respiração e o cabelo por curva no parado. Antes, uma comparação do mesmo
  jeito.
- Não migro tudo para boneco articulado sem comparar.

### Rede: falha intermitente com rede ruim corrigida na causa

Durante o piloto, o teste online com rede ruim falhou uma vez de um jeito novo: o jogador do cliente
não nasceu no host. Logs em `scratchpad/online_fail_piloto/`.

**Causa** (as duas falhas guardadas mostram a mesma linha, `Node not found: "TamerFight/PlayerSpawner"`
e antes `"MagicianFight/PlayerSpawner"`):
- O aviso do cliente "carreguei a fase" chegava ao host antes de a fase dele existir.
- O aviso se perdia, e o host nunca criava o jogador do cliente.

**Correção** (`core/network/player_spawner.gd`): o cliente repete o aviso a cada 0,5 s até o host
responder. O host já ignorava aviso repetido. Não é teste mascarado: o aviso agora não se perde.

**Testes:** online com rede ruim 3 vezes seguidas (as rodadas extras foram por causa da mudança na
rede) e online normal 1 vez, todas com 0 falhas. Os 9 testes locais tinham passado nesta rodada antes
da mudança de rede, que não os afeta.


## Marco M2 (estabilidade e acabamento): levantamento de 03/10/2026

São coisas que não dependem de imagem nova, levantadas no código. Nada aqui é escopo novo: são os
itens do M2 do `docs/DESIGN.md`, na ordem em que vão ser feitos.

1. **Rede**
   - A causa das falhas com internet ruim foi corrigida em 03/10: o aviso "carreguei a fase" se perdia.
   - Falta acompanhar nas próximas baterias.
   - Os outros envios de rede (`player_sync`, `boss_sync`, `duo_acts`) só vão para quem já está pronto
     (`Network.ready_peers`). Não têm o mesmo problema.
2. **Tutorial curto do controle**
   - Hoje não existe. Só a tenda do mapa mostra a tecla de atirar.
   - Plano: placas no mapa do parque, perto do começo, com as teclas configuradas: andar, pular,
     atirar, dash, abaixar, parry, especial. O texto fica em `dialogues/`.
   - Não vira fase nova.
3. **Menus e telas**
   - Auditar o fluxo com fotos: menu principal, Testar sozinho, Hospedar, Entrar, pausa, configurações,
     fim de luta, mapa, loja e Camarim.
   - Corrigir o que estiver cortado, ilegível ou sem volta.
4. **Opções**
   - Hoje existem: qualidade, tela, VSync, FPS, mostrar FPS, "cima também pula", ping e troca de teclas.
   - Volume entra com o som (M3).
   - "Reduzir clarões" fica para depois: os clarões já são fracos de propósito (`ScreenFlash`).
5. **Exportação**: conferir que o executável do Windows (`export_presets.cfg`, pasta `build/`) abre e
   joga a Área 1 do começo ao fim.

Fica para avaliação humana no M2: a leitura das placas, se o tutorial basta para quem nunca jogou e o
online com o parceiro de verdade.


### M2: primeira rodada de auditoria (03/10)

**Exportação para Windows**
- O `build/RespeitavelPublico.exe` é de 02/10 às 15:31, de antes do trem, do mágico, da loja e de toda a
  arte nova.
- Exportei de novo para `scratchpad/export/` (133 MB, com o predefinido "Windows Desktop").
- O executável novo abre e fecha sem erro (`--headless --quit-after 300 --log-file`).
- O de `build/` ficou como estava, porque é o que o parceiro pode estar usando. Trocar fica para quando
  o usuário for mandar a versão nova.
- Falta, e só uma pessoa faz: jogar a Área 1 inteira pelo executável.

**Fotos das telas** (`res://tests/screenshots.tscn -- menus`, com janela):
- menu principal, painel de entrar, luta, pausa, as três abas das configurações, cartaz de vitória e
  de derrota.
- O que está bom: tudo legível, nada cortado, todas com "Voltar".
- O que achei:
  1. **Neste PC, "Pular" está sem tecla no teclado** (as duas colunas com "—"). O padrão do projeto é
     Espaço e Z. O `settings.cfg` deste PC tem os espaços do teclado vazios: pode ter sido o usuário
     limpando (botão direito) ou uma troca de tecla que tirou a tecla de lá. Não é erro do código.
     - Com "Cima também pula", dá para pular com W.
     - Melhoria registrada para o M2: avisar na tela de controles quando uma ação essencial (pular,
       atirar, dash) ficar sem tecla no teclado e sem controle.
  2. **Lista de controles:** a última linha visível ("Travar mira") aparece cortada pela metade antes
     da rolagem. É só visual; a rolagem funciona. Ajuste pequeno de altura.
  3. **Painel de entrar:** vem preenchido com o último endereço usado (o do playit.gg deste PC). Está
     certo assim.

Próximos itens do M2: o aviso de ação sem tecla, a altura da lista de controles e as placas de
tutorial no mapa.


### M2: controles (03/10)

**Aviso de ação sem tecla** (`core/ui/settings_menu.gd`, `_missing_text`):
- Na aba Controles, uma linha vermelha avisa quando Pular, Atirar ou Dash ficam sem tecla no teclado ou
  sem botão no controle.
- Em Pular, a tecla de cima conta quando "Cima também pula" está ligada.
- Só avisa e lembra o "Restaurar padrão"; nunca troca as teclas do jogador.
- Conferido com um teste à parte que muda as teclas só na memória, sem salvar. O `settings.cfg` do
  usuário ficou com o mesmo hash antes e depois:

| Situação | Aviso |
|---|---|
| Teclas deste PC | nenhum (W pula) |
| Sem "Cima também pula" | "sem tecla no teclado para Pular" |
| Sem Atirar | Pular e Atirar no teclado, Atirar no controle |

**Lista de controles:** as 9 ações cabem inteiras, sem linha cortada. A letra e o espaço entre as linhas
ficaram um pouco menores. Conferido na foto `-- menus`.

**Bateria depois disso, do B6 e do eco dourado:** 9 testes locais com 0 falhas, online normal e com
rede ruim ok.

**Falta no M2:** as placas de tutorial no mapa e jogar a Área 1 pelo executável novo (avaliação
humana).


### M2: placa de controles no mapa (03/10)

**O que é:** uma placa "Como se apresentar" pendurada no varal do mapa, à esquerda, acima de onde os
jogadores nascem.
- Componente: `components/stage/control_sign.gd`. Os textos ficam em `dialogues/tutorial.json`, e
  `{ação}` vira o nome da tecla configurada.
- Mostra andar, pular, atirar, dash, abaixar, travar mira, parry, especial e entrar na tenda.
- Usa as teclas que o jogador escolheu, não as padrão. Com um controle conectado, mostra os botões dele.
- Pular sem tecla e "Cima também pula" ligado: mostra a tecla de cima. Neste PC aparece "Pular: W".
- Ação sem tecla mostra "—".
- Atualiza quando as configurações mudam. Não troca nem restaura teclas.

**Escopo:** é uma placa só, no mapa. Não é fase de tutorial nem outra área.

**Conferido:** foto do mapa (`-- loja`, foto `mapa`). A placa fica acima da tenda do Domador, sem tampar
as tendas nem o título, legível no tamanho da tela.

**Bateria depois disso:** 9 testes locais com 0 falhas, incluindo o do mapa, e online normal e com
rede ruim ok.

**Fica para avaliação humana:** se a placa basta para quem nunca jogou.


## Piloto do mundo 3D da Área 1 (03/10/2026, pedido direto do usuário)

O usuário não gostou do mapa nem de como se escolhe o chefão. Ele quer uma aventura: os dois andando
pelo mundo até os chefões, com lojas no caminho, num mapa 3D visto de cima. Isso passou na frente de
tudo como marco M0 (decisões e roteiro no `docs/DESIGN.md`, "Aventura: mundo 3D da área").

**O que foi feito (provisório, formas simples):**

*Mundo* (`levels/world/world_area1.tscn` e `.gd`), que agora é o `Levels.MAP`:
- É para onde vão o menu, a volta das lutas e o Camarim da pausa.
- Chão, caminho de tábuas, 4 postes com luz, luz de lua, névoa e um título no canto.
- A câmera fica alta e oblíqua (48°), segue o meio da dupla e fica presa nas bordas.
- O host salva ao chegar.
- Sozinho, Tab troca quem você controla.

*Andador* (`core/world/world_walker.gd` e `.tscn`):
- Anda no chão com as mesmas teclas da luta.
- Desenho virado para a câmera, com sombra redonda.
- Provisório: o parado e a corrida de lado da luta, com o passo pela distância andada.
- Online: cada PC move o seu e manda a posição; o outro suaviza (passa pelo simulador de internet
  ruim).
- Sozinho: o outro personagem segue quem você controla.

*Tendas* (`core/world/world_door.gd`), com a mesma ideia do `MapDoor`:
- Nome, "Fechado", melhor nota e "Tecla: entrar".
- Online, os dois precisam estar na frente da tenda de chefão: sozinho aparece "Esperando o parceiro".
  Quem decide é o host.
- Na volta, a dupla nasce na frente da tenda (`Levels.return_door`).
- A loja abre a Barraca e o carroção abre o Camarim.

*Roteiro:* portão com Camarim → Domador → Curiosidades → Malabaristas e Trem → Mágico (fechado até
vencer os três).

*Mudanças pequenas para isso funcionar:*
- `PlayerSpawner` estende `Node` e ganhou `player_scene` (Marker3D também serve).
- `Shop.key_for` e `ShopPanel.open_for` aceitam qualquer nó.
- Shader `shaders/world_stripes.gdshader` (lona listrada).

**Testes adaptados ao mundo:**
- `test_map`: anda no mundo, o parceiro segue, entra no Domador, vence e volta na frente da tenda;
  cadeados e notas.
- `test_shop`: barraca, congelado comprando, Camarim.
- `test_online`: o cliente sozinho na tenda espera; com os dois na frente, entra.

**Bateria:** 9 testes locais com 0 falhas, online normal e com rede ruim ok. Fotos com
`res://tests/screenshots.tscn -- mundo` (a dupla anda do portão até o fim).

**Limitação conhecida:** andando para cima ou para baixo, o desenho continua de lado. Isso só se resolve
com os desenhos novos de andar (bloco W da fila, pedido W1 pronto). O piloto não finge as direções com
a corrida de lado girada.

**Falta e só uma pessoa avalia:** se a câmera e a escala agradam jogando, e se andar entre as tendas é
melhor que o mapa antigo. Se a câmera fixa não convencer, testar a de terceira pessoa num teste curto.

**MV1 (intermediários da corrida da acrobata), pausada:**
- Mais duas tentativas do Codex recusadas:
  - `exec-9faf7069-…` (guia, corrida e parado);
  - `exec-7f2a3dcd-…` (só o guia, edição).
- As duas repetiram quase os quadros-chave e não seguiram os pontos de apoio (361, 263, 192...).
  Nenhuma foi copiada para o projeto.
- Ao todo, 5 tentativas recusadas.
- Não repetir a mesma geração. Se voltar, usar guias recortados de 1 ou 2 poses, ou redesenho
  controlado, nunca mistura ou girar a imagem.
- O mundo 3D vem antes.


### M0 visual: miniaturas 3D e maquete (03/10, à noite; o usuário rejeitou a primeira aparência)

**Feedback humano real:** o usuário achou os personagens do mapa "horríveis" e o mapa feio. Os testes
passando não aprovam o visual.

**Feito:**

*Miniaturas 3D* (`core/world/miniature.gd`):
- Palhaço e acrobata montados de esferas, cápsulas e cilindros, com esqueleto de pivôs.
- Shader de miniatura pintada (`shaders/miniature.gdshader`): sombra em degraus, brilho de verniz,
  luz de borda e losangos de arlequim.
- Contorno de tinta por casca invertida (`shaders/ink_outline.gdshader`), com a espessura em metros.
- Rosto: olhos de desenho com brilho e piscada, sobrancelha, bochechas, nariz de bola e sorriso.
- Palhaço: cartolinha com faixa dourada e margarida, tufos vermelhos, gola de babado, botões dourados,
  luvas e sapatões.
- Acrobata: coque com tiara de estrelas, brincos de estrela, maiô azul-petróleo com borda dourada,
  estrela na cintura e saiote em zigue-zague, sapatos de salto com bolinha dourada.
- Caminhada: o passo sai da distância andada (o pé de apoio não desliza), joelho dobrando na passada,
  quadril subindo e descendo, braços opostos, tronco torcendo e giro suave.
- Parado: respira e mexe a cabeça. Chapéu e coque são uma mola que fica para trás ao acelerar.
- `WorldWalker` usa a miniatura no lugar do desenho, com sombra de contato.

*Maquete* (`core/world/world_terrain.gd`, `world_props.gd`, `shaders/world_ground.gdshader`,
`shaders/world_stripes.gdshader`):
- Terreno com relevo e colisão.
- Trilhas em curva de tábuas variadas, que se ramificam.
- Atrações (`WorldDoor`, `landmark`): tenda, barraca de vendedor, carroção, estação e tenda grande,
  cada uma com a sua placa de madeira.
- O resto da cena em `levels/world/world_area1.gd`.

**Conferido em fotos:**
- `res://tests/screenshots.tscn -- mundo`: a dupla segue o roteiro com o controle de verdade, do portão
  aos Malabaristas, com closes parado e virando.
- `-- miniaturas`: palco com as 4 vistas e a caminhada.

**Antes e depois:**

| | Antes | Depois |
|---|---|---|
| Chão | deserto liso | trilhas de tábuas e relevo |
| Tendas | fila de tendas iguais | marcos diferentes por atração |
| Personagens | recortes 2D de lado | miniaturas que viram de frente e de costas |
| Nomes | cortados no alto da tela | em placas na frente das atrações |

**Corrigido no caminho:**
- As tábuas e as cordas saíam tortas (escala aplicada depois da rotação); agora com
  `Basis.from_scale`.
- O poste que ficava no meio da trilha foi tirado dali.
- A palha do chão parecia chuva e foi reduzida.

**Testes:** `test_map` e `test_online` agora usam `front_point()` da atração. A bateria completa passou:
9 testes locais com 0 falhas, online normal e com rede ruim ok.

**Ainda fraco, próximos passos:**
- O rosto do palhaço ainda é pequeno no tamanho do jogo.
- As tendas são cilindros retos.
- A borda e o sul do mapa estão vazios.
- Falta a captura da acrobata de perto.

**Pendente para depois do M0 visual:** a folha base candidata dos Malabaristas
(`docs/referencias/pecas/malabaristas/malabaristas_folha_candidata.png`). O Codex avisa que a maçã do
Teco fica perto do topo e que há trilhas de movimento dos objetos. Não começar o Pedido 2 antes da
revisão.


### M0 visual, segunda rodada: guiada pela referência do Codex (03/10, noite)

**Referência:** `docs/referencias/mundo3d_direcao_visual.png` (1774 × 887, conceito do Codex). Não é
captura nem modelo. O que se aproveita dela: rostos expressivos, silhuetas, materiais pintados, a luz
âmbar contra a azul, terreno variado, a loja como carroção com toldo e balcão, e madeira e lona. A
câmera dela é mais baixa e a acrobata maior; no jogo ficam as proporções aprovadas.

**Personagens** (`core/world/miniature.gd`):

| Personagem | O que mudou |
|---|---|
| Palhaço | macacão de quadrados vermelhos e creme, como a arte aprovada (antes eram losangos); cabeça maior; olhos grandes com muito branco e pupila com corte de torta; sorriso largo em lua com língua (antes parecia careta); gola de babado dupla; pompons vermelhos; margarida maior; sapatões grandes com babado no tornozelo |
| Acrobata | cabeça maior e um pouco erguida; coque menor e mais para trás, para o rosto aparecer na câmera alta; brincos e tiara de estrelas visíveis; estrela da cintura maior; saiote rodado |

- As estrelas saíam pretas (malha virada) e foram corrigidas.
- As miniaturas ficaram 1,35 vez maiores no mundo e a velocidade de andar foi para 2,4 m/s.

**Pés no chão, medidos no MUNDO** (`--fixed-fps 60 res://tests/screenshots.tscn -- passos`, grava
`passos.csv`):
- A dupla anda portão → Domador → loja com o controle de verdade, o palhaço controlado e a acrobata
  seguindo, e volta com a acrobata controlada.
- A medida é quanto cada tornozelo anda no chão enquanto apoia.
- **Antes:** a perna balançava por seno, e na conta o pé de apoio andava uns 60% mais rápido que o chão
  no meio do passo.
- **Agora:** passo plantado com cinemática inversa. O pé fica parado no mundo enquanto apoia e só dá o
  passo quando passa do alcance; o ritmo sai da velocidade.

| | Deslize por apoio (mediana) | Pior | Passos por segundo |
|---|---|---|---|
| Palhaço | 0,95 cm | 6 cm | 7,1 |
| Acrobata | 0,74 cm | 7,6 cm | 5,9 |

- Os piores casos são na largada e quando o seguidor freia.
- Corrigido no caminho: o personagem caindo no chão ao nascer deixava os pés no ar arrastando. Agora o
  pé fora da altura do chão se reajeita.

**Cenário do trecho Camarim → Domador → loja:**
- **Trilhas:** de terra batida (a madeira saiu), com a borda de grama gasta, tufos de capim e pedras
  num ritmo regular.
- **Chão:** grama escura com variação suave. A palha em riscos, que parecia chuva, saiu.
- **Cercas:** de madeira com mourões e travessas, com lanterninhas acesas a cada três mourões.
- **Árvores:** de copa redonda em cachos, mais duas secas, e arbustos.
- **Domador:** portão em forma de cabeça de leão (juba em camadas, olhos, sobrancelhas bravas, boca
  aberta e acesa com presas).
- **Curiosidades:** carroção-loja com balcão, toldo vermelho e creme, prateleiras com frascos que
  brilham, bola de cristal, gramofone, brasão com estrela, rodas e lanternas.
- **Camarim:** carroção com porta de cortina vermelha, espelho com lâmpadas, tapete e baú.
- **Câmera:** a 42° (antes 47°) e 9,4 m.
- **Oclusões corrigidas:** os postes passaram para o lado de trás das trilhas. O que encobria a
  acrobata nos Malabaristas foi tirado antes.
- **Ainda há:** a dupla passa por trás do pilar do arco da entrada por um instante.
- **Título do parque:** some depois de 3 s, como planejado; não é defeito.

**Fotos** (comparar com a mesma câmera):
- `-- mundo`: roteiro do portão aos Malabaristas, mais closes.
- `-- miniaturas`: palco com as 4 vistas e a caminhada.

**Teste do mapa** (`test_map`, "walked right in the world"):
- **Por que mudou:** a velocidade passou de 5,5 para 4,2 m/s (primeira rodada) e agora para 2,4 m/s.
  Com o limite antigo de 3 m em 40 quadros (feito para 5,5), o teste falhou em 03/10.
- **Primeira mudança:** baixei para 2 m.
- **Agora:** o limite vem das constantes. O esperado é SPEED × 40/60 − SPEED² / (2 × ACCEL) = 1,50 m, e o
  teste exige 80% disso. Medido: 1,51 m.
- A caminhada de verdade até a porta e o seguimento continuam obrigatórios no teste.

**Bateria depois disso:** 9 testes locais com 0 falhas, online normal e com rede ruim ok.

**Pendências do M0 visual:**
- Malabaristas, Trem e Mágico ainda com o acabamento da primeira rodada.
- Sul e bordas do mapa.
- Avaliação humana do visual: testes passando não aprovam.

**Pedido útil ao Codex, só se precisar:** texturas repetíveis para terra e grama.

### M0 visual, terceira rodada: caminhada medida, oclusão, chão, entradas e bordas (03/10, noite)

**Caminhada em movimento real** (`--fixed-fps 60 res://tests/screenshots.tscn -- caminhada <pasta>`):
- **Roteiro com o controle de verdade:**
  - largada de 0,6 s, depois 5 s em reta;
  - freio, giro (esquerda e depois para baixo) e freio;
  - Tab para a acrobata, com o palhaço virando o seguidor, e freio.
- **Grava** `caminhada.csv` (os dois tornozelos a cada quadro) e 60 fotos da dupla na reta. Para cada
  trecho, mede:
  - contatos por segundo;
  - o caminho do pé enquanto apoia;
  - o afastamento do ponto onde o pé pousou (P95 e pior).
- **Antes** (`1_antes_cadencia.csv`): o passo era curto e rápido, 8 contatos por segundo no palhaço e 6 na
  acrobata.
- **Mudança:** o passo ficou mais longo, com o pé indo mais à frente. O pé que está no ar é remirado a
  cada quadro, o que acabou com o pé passando do ponto no freio. A velocidade não mudou: 2,4 m/s.

| Trecho | Palhaço: contatos/s (ciclos/s) | Palhaço: afastamento P95 / pior | Acrobata: contatos/s (ciclos/s) | Acrobata: afastamento P95 / pior |
|---|---|---|---|---|
| Largada | 6,7 (3,3) | 0,1 / 0,1 cm | 3,3 (1,7) | 0,3 / 0,3 cm |
| Reta | **5,8 (2,9)**, antes 8 | 0,6 / 0,6 cm | **4,4 (2,2)**, antes 6 | 0,5 / 0,5 cm |
| Freio | 2,3 | 5,1 / 5,1 cm | 2,6 | 0,4 / 0,4 cm |
| Giro | 5,5 | 3,1 / 3,1 cm | 1,9 (seguidor, quase parado) | 2,7 / 2,7 cm |
| Tab (palhaço seguidor, acrobata controlada) | 4,0 | 0,9 / 0,9 cm | 4,8 | 1,7 / 1,7 cm |

- **Caminho do pé no apoio:**
  - na reta, 2 cm no pior caso (palhaço);
  - no freio, 7,2 cm (palhaço);
  - no giro, 5,7 cm.
  - Isso é o tornozelo girando com o pé no chão, não deslize: o afastamento do ponto de pouso fica em
    0,6 cm na reta.
- **Falhas que ficam:**
  - **Freio do palhaço:** um apoio de 5,1 cm. É o último passo, quando o corpo para em cima do pé.
  - **Giro:** 3,1 cm.
  - Os dois aparecem em 1 ou 2 apoios por trecho. Não reduzi a velocidade para esconder isso.
- **Medidas guardadas** em `docs/medidas/caminhada/`:
  - `0_passos_segunda_rodada.csv`;
  - `1_antes_cadencia.csv`;
  - `2_depois_cadencia.csv`;
  - `3_m0_terceira_rodada.csv` e o resumo.
  - O 3 é idêntico ao 2 byte a byte: as mudanças de cenário não mexeram no andar.

**Oclusão** (`levels/world/world_area1.gd`, `_add_occluder` e `_fade_occluders`):
- **Como funciona:** postes, árvores, o arco, as tendas, a cobertura da estação e o trem trocam para um
  material meio transparente (`WorldProps.ghost`, alpha 0,35 com tom toon e pré-passo de profundidade)
  quando um personagem está atrás deles na faixa que a câmera de 42° encobre. Depois voltam.
- **O que fica igual:** as sombras de contato e a colisão.
- **Primeira tentativa:** usei a `transparency` do nó, que não teve efeito no renderizador de
  compatibilidade (o pilar continuava opaco nas fotos). Troquei para a troca de material.
- **Placa do Domador:** o poste que a tapava foi de x −4,8 para −3,7.

**Chão:**
- **Facetas:** os quadrados que se viam eram facetas, porque a malha tinha normais por triângulo. Com
  `st.index()` antes de `generate_normals()`, a normal ficou suave.
- **Shader:** manchas em três escalas, torcidas para não formar grade, pedrisco claro e escuro na terra e
  pontinhos na grama.
- **Tufos e pedras:**
  - em moitas de 2 a 7 folhas, com um ruído decidindo os trechos cheios e vazios;
  - pedras soltas ou em dupla;
  - moitas soltas no gramado, longe das trilhas e dos pátios.

**Entradas:**
- **Trem:** cobertura de duas águas listrada de verde e creme com babado, relógio, banco, malas,
  lampiões, faixa amarela na beira, locomotiva com faixas douradas, limpa-trilhos e fumaça, e um vagão
  listrado com janelas acesas.
- **Mágico:**
  - a câmera agora vai até x 17,5, e a placa aparece inteira;
  - a cerca da trilha parou antes da placa;
  - o trem fica transparente quando tapa a frente da tenda.
- **Loja:** o teto ganhou friso dourado e carga, porque é visto de cima quando se anda atrás dela.
- **Malabaristas:** sem mudança. Nas fotos estava legível e sem oclusão.

**Bordas:**
- **Cerca:** de madeira velha nas quatro beiras, com falhas, o portão no sul e a passagem dos trilhos no
  leste.
- **Do lado de fora e no fundo:** moitas de 1 a 4 arbustos do lado de fora; no fundo (norte), fardos,
  barris, caixote e uma roda de carroça encostada.
- **Beira da frente:** as árvores da beira sul (perto da câmera) viraram arbustos baixos, porque tapavam
  a dupla.
- **Paredes e câmera:**
  - As paredes invisíveis vieram para a linha da cerca. Antes ficavam do lado de fora, e a dupla saía da
    tela nos cantos.
  - A câmera vai até z −10 e x −16,5.

**Fotos novas:** `-- entradas <pasta>` mostra a dupla na frente de cada atração e nos quatro cantos e no
meio das beiras.

**Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Pedido T1 na fila:**
- terra batida, 1024 × 1024, RGB opaco, contínua nas quatro bordas;
- 4 m por repetição, vista de cima sem direção dominante;
- paleta e tamanho dos detalhes, sem luz nem sombra pintadas;
- referências em `docs/referencias/texturas/`.
- Depois vem o T2, a grama.

**Retomada (próximos passos concretos):**
1. Esperar o visual do usuário andando no jogo, sem parar o resto. O que ele apontar vem antes de tudo.
2. Quando a T1 chegar:
   - conferir tamanho, alpha, emenda (deslocar 512 px), média de cor e ausência de luz;
   - copiar para `terra_batida.png`;
   - no `world_ground.gdshader`, amostrar com UV = xz × 0,25, tingida pela cor do vértice, e misturar
     pela máscara de terra que o shader já calcula (`dirt`);
   - conferir com `-- mundo` e `-- entradas`.
   - Depois disso, mandar o T2.
3. Se o usuário reclamar do freio, olhar o último passo do palhaço em `_step_feet`
   (`core/world/miniature.gd`): o pé de apoio acompanhar o corpo nos últimos 5 cm.
4. Só depois do M0 aprovado: revisar a folha candidata dos Malabaristas.

### Textura T1 (terra batida) no jogo (03/10, noite)

- **Entrega e medidas:** o Codex entregou `terra_batida_candidata.png` com 1254 × 1254 e o azul 10,9%
  acima do alvo.
  - Foi reduzida por igual para 1024 e recebeu um ganho único por canal; a média ficou a menos de 1% do
    alvo.
  - Emenda: nada visível com a imagem deslocada 512 px, nem no mosaico de 12 m.
  - Bisel fraco nas pedrinhas: não aparece no jogo, onde a pedrinha ocupa de 1 a 4 px.
  - Detalhes e números em "Resultado do T1", na fila.
- **No jogo:** `core/world/art/dirt_albedo.png`, no `world_ground.gdshader`, dividida pela média e
  tingida pela cor do vértice.
- **Modo novo de fotos:** `-- chao` grava a tela inteira, sem reduzir, no portão, no Domador e na loja.
- **Conferência:**
  - a caminhada saiu idêntica (`docs/medidas/caminhada/4_t1_resumo.txt`);
  - `-- mundo` com a dupla andando portão → Domador → loja;
  - bateria: 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.
- **Retomada:**
  1. A T2 (grama) está pronta na fila. Quando chegar, seguir o mesmo roteiro.
  2. A avaliação humana do M0 continua pendente, mas não trava ajustes delegados.
  3. Depois do M0 visual: revisar a folha candidata dos Malabaristas.

### Textura T2 (grama) no jogo e pé cruzado no giro (03/10, noite)

**T2:**
- **Entrega:** veio com 1254 × 1254, média 74,95 / 72,08 / 38,81 contra o alvo 66 / 69 / 42, e 86,6% dos
  pixels dentro de 12% da luminância.
- **Ajustes:** reduzida por igual para 1024 e com ganho único por canal; a média ficou a menos de 1% do
  alvo.
- **Defeitos, conferidos no jogo:**
  - As cunhas escuras embaixo dos tufos quase não aparecem, porque o tufo ocupa de 3 a 8 px.
  - As falhas de terra vieram avermelhadas e viravam manchas vermelhas na grama. Corrigi no shader, sem
    mexer na arte: a grama usa o claro e escuro inteiro da textura e só 30% da cor dela.
- **No jogo:** `core/world/art/grass_albedo.png`, no lugar dos pontinhos procedurais. Detalhes e um T2b
  opcional estão em "Resultado do T2", na fila.
- **Conferência:** `-- chao`, `-- entradas` e `-- mundo`. A caminhada saiu idêntica, e a bateria passou:
  9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Pé cruzado** (`core/world/miniature.gd`, `_step_feet`):
- **O que era:** o pior apoio da terceira rodada (5,1 cm, palhaço) não vinha do freio. Era o seguidor
  virando no lugar quando o Tab começa: o pé de apoio ficava cruzado embaixo do corpo, a rolagem do
  quadril batia no limite e o tornozelo arrastava.
- **Correção:** o pé que passa para o outro lado da linha do meio dá o passo logo, só com o outro pé no
  chão.
  - Na primeira versão, sem essa condição, os dois pés saíam do chão juntos (um pulinho).

| Trecho | Afastamento do pouso, pior (antes, depois) |
|---|---|
| Palhaço, freio (inclui o começo do Tab) | 5,1 cm, 1,9 cm |
| Palhaço, Tab | 0,9 cm, 1,1 cm |
| Palhaço, giro | 3,1 cm, 4,0 cm |
| Acrobata, giro | 2,7 cm, 1,0 cm |
| Acrobata, Tab | 1,7 cm, 1,7 cm |
| Reta, os dois | 0,6 e 0,5 cm, igual |

- **Falha que fica:** o giro do palhaço em velocidade máxima (90°, de andar para a esquerda para andar
  para baixo).
  - É um apoio só, de 4 cm. O tornozelo chega ao ponto de pouso 3 quadros depois de o pé pousar.
  - Tentei limitar o pouso ao alcance horizontal da perna e não mudou nada; voltei atrás.
  - A causa provável é vertical: o quadril baixa no pouso, e o pé pousa abaixo da altura que a perna
    alcança.
  - Não mexi mais. É raro e, a 2,4 m/s, dura 3 quadros.
- **Arquivos:** CSV e resumo em `docs/medidas/caminhada/6_pe_cruzado*`. As medidas anteriores ficaram
  como estavam.
- **Bateria depois disso:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Situação do M0:**
- O trabalho finito está feito: mundo, miniaturas, acabamento, oclusão, entradas, bordas e as duas
  texturas do chão.
- Falta a avaliação humana. Nenhum pedido de imagem do mundo está aberto.
- **Retomada:**
  1. O que o usuário apontar no visual.
  2. Se quiser o giro do palhaço mais limpo: em `_step_feet`, olhar o pouso com o quadril baixando (o
     `_step_kick`).
  3. Depois do M0 aprovado: revisar a folha candidata dos Malabaristas e seguir o M1.

### E1 dos Malabaristas aprovada tecnicamente; Pedido E2 pronto (03/10, noite)

**Situação dos marcos:** o M0 (mapa) está feito e aguarda só a avaliação humana. O usuário pediu para
seguir as animações; a arte de luta do M1 não espera o mapa.

**E1** (folha base, `malabaristas_folha_candidata.png`, 1774 × 887). Detalhes em "Resultado da E1", na
fila.
- **Gêmeos idênticos, medidos:** nariz de 44 × 28 nos dois, branco do olho de 42 × 64 e 42 × 66, e a
  mesma altura.
- **O que difere:** só as listras (vermelho ou azul) e os objetos (bolas ou claves).
- **Direção:** olham para a direita, como o pedido manda.
- **Desvios:**
  - A clave do Teco ficava a 4 px do topo. Foi normalizada para 2048 × 1024 com escala única de 1,1003 e
    ficou com margens de 27 e 35 px (`malabaristas_folha.png`).
  - Tem trilhas de movimento, soltas e sem encostar nos objetos. Ficam só na folha base como referência e
    não entram no jogo.
- **Original:** guardado em `originais/malabaristas_folha_codex_1774x887.png`.

**Decisões (por delegação):**
- **Escala de combate:** uns 230 px do cabelo à sola, a mesma do desenho por código, para as caixas de
  dano e as mãos não mudarem. A E2 é desenhada com 430 px.
- **Teco:** sai da folha do Tico pelo `tools/recolor_twin.gd` (novo).
  - A ferramenta troca só as manchas vermelhas com mediana de listra (S < 0,93 e V entre 0,5 e 0,8).
  - A borda não serve para separar, porque pele e creme têm a mesma cor (medido).
  - Testada na folha base: o Tico recolorido bate com o Teco desenhado, com nariz, língua, pele, luvas e
    sapatos intactos (`malabaristas/teste_teco_por_recolor.png`).
- **Objetos:** as folhas de animação vêm sem objetos. O jogo desenha a bola do Tico e a clave do Teco,
  recortadas da folha base sem as trilhas, nas mãos. Os projéteis dos ataques continuam separados.

**Pedido E2** (Tico parado malabarizando, 8 quadros, pronto na fila):
- caminho da candidata, canvas e células, medidas de cabeça, nariz, olho, luva e sapato;
- sola em 486, margens, as mãos quadro a quadro, o tempo e a cara de cada quadro;
- a regra das cores dos vermelhos (para a troca de cor funcionar);
- o plano de conferência a 60 quadros por segundo.
- O antigo Pedido 2 de `codex_malabaristas.md` ficou como histórico.

**Retomada:**
1. Quando a E2 chegar, seguir o plano de conferência na fila: normalizar, medir, recolorir o Teco,
   recortar os objetos, ligar no `Juggler`, capturar `-- malabaristas_parado` e rodar a bateria.
2. Depois dela, uma folha por vez: arremesso, salto mortal, tonto e derrota.
3. O M0 continua esperando a avaliação humana, sem travar isto.

### E2 dos Malabaristas: recusada como pedida, aproveitada como "chuveiro" e conferida em piloto (03/10, noite)

**Desvio da E2:** os quadros 5 a 7 repetem a mão da frente no alto. Também vieram fora: o tamanho (7% a
mais), as solas, a margem de baixo e um pixel cruzando do quadro 5 para o 6. Recusada como cascata
alternada. Medidas em "Resultado da E2", na fila.

**O que fiz (por delegação):**
1. **Aproveitamento:** os 8 desenhos viraram o padrão "chuveiro", em que a mão da frente sempre joga alto
   e a de trás pega e passa baixo. Sem desenho novo e sem espelhar o rosto.
2. **Normalização:** `regrid_sheet.gd` com âncora `pes` e `limpar`; os pés ficam no mesmo lugar e a sola
   em 486. Resultado: `tico_malabares.png`.
3. **Teco:** gerado por `tools/recolor_twin.gd`, ajustado nesta folha (listras até S 0,93; fiapos
   claros entre os botões; segunda passada nas beiradas). O nariz e a língua não mudaram, conferido nas
   8 caras.
4. **Objetos:** a bola e a clave foram recortadas da folha base, sem as trilhas.
5. **Recorte:** `cut_animation_sheet.gd` (entradas novas): `bosses/jugglers/art/tico/` e `teco/`, com
   230 px no jogo.
6. **No jogo:** `Juggler` usa o desenho no `idle` parado e põe os objetos por código, seguindo as luvas
   medidas em cada quadro.
7. **Piloto a 60 quadros por segundo** (`-- malabaristas_parado`), em três ajustes:
   - O arco alto descia por cima do cabelo e virou uma curva que desce por fora.
   - O passe baixo passava na boca e ficou reto na frente do peito.
   - A clave ficou segura pelo cabo.
   - O maior salto de um objeto entre quadros do jogo (74 px) é a própria mão desenhada mudando de
     lugar a 12 quadros por segundo.
8. **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- é o chuveiro, não a cascata;
- a mão salta entre os desenhos;
- a clave encosta no rosto no quadro 2;
- só o parado é desenho: na luta, o irmão alterna entre o desenho e o boneco de código, e as mãos dos
  ataques ainda são as do código;
- o Teco tem cabelo preto.

**Arquivos guardados:**
- candidata e original: `originais/tico_malabares_codex_1774x887.png`;
- CSV do piloto: `docs/medidas/malabaristas/e2_piloto_60fps.csv`;
- recortes: `malabaristas/piloto_e2_*.png`;
- cópias de antes das mudanças (código, cena, ferramenta e fila): no scratchpad, em `e2/`.

**Retomada:**
1. Pedido E3, o arremesso (4 quadros):
   - medidas da `tico_malabares.png` (430 px no desenho, sola em 486, nariz de 38 × 24);
   - sem objetos;
   - a mão que solta, nos quadros 2 e 3, na altura do `hand_position()` do jogo (frente, uns 150 px
     acima dos pés no jogo, ou seja, y ~186 na célula);
   - piloto com o `juggle_pass` de verdade antes de integrar.
2. Depois, um de cada vez: salto mortal (troca de lugar), tonto e derrota.
3. O M0 continua esperando a avaliação humana, sem travar isto.

### Acabamento E2b do parado dos Malabaristas (03/10, noite)

**Pedido:** acabamento finito dos defeitos visíveis do piloto da E2, antes de pedir a E3. Eram três:
- o objeto saltava 74 px (desenho 7→8) e 56 px (desenho 2→3);
- a luva desenhada saltava 77 px;
- a clave encostava no rosto.

**Método escolhido:** intermediários do braço montados a partir das partes da própria E2, com a
ferramenta nova `tools/juggler_inbetweens.gd`.
- **Descartado: interpolar só o objeto.** A mão desenhada continuaria pulando.
- **Descartado: braços por peças.** Teria de redesenhar a luva e o braço fora do estilo.
- **Descartado: pedir PNG novo.** A E2 já tinha os braços certos, só faltavam as posições do meio.

**Como ficou:**
- Os 4 intermediários (C, A, D e B) põem o braço da frente de um desenho no corpo de outro.
  - O recorte do braço guarda o contorno do tronco, o bigode e a gola.
  - Os pixels soltos que sobram são tirados.
- São 12 desenhos com tempos de 3 e 4 quadros do jogo. A volta (0,667 s) e as solturas são as mesmas.
- A clave é segura pelo cabo, apontando para a frente na mão da frente e para trás na de trás.
- A versão de 8 fica para comparar: `smooth_idle = false`, e o código antigo está em
  `scratchpad/e2b/juggler_chuveiro_v1.gd`.

**Tentativas no caminho (registradas):**
1. **Corpos com o braço erguido:** sobrava a raiz do braço antigo e o bigode saía apagado. Troquei para
   corpos com o braço na mesma altura.
2. **Apagar por retângulos:** cortava o contorno do tronco. Troquei para o miolo do braço com a tinta que
   só encosta nele.
3. **Mesmo ângulo nas duas mãos:** a clave da mão de trás atravessava o peito até o queixo. Separei os
   ângulos.

**Medidas** (3 s, os dois irmãos, as duas versões):

| | Antes | Agora |
|---|---|---|
| Objeto na fronteira de estado | 74,2 px | 13,6 px |
| Luva da frente | 77,2 px | 48,1 px |
| Objeto na mão quando o desenho troca | 38,8 px | 33,5 px |
| Voo alto (velocidade do arco, legítima) | 26,6 px | 26,6 px |

- **Os 48 px que sobram:** a mão vazia descendo depois de soltar.
- **Arquivos:** CSVs e resumos em `docs/medidas/malabaristas/e2b_*`. O CSV de 1 s, preservado.
- **Movimento:** cena `tests/juggler_compare.tscn`, com o Tico e o Teco, 8 e 12, lado a lado. Roda em
  loop (F6) e grava 120 quadros com uma pasta. Foto em `malabaristas/comparar_8_12.png`. Não é
  aprovação: ninguém assistiu ao movimento ainda.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- a mão vazia desce 48 px de uma vez;
- um tique de tinta de ~2 px na raiz do braço em A e D;
- a clave cruza o peito no passe baixo;
- na comparação, o "antes" já usa a clave nova.

**Pedido E3** (arremesso), pronto na fila:
- medidas reais da E2 normalizada (460 px, não os 430 pedidos);
- tempos medidos nos ataques: 0,35 s, com o quadro 3 no instante da soltura;
- luva do quadro 3 embaixo de `hand_position()`, (332, 186) na célula;
- sem objetos;
- piloto com o Troca-Troca de verdade antes de integrar.

**Retomada:**
1. Quando a E3 chegar, seguir o plano dela, que está na fila.
2. Se a avaliação humana achar a mão vazia brusca, um quinto intermediário precisa de outro corpo de
   base: de preferência um pedido focal só do braço.
3. O M0 continua esperando a avaliação humana, sem travar isto.

### E3 dos Malabaristas: arremesso por baixo no jogo, conferido em piloto (03/10, noite)

**Entrega:** a candidata veio em 2173 × 724 (3:1), com as figuras de 501 a 534 px, margens laterais
falhando e o quadro 1 passando 10 px para a coluna 2. O Codex não aprovou. O original está em
`originais/tico_arremesso_codex_2173x724.png`.

**Revisão:**
1. **Normalização:** escala única de 0,882, separando pelos vãos e com os pés no lugar do parado. Ficou
   com 443 a 471 px e nariz de 43 a 46 × 28 a 37, batendo com a E2.
2. **Luva de soltura:** a do desenho 3 fica a 14 px (no jogo) do ponto de onde o objeto sai. Está dentro
   do limite.
3. **Ordem:** a da folha não serve, porque a mão sobe no 2 e volta no 3. O desenho 1 inclina a cabeça
   para a frente.
4. **Primeiro piloto, na ordem 1 → 3 → 2 → 4:** o nariz pulava 47 px. Está registrado como "ordem
   antiga".
5. **Decisão (por delegação):** arremesso por baixo, na ordem 4 → 3 → 2. O desenho 1 fica fora do jogo.
   O nariz passou a pular no máximo 23,8 px, como nas trocas do próprio parado (21,2 px).
6. **Só em pé:** o arremesso desenhado só entra quando o irmão está em pé. Sentado no totem ou no
   monociclo continua o boneco de código.
7. **Piloto** (`-- malabaristas_arremesso`): Troca-Troca e Bolas Quicando de verdade.
   - Todos os objetos apareceram com o desenho de soltura na tela, a 14,3 px da palma.
   - Os pés ficaram parados, e os dois lados estão espelhados.
8. **Comparação:** `tests/juggler_compare.tscn` agora também arremessa a cada 1,5 s.
9. **Teco:** o limite de saturação do `recolor_twin.gd` subiu para 0,99, por causa de uma listra com S
   0,97.
10. **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- o arremesso tem 3 desenhos;
- os 3 objetos do parado somem durante o arremesso;
- quem está sentado continua o boneco de código;
- a palma fica a 14,3 px do objeto, no limite;
- ninguém assistiu ao movimento ainda.

**Pedido E4** (tonto), pronto na fila:
- sem estrelas, que o jogo desenha;
- alto da cabeça onde a bola de cura chega;
- medidas das folhas que estão no jogo;
- pêndulo de 4 quadros a 8 por segundo;
- piloto com o tonto e a cura de verdade.

**Retomada:**
1. Quando a E4 chegar, seguir o plano dela, que está na fila.
2. Depois, uma folha por vez: salto mortal (Troca de Lugar) e derrota.
3. O M0 continua esperando a avaliação humana.

### E4 dos Malabaristas: tonto no jogo, conferido com a cura de verdade (04/10)

A cota renovou no meio da revisão e ela foi retomada sem gerar nada de novo. A candidata e o original
ficaram guardados (`originais/tico_tonto_codex_2048x768.png`).

**Revisão:**
- **Normalização:** escala única de 0,79, pelo nariz.
- **Alpha:** conferido composto sobre cinza; não aparece halo.
- **Alturas:** 445 a 480 px. O meio do pêndulo passa 2% do teto e fica com margem de 7 px; aceitei.
- **Teco:** recolorido.

**Desvio:**
- O pêndulo leva a cabeça até 31 px para fora do ponto da cura.
- **Saída (híbrido):** `head_position()` segue a cabeça desenhada enquanto o irmão está tonto. É só o fim
  do arco da bola; a mecânica é a mesma.

**Corrigido:**
- O irmão que joga a cura ficava preso na pose `throw`, e por isso o Teco não usava o desenho do tonto.
- Agora ele volta ao parado em 0,1 s, e o arremesso da cura começa direto na soltura
  (`Juggler.throw_now()`).

**Piloto** (`-- malabaristas_tonto`), Tico e depois Teco:
- tonto por 4,17 a 4,18 s até a cura pousar;
- a bola pousa no meio da cabeça desenhada; o último quadro visível fica a 24,9 px dela (é a velocidade
  do arco);
- pulos do nariz: entrada de 12,9 a 28,5 px, dentro do pêndulo 36,1 px (com a ponte 4 → 1) e saída de
  14,9 a 16,6 px;
- os pés parados e os dois lados espelhados.

**Bateria:** 9 testes locais com 0 falhas (com o `test_jugglers`: tonto, cura, parry e fase), e o online
normal e com rede ruim ok.

**Limitações:**
- o pêndulo pula 36 px por desenho;
- a bola chega rápido;
- no online, o ponto final pode variar uns quadros entre os PCs (só visual);
- no totem, o tonto continua o boneco de código;
- sobra um fiapo vermelho de ~1 px.
- É teste técnico: ninguém assistiu ao movimento.

**Janela de comparação:** a que abri na sessão anterior foi fechada pelo limite de tempo da tarefa.
Para abrir de novo, `tools/ver_malabaristas.bat`.

**Pedido E5** (salto mortal), pronto na fila:
- agachado, 8 orientações da bolinha (cada desenho, não o mesmo girado) e a aterrissagem;
- o desenho escolhido pelo `spin` real da Troca de Lugar (2 voltas por cima, 3 por baixo, em 1 s) e das
  entradas;
- o meio da bolinha em (256, 280);
- piloto planejado.

**Retomada:**
1. Quando a E5 chegar, seguir o plano dela, que está na fila.
2. Depois: a derrota.
3. O M0 continua esperando a avaliação humana.

### E5 dos Malabaristas (salto mortal) no jogo, e o tonto suavizado (E4b) (04/10)

**E5:**
- **Candidata:** veio em 1448 × 1086, com cruzamentos entre células e bolinhas fora da medida. O
  original está guardado.
- **Normalização:** escala única de 1,28 (pelo nariz), com o meio da bolinha em (256, 280) e os pés no
  lugar do parado no agachado e na aterrissagem. A luva do 10 ficou inteira, separada pelo vão.
- **Orientação:** conferida a olho. É uma volta para a frente; o 8 e o 9 ficam a ~35° um do outro, e o
  rosto do 8 fica de pé. Nenhum desenho foi girado.
- **No jogo:**
  - agachado (`crouch`) → a bolinha pelo giro real → aterrissagem por 0,15 s;
  - os objetos do malabarismo ficam escondidos nesse tempo (o primeiro piloto os mostrava flutuando,
    corrigido).
- **Piloto** (`-- malabaristas_salto`, a Troca de Lugar duas vezes):
  - a orientação nunca voltou para trás, e os 8 desenhos apareceram por volta;
  - meio do desenho: entrada 8,7 px, troca no giro 11,3 px (fora o caminho do ataque, até 54,9 px por
    quadro, que é o mesmo de antes), aterrissagem 8,3 px.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**E4b** (revisão em movimento do tonto, pedida):
- O pulo de 36 px não ficou como "estilo".
- **Assentamento:** a cada troca de desenho, uma inclinação em volta dos pés que endireita em 0,125 s.

| Versão | Nariz | Sapato sobe |
|---|---|---|
| Sem suavizar (a de antes) | 36,1 px | 0 |
| Correção inteira | 23,8 px | 16,8 px |
| Metade (no jogo) | 29,1 px | 8,4 px |

- Fiquei com a metade, porque com a inteira os pés pareciam sair do chão.
- A versão sem suavizar fica para comparar: `smooth_dizzy = false`.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- **Tonto:** o nariz ainda pula 29 px. Se a avaliação humana achar travado, o caminho é um pedido
  focal de desenhos do meio do pêndulo.
- **Salto:** o 8 e o 9 ficam mais juntos que os outros.
- **Entradas do totem e do monociclo:** não foram pilotadas à parte.
- Nenhuma aprovação humana.

**Retomada:**
1. **Pedido E6 (derrota):** ainda não está escrito. Base: a derrota real em `_on_defeated` de
   `jugglers_boss.gd` (o último malabarismo e os dois caindo um em cima do outro). Tempos e pivôs a
   medir no código antes de escrever.
2. **Para ver:** `tools/ver_malabaristas.bat` mostra o parado e o arremesso; o tonto e o salto ainda não
   estão na cena de comparação.
3. O M0 continua esperando a avaliação humana.

### Entradas com o salto, cena de comparação ampliada e Pedido E6 (04/10)

**1. Entradas do totem e do monociclo, pilotadas** (`-- malabaristas_entradas`):
- **Falha:** a base do totem usava o desenho do parado, e o de cima caía na cara dela (245 quadros).
- **Correção:** `Juggler.carrying`, ligado pelo `set_mode`. Quem carrega o irmão fica no boneco de código.
- **Depois da correção:**
  - entrada no giro 8,7 px, giro 11,3 px, saída para sentado ou montado 7,5 px (em relação aos pés);
  - tempos e caixas de dano sem mudança;
  - nenhum objeto no giro.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.
- **Arquivos:** CSVs de antes e de depois em `docs/medidas/malabaristas/e5_entradas*`.

**2. Cena de comparação** (`tests/juggler_compare.tscn`, `tools/ver_malabaristas.bat`):
- **Partes:** parado e arremesso (8 × 12), tonto (sem suavizar × E4b) e salto. As teclas 1, 2 e 3 escolhem
  a parte, e o 0 volta a alternar.
- **Gravação:** com `-- <pasta> parado|tonto|salto`.
- **Tonto:** mantida a metade da correção. Se parecer travado, o caminho é um pedido focal de 4 desenhos
  do meio do pêndulo, não mais código.

**3. Derrota medida:**
- 0,38 s parados no monociclo e, num corte seco, os dois deitados no chão de boneco (Teco por cima, 70 px
  ao lado e 40 px acima) até a tela de fim, aos 2,3 s.
- **Pedido E6, completo na fila:**
  - 4 quadros deitados (batida, quique, assentando, nocaute), sem objetos;
  - células de 1024 × 512;
  - costas na linha do chão;
  - piloto planejado.

**Texto da fila corrigido:** a avaliação humana é para a aprovação final do visual e não trava as decisões
de rotina do M1.

**Retomada:** quando a E6 chegar, seguir o plano dela, que está na fila. Depois, o bloco E dos
Malabaristas está completo (o totem e o monociclo continuam por código, sem pedido).

### E6 dos Malabaristas: derrota no jogo, conferida na derrota real (04/10)

**Candidata:** 1774 × 887, com a fila de cima passando da linha 443. O original está guardado.

**Revisão:**
- **Corte:** no vão transparente real entre as filas (de y ~468 a ~516), sem perder pedaços.
- **Escala:** única de 0,92, pelo nariz (0,98) e pela cabeça (~0,9) juntos.
- **Comprimento deitado:** de 534 a 565 px, contra 430 a 470 pedidos. Aceito pelos braços e pernas
  abertos; a cabeça e o nariz batem.
- **Posição:** as costas na linha 486 (o quique 12 px acima) e o nariz em x ~430.
- **Teco:** recolorido.

**No jogo:**
- **Desenhos:** na pose `down`, 1 → 3 a 10 por segundo e o 4 parado. O Teco começa 0,1 s depois.
- **Monociclo:** vale mesmo carregando o irmão no monociclo.
- **A pilha:** o Teco por cima, com a cabeça no peito do Tico, para os dois rostos aparecerem. As duas
  tentativas que tapavam o rosto estão registradas em fotos.

**Piloto** (`-- malabaristas_derrota`), a derrota de verdade na fase 3:
- 0,38 s no monociclo;
- os dois no chão no quadro 23;
- Tico 2/3/4 nos quadros 30/36/41; o Teco 6 quadros depois;
- caixas de dano desligadas;
- tela de fim aos 2,30 s, como antes.

**Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Limitações:**
- o corte seco do monociclo para o chão continua;
- o lado espelhado (olhando para a direita) não acontece na luta e não foi pilotado;
- o desenho é 15 a 20% mais comprido;
- nenhuma aprovação humana.

**Situação do bloco E:** as poses em pé dos Malabaristas estão desenhadas (parado, arremesso, tonto,
salto e derrota). O totem sentado e o monociclo continuam por código, sem pedido.

**Retomada:**
1. Próximo escopo do M1: o Mágico (bloco E, item 2; `codex_magico.md` Pedido 1 = folha base). Medir no
   código antes de escrever o pedido.
2. A avaliação humana dos Malabaristas em movimento: `tools/ver_malabaristas.bat` e a luta.
3. O M0 continua esperando a avaliação humana.

### Revisão do tonto em sequência e preparação do Mágico (04/10)

**Tonto (E4b em revisão):**
- **Medido por troca de desenho:** sem suavizar, de 26,7 a 36,1 px; com a metade da correção, de 20,1 a
  29,1 px mais um deslize de até 2,7 px por quadro.
- **Conclusão:** continua um pulo a cada 0,125 s. A inclinação não cria pose nova.
- **Decisão:** pedido focal E4c, com 4 desenhos do meio do pêndulo.
  - O meio da cabeça e o nariz de cada um vêm medidos, a meio caminho dos vizinhos na `tico_tonto.png`.
  - No jogo: 8 desenhos a 16 por segundo, sem o assentamento.
  - A versão de agora fica para comparar.
- **Janela de comparação:** deixei aberta na parte do tonto (tarefa em segundo plano, até 2 h). A cena
  agora abre direto numa parte com `-- tonto` (ou `parado` ou `salto`), sem gravar.

**Mágico (bloco E, item 2):**
- **Medido no código:**
  - o pequeno tem ~325 px e olha para a esquerda; caixa de levar tiro 80 × 300, caixa que machuca 56 × 260;
  - a varinha fica em três pontos de mão;
  - o rosto gigante tem 300 × 380, com a cartola de 260 × 290 sobre aba de 400; as mãos ficam a ±470 da
    cabeça, com caixa de 220 × 220;
  - poses e tempos dos ataques registrados na fila.
- **Pedido M1 (folha base), completo na fila:**
  - layout em coordenadas (pequeno à esquerda; cabeça do gigante sem a cartola, a cartola separada e as
    mãos aberta e fechada à direita);
  - paleta e identidade;
  - sem objetos de ataque;
  - arquivo `magico/magico_folha_candidata.png`.
- **Lote M2–M8:** planejado com as poses, o uso, os tempos e o método (híbrido no sumir, nas mãos e no rosto
  com a cartola girada por código).
- O `codex_magico.md` antigo ficou como histórico.

**Testes:** só mudou a cena de comparação (a opção de parte). A importação está ok e ela abriu na parte do
tonto. Não houve mudança no jogo, então a bateria não foi rodada de novo.

**Retomada:**
1. **E4c:** seguir o plano dela, que está na fila.
2. **M1:** revisar a folha base e depois escrever o M2 (parado).
3. O M0 continua esperando a avaliação humana.

### E4c recusada; E4d pedida com um guia visual (04/10)

**E4c** (o meio do pêndulo do tonto, 2172 × 724):
- **Normalização:** escala única de 0,806 (a da `tico_tonto.png`, pelo nariz e pelo sapato), com os pés
  no lugar.
- **Medidas contra o alvo:**
  - o A e o B ficam a 21–23 px na cabeça e 37–38 px no nariz, porque passam do ponto (a cabeça do A está
    onde fica a do desenho 2);
  - o C e o D ficam a 8–14 px.
- **Previsão do piloto** (a mesma medida do piloto): o pior pulo do nariz seria de 35 px, contra 29 hoje e o
  alvo de ~18. Reordenar não resolve.
- **Decisão:** recusada sem integrar. O jogo segue com a E4b. Não fiz híbrido, porque inclinar ou deslocar
  seria fingir pose nova.
- **Arquivos:** a candidata e o original preservados, mais a normalizada e a comparação com os alvos.

**E4d** (pedido focal visual, na fila):
- **Guia:** `tools/onion_guide.gd` gera `malabaristas/guia_tonto_meio.png`, com os dois vizinhos como
  fantasmas e cruzes no alvo da cabeça e do nariz. O desenho novo deve cair entre os fantasmas.
- **Arquivo:** `tico_tonto_meio2_candidata.png`.

**Mágico M1:** em geração pelo Codex; a revisão fica para quando chegar.

**Retomada:**
1. E4d: normalizar com a escala de 0,806 e medir contra os alvos (até 10 px). Só se passar, montar a
   sequência de 8 e pilotar.
2. M1: revisar.
3. O M0 continua esperando a avaliação humana.

### M1 do Mágico aprovada tecnicamente; Pedido M2 pronto (04/10)

**M1** (folha base, 1774 × 887). O original está guardado.
- **Revisão:** 5 peças separadas por grupos ligados, sem pedaços soltos nem buracos no interior. Sobre
  magenta, sem franja.
- **Identidade:** confere com o conceito.
- **Desvios aceitos:** é referência de desenho, e cada folha de animação define a sua escala.
  - Zaratan com 865 px (pedido ~780);
  - aba da cartola com 385 (pedido ~338);
  - mãos com 303 de largura e 233 de altura (pedido ~260 e ~286);
  - corpo invadindo a metade direita e margens de 9 a 10 px.
- **Normalização:** `magico/magico_folha.png`, com as peças na escala 1,0 (sem encolher), recolocadas
  com 24 px ou mais de margem. As peças soltas ficam em `magico/pecas/`.

**Pedido M2** (Zaratan parado), completo na fila:
- 4 quadros a 6 por segundo, células de 512;
- ~465 px de altura (no jogo, 330, a convenção do Domador);
- cartola de 95 e rosto de 67, pelas proporções da folha base;
- sola em 486, a mão da varinha em (186, 246) (`hand_position` do parado);
- a referência é a peça `zaratan_corpo.png`;
- o plano de piloto com a luta real.

**Retomada:**
1. Os próximos pedidos de imagem são o E4d (o tonto, sobre o guia) e o M2 (Mágico parado), um por chamada.
2. Depois de cada um: normalizar, medir e pilotar antes de integrar.
3. O M0 continua esperando a avaliação humana.

### E4d recusada; o tonto segue com a E4b (04/10)

**E4d** (desenhada sobre o guia visual):
- **Normalização:** escala única de 0,886, pelo nariz. A escala da E4c a deixava 8% menor, porque os
  desenhos vieram menores. Os pés ficaram no lugar.
- **Contra os alvos:**
  - só o B cai no alvo (4 px na cabeça, 7 no nariz);
  - o A e o D são, na prática, eretos (cabeça a 18–19 px, nariz a 46);
  - o C fica a 14 px na cabeça e 27 no nariz.
- **Previsão do piloto:** o pior pulo da cabeça seria de 24 px no jogo, e o do nariz passaria de 30. O alvo
  era ~18.
- **Decisão:** recusada, sem integrar, pilotar ou recolorir. Não há híbrido legítimo:
  - só o B deixaria o pêndulo assimétrico;
  - inclinar ou deslocar desenhos seria transformação, não pose nova;
  - fusão de desenhos foi vetada.

**Limite:** duas tentativas numéricas (E4c) e duas visuais (E4d) não controlaram a inclinação. O tonto
segue com a E4b (nariz até 29 px), registrado como um defeito conhecido, sem nova tentativa por enquanto.
- **Se voltar:** um desenho por pedido, com um guia de uma célula só, e o B aproveitado.

**Arquivos:** a candidata e o original preservados, a normalizada e a comparação com as cruzes, em
`malabaristas/tico_tonto_meio2_*`.

**Retomada:**
1. O próximo pedido de imagem é o M2 (Zaratan parado), já completo na fila.
2. O M0 continua esperando a avaliação humana.

### M2 do Mágico (parado) no jogo; Pedido M3 pronto (04/10)

**M2:**
- **Candidata:** 2172 × 724, com as capas cruzando a grade em 3 a 18 px e sem margens. O original está
  guardado.
- **Normalização:** separada pelos vãos (nenhuma ponta perdida), escala única de 0,661, com 465 a 466 px e
  os pés fixos.
- **Desvios aceitos:**
  - a mão da varinha ficou a ~54 px do alvo. No parado ela não lança nada, e `hand_position` não mudou;
  - a mão de trás fica perto do bigode, mas não o enrola com certeza.
- **No jogo** (`magician.gd`): o desenho só na pose `idle`, fora do Blackout, a 6 quadros por segundo,
  espelhado pelo `facing`. O sumir apaga junto.
- **Piloto** (`-- magico_parado`): o parado, o Leque, o Teleporte, os Coelhos e o Blackout de verdade.
  - 654 quadros desenhados, 14 trocas de ida e 14 de volta;
  - pés parados, os dois lados;
  - caixas de dano iguais (80 × 300 e 56 × 260).
- **Bateria:** 9 testes locais com 0 falhas (com o `test_magician`), e o online normal e com rede ruim ok.
- **Limitação:** a troca de estilo entre o desenho e o boneco em cada ataque é grande, até a M3 e as
  seguintes.

**Pedido M3** (varinha), completo na fila:
- `cast` (o preparo de 0,55 s);
- `throw` em 3 quadros em volta da saída das cartas, com a mão do quadro 3 em (129, 218), o ponto de
  `hand_position()`;
- o plano de piloto com o Leque e o Blackout.

**Retomada:**
1. Quando a M3 chegar, seguir o plano dela, que está na fila.
2. O tonto continua com o limite registrado.
3. O M0 continua esperando a avaliação humana.

### M3 do Mágico: o feitiço no jogo; pedidos M3b, E4e e M4 (04/10)

**M3:**
- **Normalização:** escala única de 0,775, pela altura do personagem (não pela caixa com a varinha). Os
  quadros 2 a 4 ficaram com 461 a 469 px.
- **Células de 512 × 640:** necessárias porque a varinha erguida passa de 512. A sola fica em 614.
- **Lançamento:** a luva do quadro 3 ficou a ~56 px (no jogo) de `hand_position()` do `throw`, onde as
  cartas saem. Mudar esse ponto seria mudar a mecânica, e não mudei.
- **Integração parcial:** só o quadro 1 entra, na pose `cast` (o preparo do Leque, o teleporte e as Caixas
  com Serras). O `throw` continua o boneco.
- **Piloto** (`-- magico_parado`, agora com as Serras):
  - 192 quadros com o feitiço desenhado;
  - 15 trocas de ida e 14 de volta;
  - um único "pé andando", que é o teleporte com o Mágico totalmente apagado;
  - caixas de dano iguais.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Pedidos abertos, um desenho ou uma folha por vez, nesta ordem:**
1. **M3b:** só o quadro de lançamento, sobre o guia `magico/guia_varinha_lancamento.png` (fantasmas dos
   quadros 2 e 4, e a cruz na mão em (129, 218)).
2. **E4e:** o desenho A do meio do pêndulo do tonto, sozinho, sobre `guia_tonto_meio_A.png`.
   - O B da E4d passou e foi guardado (`tico_tonto_meio_B_aprovado.png`).
   - O C e o D vêm depois, um por vez.
   - O tonto segue com a E4b até os quatro estarem aprovados.
3. **M4:** batendo na cartola (`tap`, nos Coelhos), em células de 512 × 640, com os tempos dos pulsos.

**Retomada:** quando cada um chegar, seguir o plano dele, que está na fila. O M0 continua esperando a
avaliação humana.

### M3b do Mágico: o lançamento no jogo (04/10)

- **Normalização:** escala única pela altura do personagem (465 px, fator 0,404). A mão aberta ficou a 7
  px do alvo (130, 225 contra 129, 218).
- **Folha:** o desenho entrou no lugar do quadro 3 da `magico_varinha.png`, descido 128 px para a sola cair
  em 614. A folha antiga está guardada.
- **No jogo:** o `throw` usa os desenhos 2 → 3 → 4 pelo tempo na pose. Vindo direto do `cast` (o primeiro
  leque), o preparo é pulado. O primeiro piloto mostrou o primeiro leque saindo no preparo, e foi
  corrigido.
- **Piloto** (`-- magico_parado`):
  - nos 3 leques, o lançamento estava na tela quando as cartas saíram, a 4,8 px da palma desenhada, nos
    dois lados;
  - o Mágico fica desenhado o leque inteiro;
  - trocas com o boneco: de 15 e 14 caíram para 11 e 10;
  - caixas de dano e `hand_position` iguais.
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.
- **Limitação:** o teleporte também mostra o lançamento (as cartas dele saem do corpo).
- **Próximos pedidos, um por chamada:**
  1. E4e (o tonto, desenho A sozinho sobre o guia);
  2. M4 (cartola).

### E4e recusada; o meio do pêndulo do tonto fica como defeito conhecido (04/10)

**E4e** (o desenho A sozinho, 1254 × 1254):
- **Normalização:** escala única pelo nariz (46 × 35, igual à E4), com os pés no lugar.
- **Contra os alvos:** cabeça a 32 px (31 abaixo) e nariz a 21. A altura é de 430 px, menor que os dois
  vizinhos (445 e 480): o corpo está agachado, mas a inclinação e os pés estão certos.
- **Na sequência:** a cabeça desceria 16 px e subiria 52 (26 no jogo).
- **Decisão:** recusado, sem integrar. Esticar o corpo ou subir a cabeça seria fingir pose.

**Decisão sobre o tonto:**
- Três formatos de pedido de imagem falharam:
  - E4c, 4 desenhos por números;
  - E4d, 4 desenhos sobre um guia;
  - E4e, 1 desenho sobre um guia.
  - Só o B da E4d passou.
- O caminho de imagem para o meio do pêndulo está encerrado neste ciclo.
- O recorte por partes (tronco girado sobre outras pernas) é inclinação de parte e foi vetado.
- O tonto segue com a E4b (nariz até 29 px, sapato até 8 px), um defeito conhecido. Precisa de desenho
  feito à mão ou de outro gerador. O B e os guias ficam guardados para isso.

**Janela:** a comparação está aberta na parte do tonto (tarefa em segundo plano, até 2 h).

**Retomada:**
1. O próximo pedido de imagem é o M4 (cartola), completo na fila.
2. O M0 continua esperando a avaliação humana.

### M4 do Mágico (cartola) no jogo; Pedido M5 pronto; correção de escopo do tonto (04/10)

**M4:**
- **Normalização:** escala única de 0,798, pela altura do personagem no quadro 4 (sem a varinha), em
  células de 512 × 640 com a sola em 614.
- **Conferido:** a estrela encosta na copa no quadro 2, com a cartola amassada; o repique e a varinha
  abaixada no 4.
- **No jogo** (pose `tap`): o ataque não avisa qual pulso é o último.
  - Os desenhos seguem um ciclo pelo tempo: bate, repique, erguer.
  - O 4 aparece 0,15 s ao sair de cada pulso.
  - Ajustei os cortes (0,08 e 0,16) para cada pulso não terminar com um quadro de "erguer".
- **Piloto** (`-- magico_parado` mais a tira dos Coelhos):
  - a sequência certa;
  - espelhado, com os pés parados, os coelhos só do jogo e a estrela na cartola;
  - na luta inteira, só 2 trocas para o boneco (o `bow` e o `scared` não estão no roteiro).
- **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Pedido M5** (sumir), na fila:
- 4 desenhos do corpo se enrolando na capa, sem fumaça;
- escolhidos pelo valor do `vanish`, com a transparência por cima;
- na volta, ao contrário;
- teleporte e Jogo das Três Caixas no piloto.

**Correção de escopo do tonto:** o veto é a transformação do corpo inteiro fingindo desenho novo, não todo
método por peças.
- Depois do resto do Mágico pode haver um piloto híbrido por peças (pés fixos, a parte de cima com
  curvas, comparado com a E4b), chamado assim.
- Sem pedir outro gerador nem desenho de fora agora.

**Retomada:**
1. Quando a M5 chegar, seguir o plano dela, que está na fila.
2. Depois: M6 (reverência e derrota), M7 (mãos gigantes) e M8 (rosto gigante), um por vez.
3. Depois do Mágico, o piloto híbrido do tonto, se for viável.

### M5 do Mágico (sumir) no jogo; Coelhos nos dois lados; Pedido M6 pronto (04/10)

**M5:**
- **Separação:** por peças inteiras; o corte da grade partia o quadro 1.
- **Escala:** única de 0,71, pela altura do personagem no quadro 1. A coluna e a cartola ficaram menores
  de propósito.
- **Montagem:** células de 512 × 640, com o fundo de cada peça na sola em 614.
- **No jogo:** o desenho sai do valor do `vanish` (1 a 4), com a transparência por cima; na volta,
  ao contrário.
- **Piloto** (`-- magico_sumir`):
  - os dois teleportes saíram na ordem 1, 2, 3, 4, 3, 2, 1, com os dois lados;
  - no Jogo das Três Caixas, a ida saiu 1 → 4.
- **Limitação real:** no Jogo das Três Caixas ele desliza ~95 px enquanto some. O ataque move o nó, e o
  boneco antigo também deslizava.

**Pendência da M4 fechada:** os Coelhos agora foram pilotados nos dois lados, com 131 quadros de `tap`
para cada lado.

**Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Pedido M6** (reverência e medo), completo na fila. São as duas últimas poses do pequeno em boneco:
- a reverência na entrada da fase 2 (0,9 s) e no Jogo das Três Caixas;
- o medo na entrada da fase 3 (0,6 s).

**Retomada:**
1. Quando a M6 chegar, seguir o plano dela, que está na fila.
2. Depois: M7 (mãos gigantes) e M8 (rosto gigante), um por vez.
3. Depois, o piloto híbrido por peças do tonto, se for viável.
4. O M0 continua esperando a avaliação humana.

### M6 do Mágico (reverência e medo) no jogo; nova prioridade: marco de gameplay do Mágico (04/10)

**M6:**
- **Separação:** por peças inteiras.
- **Escala:** única de 0,756, pela altura do personagem em pé no quadro 3. O quadro 4 fica 24 px mais
  baixo, porque ele se encolhe tremendo.
- **Células de 640 × 640:** a reverência funda, com a cartola na mão, não cabe em 512 sem encolher.
- **No jogo:**
  - `bow`: 1 até 0,3 s, depois 2;
  - `scared`: 3 e 4 a 12 por segundo;
  - o tempo na pose só conta com ele à vista;
  - ao sair da reverência, o 1 fica 0,1 s.
- **Fim do boneco:** acabou o boneco por código no Mágico pequeno (só os olhos no Blackout).
- **Piloto** (`-- magico_reverencia`, com `virado` e `fim`): entradas das fases 2 e 3, nos dois lados; Três
  Caixas até reaparecer; derrota ainda pequeno; 0 trocas para o boneco.

**Defeito achado:** nas Três Caixas a reverência desliza 885 a 912 px até a caixa (o ataque move o nó). Os
"95 px" da M5 eram só o trecho sumindo.

**Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.

**Nova prioridade do usuário (antes de M7 e M8):** um marco de gameplay do Mágico, com mudança de mecânica
autorizada:
- cartas perseguidoras, uma por salva no Leque de Cartas, no lugar de uma reta;
- alvos alternados P1 → P2 entre as salvas, persistindo durante a luta;
- rosas para parry garantidas;
- aviso de alvo antes do lançamento;
- embaralhar das caixas sorteado por execução e igual nos dois PCs.

**Retomada:**
1. O marco de gameplay do Mágico, com plano e baselines registrados antes de alterar.
2. Depois: um pedido completo da M7 (mãos gigantes), depois a M8.
3. Depois, o piloto híbrido por peças do tonto, se for viável.
4. O M0 continua esperando a avaliação humana.

### Marco de gameplay do Mágico: plano e linhas de base (04/10)

**Pedido do usuário:**
- cartas que atiram e machucam;
- algumas rosas para parry;
- algumas perseguidoras;
- salvas alternando P1 e P2, numa dificuldade alta mas possível;
- embaralhar das caixas sorteado.

É uma mudança de mecânica autorizada. O plano completo está no DESIGN.md ("Marco de gameplay do Mágico").

**Auditoria (só leitura) antes de alterar:**
- **`card_fan.gd`:** 3 leques aos 0,55, 1,2 e 1,85 s, um buraco por leque e um ás rosa por ataque.
- **`magician_attack.launch`:** reto, pelo tempo.
- **`MagicProp`:** é `EnemyHitbox`, e a rosa aceita parry pelo `parry_id`.
- **`shell_game._start`:** sorteia a caixa e 5 trocas pela semente do ataque. A semente vem do
  `_brain_rng.randomize()` do host, então muda a cada execução e é a mesma nos dois PCs.
- **Ordem dos jogadores:** hoje o `_args_for` ordena os vivos pelo nome. O alvo novo usa o slot (0 = host
  = P1).

**Linhas de base:**
- **Leque:** 12 cartas retas por ataque, 1 rosa, nenhuma perseguidora.
- **Três Caixas, em 1000 sementes:**
  - 982 planos distintos;
  - 1341 de 4000 trocas seguidas desfazem a anterior;
  - a caixa dele não se mexe em 4 sementes e se mexe uma vez em 44
    (`scratchpad/gp/shell_stats.gd`, `shell_base.txt`).

### Marco de gameplay do Mágico: resultado (04/10)

**Feito** (detalhes e números no DESIGN.md, "Marco de gameplay do Mágico"):
- **Leque de Cartas:**
  - uma carta preta por leque, no lugar de uma reta;
  - ela persegue por 0,8 s (560 px/s, até 120°/s) o jogador da vez: P1, P2, P1... pela luta toda;
  - uma placa "P1"/"P2" sobre o alvo 0,5 s antes;
  - mira só quem está de pé;
  - duas rosas por ataque, na altura do pulo;
  - o host decide o alvo e o giro, e o cliente recebe e calcula a mesma trajetória.
- **Três Caixas:** nenhuma troca desfaz a anterior, e a caixa dele se mexe pelo menos 2 vezes. O plano
  continua vindo da semente do host.

**Piloto comparativo com bots** (luta real, 60 fps, conjuntos A, B e C):
- parado leva a preta 100% das vezes;
- andando, 78–100%;
- pulo ou dash na hora, 0%;
- o bot de parry fez 9 parries, todos com P1 (P2 0; ver a revisão);
- **Escolha:** o B.
- **Achado no caminho:** as rosas sorteadas em qualquer direção muitas vezes passavam fora do alcance; agora
  saem só nas direções da altura do pulo.

**Testes:**
- o `test_magician` cobre a alternância (9 salvas), P2 caído, ninguém de pé, o alvo caindo em voo, o
  parceiro saindo, o dano real, o parry e o embaralhar (200 sementes);
- o `test_online` cobre o mesmo plano nos dois PCs (normal e ruim) e a correção no cliente (14,6 px no
  máximo).

**Bateria:** toda verde.

**Limitações:**
- os bots não fizeram uma rodada inteira sem contato;
- "difícil mas possível" precisa do teste humano;
- a preta também pega o parceiro no caminho;
- a placa pode aparecer atrasada no cliente;
- o deslize da reverência nas Três Caixas continua.

**Retomada:**
1. O pedido M7 (mãos gigantes) está pronto na fila; quando chegar, seguir o plano dele.
2. Depois: a M8 (rosto gigante).
3. Depois, o piloto híbrido por peças do tonto, se for viável.
4. Teste humano do Mágico: o Leque de Cartas com as pretas e as Três Caixas.

### Revisão do marco de gameplay do Mágico: plano (04/10)

**Pedido do usuário:** depois do resultado técnico, fechar uma revisão finita antes da M7:
1. parry e dano reais nos dois jogadores e pela rede (o cliente dando parry com o input real);
2. a saída de verdade do P2 durante o rastreio;
3. as Três Caixas sem o deslize, pela coreografia do DESIGN.md ("Revisão do marco").

**Correção do resumo anterior:**
- o bot de parry fez 9 parries com P1 e 0 com P2;
- as pretas acertaram 12 de 18 nesse piloto, com contatos no parceiro e em retas;
- "difícil mas possível" segue pendente do teste humano.

**Linhas de base mantidas:**
- os parâmetros B das pretas;
- 885 a 912 px de deslize em reverência, mais ~93 px sumindo;
- 242,5 px de salto ao reaparecer.

### Revisão do marco de gameplay do Mágico: resultado (04/10)

**Três Caixas sem deslize:**
- ele faz a reverência no lugar enquanto só a tampa da caixa dele abre;
- some pela capa no lugar e, invisível, vai até a caixa;
- aparece enrolado na capa na frente da tampa aberta e afunda;
- na revelação desenrola da capa na caixa certa.

**Primeira versão (falha):** sumia no lugar sem aparecer na caixa, o que enganava quando ele começava na
frente de outra caixa.

**Defeito antigo corrigido:** no embaralhar ficava uma cartola a ~4% de opacidade no lugar de entrada.

**Piloto:**
- 0,0 px à vista (antes, 885–912 px mais ~93 px);
- na revelação, salta 5,4 px (antes, 242,5 px).

**Parry:**
- **Antes:** o bot do P2 nunca deu parry (pulava cedo e ficava em cima do trapézio).
- **Bot corrigido:** só o P1, 11 parries; só o P2, 11 parries; os dois, a rosa estoura no primeiro da fila.
- **Online, normal e ruim:**
  - o cliente deu 2 parries com o input real;
  - as rosas estouraram nos dois PCs;
  - a recompensa conta uma vez;
  - a preta machucou os dois sem invencibilidade;
  - o aviso chegou com até 0,103 s de atraso;
  - a correção foi de até 15,5 px.
- **Local:** a rosa machuca sem parry.

**Saída de verdade** (menu de pausa, normal e ruim):
- no host, a preta para de virar e as salvas seguintes miram P1, com o contador até 4;
- o cliente vai ao menu, as cartas somem e ele volta.

**Evidências:** `docs/medidas/magico/revisao_*` e `logs_revisao/`. **Bateria:** toda verde.

**Continua pendente:** o teste humano de "difícil mas possível".

**Retomada:**
1. Gerar a M7 (pedido completo na fila); quando chegar, seguir o plano dele.
2. Depois: a M8.
3. Depois, o piloto híbrido por peças do tonto, se for viável.

### M7 do Mágico (mãos gigantes) no jogo; agarradas corrigidas; vida do chefão reenviada; Pedido M8 pronto (04/10)

**M7:**
- **Separação:** por peças inteiras (a mão 1 cruzava a grade).
- **Escala:** única de 0,891.
- **Âncora:** o botão dourado da manga, então o pulso fica parado.
- **Células de 640** (a mão aberta não cabe em 512).
- **Pivô:** no meio do punho e 175 px acima do fundo dele.
- **Desvio aceito:** o punho sai uns 7–11% maior, como nas peças aprovadas da M1.
- **No jogo:** o desenho sai do `closed`, e a mão da direita é espelhada.

**Piloto** (`-- magico_maos`):
- 1 → 4 → 1 contínuo nas duas mãos;
- golpe só nos desenhos 3 e 4;
- área de dano acima do chão 62–82% dentro do desenho.

**Defeito achado e corrigido** (`grab_hands.gd`): a 2ª agarrada da mesma mão puxava a mão do chão para o ar,
já aberta, com o golpe da 1ª ainda ligado (pulo de 298 px, 3 quadros de dano injusto). Agora cada mão segue
só a agarrada mais nova, sem mudar os horários. O teste novo falha com o código antigo.

**Rede:** numa bateria, com rede ruim, o cliente não viu o bônus da caixa certa. A vida do chefão ia só
quando mudava, por um canal que perde mensagens. Agora o host a reenvia a cada 0,5 s (`boss_sync.gd`), e 3
rodadas seguidas com rede ruim passaram.

**Falha não explicada no mesmo log:** o Leque no cliente sem contato nem parry, que não se repetiu em 5
rodadas. Logs em `docs/medidas/magico/logs_m7/`.

**Bateria final:** toda verde.

**Pedido M8** (rosto gigante de frente, sem cartola, 4 expressões) pronto na fila.

**Retomada:**
1. Gerar a M8; quando chegar, seguir o plano dela.
2. Depois, o piloto híbrido por peças do tonto (pés fixos, sem fingir desenho novo, linha de base E4b
   guardada), se for viável.
3. O teste humano do Mágico continua pendente.

### M8 do Mágico (rosto gigante) no jogo: o Mágico está todo desenhado (04/10)

**M8:**
- **Separação:** por peças inteiras.
- **Identidade:** pela largura nas orelhas (370 a 380 px).
- **Escala:** única de 0,921.
- **Montagem:** células de 640, com o pivô no meio da cabeça.
- **Cartola:** a da M1, como peça girada pelo `hat_tilt`.
- **Desenhos:**
  - gargalhada pelo `laugh`;
  - bravo ao levar tiro (0,25 s, no máximo uma vez por segundo);
  - tonto desde a derrota (o chefão avisa o gigante; na primeira rodada ele sorria 81 quadros antes de
    encolher).

**Piloto** (`-- magico_rosto`): a fase 3 inteira, com a cartola presa à cabeça (0,00 px) e girando até
0,6 rad.

**Bateria:** toda verde.

**Limitações:**
- a área de dano da cabeça fica 73–77% coberta;
- a cartola é mais baixa que a do código;
- 1 px de buraco no quadro 2;
- a falha rara do Leque no cliente continua sem causa.

**Logs:** `C:\jogo-coop\docs\medidas\magico\logs_m8\` e `m8_piloto_*`.

**Retomada:**
1. O piloto híbrido por peças do tonto (plano a registrar antes).
2. O teste humano do Mágico continua pendente.

### Piloto por peças do tonto: não viável; próximo defeito, a falha rara do Leque no cliente (04/10)

**Plano:** o único osso possível seria a cabeça, cortada na gola de babado. Ela andaria numa curva contínua
entre as posições desenhadas, com os pés plantados e sem a inclinação inteira da E4b. O tronco não serve,
porque os braços ligam os ombros às mãos apoiadas nos joelhos.

**Por que não dá:**
- Nos desenhos 1 e 3 (os extremos do pêndulo), a cabeça fica na frente da gola: bigode, língua e bochecha
  tapam o babado, que não existe por baixo.
- Com a cabeça por cima, deslocá-la 6 px de jogo abre buraco onde ela tapava.
- Com a gola por cima, a gola cortaria o bigode e a língua.
- Toda troca envolve um extremo, então o osso só serviria às cabeças do meio, tirando no máximo ~6 px dos
  29,1.
- Preencher a gola seria inventar desenho.
- Evidência: `docs/referencias/pecas/malabaristas/tonto_osso_cabeca_gola.png`.
- Uma prova automática por máscara de cor saiu com listras (a máscara pegou pontos dourados no rosto). Foi
  descartada e não serve de evidência.

**Decisão:** a E4b (29,1 px no nariz, 8,4 px no sapato) continua como defeito conhecido. Para comparar:
`tools/ver_malabaristas.bat` com `-- tonto`.

**Próximo defeito real:** a falha rara do Leque no cliente com rede ruim (sem contato nem parry; logs da M7).
**Plano finito:** 6 rodadas do teste online com rede ruim, com o diagnóstico de posição, guardando cada log.

### Falha rara do Leque no cliente: causa provável no próprio teste; duas outras falhas do teste online (04/10)

**Falha:** numa bateria da M7, com rede ruim, o cliente mediu o Leque de Cartas "sem contato nem parry" e com
passo extra da preta de 0,0 px.

**Causa provável** (o teste, não o jogo):
- a 10c esperava `fan.is_running()`;
- com rede ruim, o Leque da seção anterior (10b, semente 777) ainda pode estar no fim no cliente, porque ele
  termina aos 4,65 s e o cliente sai da 10b aos 3,6 s mais o encontro;
- a espera voltava na hora com o ataque velho, e o laço media só o fim dele, com as cartas já retas, perdendo
  o ataque novo inteiro.
- A assinatura bate com o log original: 0 contatos, 0 parries, passo 0,0 px, e 3 pretas no host em vez
  de 2.
- Não dá para provar que foi isso naquela vez, porque o log não tinha o diagnóstico.

**Correção:** cada seção espera o ataque com a sua semente (10c 100, 10d 300, 10e 55) e imprime a semente e
o tempo em que começou a medir.

**Mais duas falhas do teste, achadas nas rodadas de confirmação:**
1. **Limite geral de 190 s estourado no fim** (com as seções novas e rede ruim). Subiu para 260 s, com o
   motivo no código.
2. **Uma reconexão falhou** (`join_failed`) logo depois de sair pelo menu. O teste só esperava `joined` e
   travou até o limite. Agora tenta de novo até 3 vezes, como um jogador faria. A falha de conexão em si fica
   registrada como intermitente.
   - O log dessa rodada tem bytes nulos e um "FAIL timeout" foi parar no log da rodada seguinte: um processo
     da rodada travada ainda escreveu depois.

**Rodadas** (`docs/medidas/magico/logs_falha_rara/`):
- **Código antigo, 1 rodada:** interrompida por mim, não conta.
- **Esperando a semente, 6 rodadas:**
  - 4 sem falha;
  - 1 estourou os 190 s no fim;
  - 1 travou na reconexão.
- **Com as três correções:** 3 rodadas sem falha, mais a bateria completa.

**Dados nas rodadas boas:**
- o cliente começou a medir o Leque novo com 0,10–0,18 s de atraso;
- 2 parries em todas;
- o aviso do alvo chegou com até 0,151 s de atraso;
- a correção da preta no cliente foi de 6,9 a 29,7 px (limite de 40 no teste, só informativo).

**Status:** causa provável identificada e corrigida no teste. Não declaro resolvida só por rodadas verdes.

**Bateria final:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok
(`logs_falha_rara/confirmacao/bateria.log`).

**Retomada:**
1. Nenhum pedido de imagem aberto. O Mágico e os Malabaristas estão desenhados; o tonto segue com a E4b.
2. Avaliação humana pendente: o Mágico inteiro (Leque com as pretas, Três Caixas, mãos e rosto da fase 3)
   e o tonto (`tools/ver_malabaristas.bat` com `-- tonto`).
3. Próximo trabalho delegado: escolher com o usuário o próximo marco do roadmap (DESIGN.md), sem inventar
   ataque, chefão ou área.

## Frente de arte e animação com o Codex (02/10/2026, noite)

Nova autorização: o Codex gera os PNGs das animações que faltam; o Claude faz o inventário,
escreve os pedidos (uma folha por pedido), recorta, integra e valida no Godot, sem mudar
mecânicas, colisões, saída do tiro, rede ou controles. Sem git. Prazo: segunda, 05/10, às 09h
(prioridade, não garantia).

- **Fila:** `docs/prompts/fila_animacoes_codex.md`. Blocos: A jogadores (parry, parado, pulo,
  balão, dash, abaixado, dano), B Leopoldo (salto, fogo, derrota), C Domador, D especiais,
  E Malabaristas, Mágico, trem e mapa.
- **Regras novas do usuário** (já na fila): folhas dos jogadores sempre 2048 × 1024, 4 × 2, células que sobram transparentes (o balão vira duas folhas de 8); olhos abertos no parado; o leão mantém as proporções das folhas prontas (uns 565 px de largura com 440 de altura), sem esticar até 880.
- **Ferramentas:** `tools/regrid_sheet.gd` (normaliza o tamanho e recentraliza cada quadro na célula); `tools/cut_animation_sheet.gd` agora aceita o nome da folha (`-- palhaco_parry.png`) e recorta só ela, sem regravar as outras.

| Pedido | Folha | Situação |
|---|---|---|
| A1 | palhaco_parry.png | **No jogo.** Recebido em 1774 × 887 (RGBA, fundo com alpha 0). Conferido quadro a quadro: a cambalhota gira sempre para a frente, o quadro 5 fecha a volta e não há braço sobrando; aprovado. Original guardado em `docs/referencias/pecas/originais/palhaco_parry_codex_1774x887.png`. Normalizado para 2048 × 1024 (fator 1,1545, sem distorção; os 8 quadros centrados em (256, 280), nenhum na borda). Recortado em `core/player/characters/clown/parry/` (mesma escala da corrida, uns 900 KB). O `CharacterRig` ganhou `parry_animation` (troca o quadro pelo progresso do parry e esconde o braço da arma); o `Player` só gira o desenho quando não há parry desenhado (a acrobata continua girando até o A2). Fotos no jogo: sequência certa, sem giro, sem pistola, volta à pose normal no fim. Bateria completa: 9 testes locais com 0 falhas e 0 erros de script; online normal e com rede ruim, ok. Nada de mecânica, colisão, tiro, rede ou controle mudou. |
| A2 | acrobata_parry.png | **No jogo.** Recebido em 1774 × 887 com alpha real (correções do Codex: braço extra dos quadros 6 e 7, piscadinha no 8, pernas do 1 dobradas). Conferido: duas pernas e dois sapatos em todos os quadros; o 3, o 4 e o 5 giram para a frente como no A1; escala certa (o quadro 6 fica com uns 462 px). Original em `docs/referencias/pecas/originais/acrobata_parry_codex_1774x887.png`. Na normalização, as faíscas do quadro 7 passavam da linha da célula e pedaços caíam na célula do 8: o `regrid_sheet.gd` passou a separar os quadros pelo vão transparente mais perto da linha da grade (o A1 refeito com a ferramenta nova sai idêntico ao aprovado). Os quadros 4, 7 e 8 têm 466 a 485 px de altura e subiram até 10 px para caber nos 512. Recortado em `core/player/characters/acrobat/parry/` (escala da corrida da acrobata, uns 780 KB) e ligado no `acrobat_rig.tscn`. Fotos no jogo: cambalhota desenhada, sem giro, sem pistola, volta à pose normal. Bateria completa: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Sem git, sem mudança de mecânica. |
| A3 | palhaco_parado.png | **No jogo.** Recebido em 1774 × 887 com alpha real. Original em `originais/palhaco_parado_codex_1774x887.png`. Normalizado com a âncora nova `pes` do `regrid_sheet.gd`: sola em 486 e o meio dos pés em x = 256 em todos os quadros (o meio dos pés variava só 137 a 140 px, então os pés ficam cravados). Alturas de 435 a 448 px; o **quadro 6 fica com 416** (24 px abaixo do 5): aparece como uma descida do chapéu um pouco maior, e o pedido de correção A3b está pronto. Nariz achado em todos os quadros (x 376–379), então o ombro da pistola acompanha a respiração. O `CharacterRig` ganhou `idle_animation`: toca a 8 quadros por segundo quando está parado no chão (sem correr, dash nem abaixado); o braço da arma continua por código. Recortado em `core/player/characters/clown/idle/` (uns 920 KB). Fotos no jogo (`screenshots.tscn -- parado`): pés parados, braço preso ao ombro, volta 8→1 suave. Bateria completa: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. |
| A4 | acrobata_parado.png | **Candidata recusada (não integrada).** Recebida em 1774 × 887 com alpha 0 no fundo; original em `originais/acrobata_parado_codex_1774x887.png`. Normalizada só no scratchpad, com âncora `pes`: o meio dos pés fica fixo (145 a 151 px), mas os quadros 1 a 4 têm 508 a 510 px de altura e os 5 a 8, 482 a 483. Pulo de uns 27 px no 4→5 e no 8→1 (limite: 15 px), e mais alta que os 465 px da corrida. Também há pontinhos vermelhos e amarelos perto das pernas. O `docs/referencias/pecas/acrobata_parado.png` continua sendo a candidata do Codex; nada foi recortado nem ligado no jogo. A acrobata segue com o parado de peças. Ajuste no `regrid_sheet.gd`: corta primeiro as colunas e depois o vão entre as filas dentro de cada coluna (as três folhas aprovadas refeitas com a ferramenta saem idênticas). |
| A4b | acrobata_parado_v2.png | **Recusada (não integrada).** Original em `originais/acrobata_parado_v2_codex_1774x887.png`. Medidas: fila de cima 500–501 px, de baixo 483–484 (17 px, acima do limite); largura/altura 0,520–0,527 em cima e 0,542–0,549 embaixo; nariz a 0,230–0,234 e 0,242–0,246. A fila de cima está uns 4–5% esticada, então não é só escala: com escala por fila até 465 px, cabeça e coque de baixo ficam visivelmente maiores (foto no scratchpad). Pontinhos: grupos soltos de 37 a 93 px por quadro; a opção nova `limpar` do `regrid_sheet.gd` tira só esses. O `regrid_sheet.gd` também ganhou `medir` e `altura=N`. As três folhas aprovadas, refeitas com a ferramenta, saem idênticas. |
| A4c | acrobata_parado_v3.png | **No jogo (03/10).** Original em `originais/acrobata_parado_v3_codex_1774x887.png`. Medidas: os 8 quadros com 480–481 px, largura/altura 0,563–0,573, nariz a 0,244–0,247, meio dos pés 141–146. Montagem: os 8 quadros da própria A4c (a sugestão era usar os 4 de baixo da A4b, mas eles têm largura/altura de 0,542–0,549, uns 4% mais estreitos que os de cima novos; misturar traria de volta o pulo no 4→5; os de baixo da A4c batem com os de cima). Preparação: `regrid_sheet.gd ... pes limpar altura=465` (escala uniforme 0,969/0,967 por fila, sem deformar; a limpeza tirou só grupos soltos de 71 a 147 px por quadro), salva em `docs/referencias/pecas/acrobata_parado.png` (a candidata A4 recusada ficou em `originais/`). Nariz achado em todos (x 322–327, y 138–141). Fundo claro e escuro sem franja. Recortado em `core/player/characters/acrobat/idle/` (uns 740 KB) e ligado no `acrobat_rig.tscn`. Fotos no jogo: pés cravados, ombro da pistola certo, ciclo suave. |
| A3c | palhaco_parado_v3.png | **No jogo (03/10), só o quadro 6.** Original em `originais/palhaco_parado_v3_codex_1774x887.png`. Montagem: os 7 quadros do original aprovado + o 6 da A3c (`merge_frame6.gd` no scratchpad). Medidas 5/6/7 = 440/444/436 (+4/−8; o maior salto do ciclo continua sendo o 3→4 aprovado, 13 px); nariz do 6 a 0,171, igual aos vizinhos (0,167–0,170). O 6 ficou 4 px mais alto que o 5, e não 3 px abaixo como pedido, mas a respiração fica suave. Comparação célula a célula com a folha anterior: só o quadro 6 mudou (os outros 7 com 0 pixels diferentes). Recortado de novo e conferido em fotos. A alternativa de 7 quadros não foi aplicada. |
| — | bateria | 03/10: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Sem git, sem mudança de mecânica, arma, colisão, rede ou controles. |
| A5 | palhaco_pulo.png | **No jogo (03/10).** Recebido em 1774 × 887 com alpha 0 no fundo, os 8 quadros no ar; original em `originais/palhaco_pulo_codex_1774x887.png`. **Escala:** o desenho veio uns 20% menor que o resto do palhaço. Medida pela cabeça, que não muda com a pose: do topo do chapéu ao nariz dá 54–61 px nos quadros do pulo (já em 2048) contra 70–76 (mediana 73) no parado aprovado; o quadro 4 dá 72 porque o chapéu levanta, então ficou fora da conta. Fator único para a folha inteira: 73/58 ≈ **1,26** (opção nova `escala=F` do `regrid_sheet.gd`). Conferência: o quadro 1, esticado, fica com 446 px, na faixa do parado em pé (435–448). Alturas depois da escala: 446, 431, 398, 404, 378, 427, 411, 426. A diferença entre as poses (encolhido x esticado) foi mantida, sem igualar. Preparação: `regrid_sheet.gd ... 4 2 ar limpar escala=1.26`, com 0 avisos: todos com o meio em (256, 280) e nenhum na borda. A limpeza tirou só grupos soltos de 40 a 98 px por quadro. **Conferido:** mesmo palhaço nas duas filas (cabeça, chapéu com margarida, gola, dois botões dourados à vista), nariz visível em todos (x 392–409), só o braço de trás e sem pistola. Fundo claro e escuro sem franja. Recortado em `core/player/characters/clown/jump/` (uns 850 KB, 8 texturas pequenas, sem custo perceptível). O `CharacterRig` ganhou `jump_animation`: no ar e sem dash, o quadro sai da velocidade vertical (limites de −950, −550, −200, 0, 200, 550 e 950 px/s), então pulo curto, pulo alto, Sapatos de Mola e queda da beirada funcionam sem relógio. Prioridade: parry > pulo > corrida > parado. O braço da arma segue o ombro de cada quadro. **Fotos de um pulo real** (`screenshots.tscn -- pulo`, modo novo): parado → 1 → … → 8 → pouso → parado, sem salto de tamanho, braço preso ao ombro e pouso com o amassado de código. A acrobata continua com o pulo de peças até o A6. Nenhuma mecânica, colisão, tiro, rede ou controle mudou. |
| A3b | palhaco_parado_v2.png | **Recusada (não integrada).** Original em `originais/palhaco_parado_v2_codex_1774x887.png`. O quadro 6 foi para 453 px (5 = 441, topo da respiração = 449), e os outros sete mudaram 1–3 px. Folha de preparação (os 7 do original + o 6 novo, `merge_frame6.gd` no scratchpad): 5/6/7 = 440/453/436 (+13/−17, limite 15); nariz do 6 a 0,157 da altura contra 0,167–0,170: cabeça e chapéu esticados, escala uniforme não resolve. O jogo segue com o A3 aprovado. Alternativa só de integração, a decidir pelo usuário: loop de 7 quadros pulando o 6. |
| A3c | palhaco_parado_v3.png | pedido focal pronto (quadro 6 = quadro 5 com o tronco 3–4 px mais baixo; alvo de 376 a 379 px na folha de 1774) |
| — | bateria | 03/10, depois do A5: 9 testes locais com 0 falhas e 0 erros de script; online normal ok. Online com rede ruim: **1 falha intermitente** na 1ª rodada (`right box hit by the client: bonus damage (0)`, a caixa certa do Mágico acertada pelo cliente; não tem relação com desenho). Rodado de novo 3 vezes, passou nas 3 (0 falhas no host e no cliente). Fica anotado como teste instável a olhar. |
| A6 | acrobata_pulo.png | **No jogo (03/10).** Recebido em 1774 × 887 com alpha 0. Original em `originais/acrobata_pulo_codex_1774x887.png`. **Bordas (ressalva do Codex):** a 1ª linha e as 4 primeiras colunas da folha estão vazias. O coque do 2 começa na 2ª linha e o sapato do 5 na coluna 6, e os dois contornos fecham (conferido com zoom), então nada foi cortado. O vão entre o sapato do 2 e o coque do 6 também está limpo. O aviso "encosta na borda" do quadro 2 no `regrid_sheet.gd` é só isso. **Escala:** a cabeça veio maior. Na escala da folha (1,1545), a largura da cabeça na linha dos olhos dá 162–172 px contra 157 no parado, o branco do olho 41–43 contra 40–41, e coque-nariz 120–121 nos quadros 1 e 2 contra 113. Nos quadros 3 a 8, coque-nariz dá 133–143, mas é a cabeça inclinada que aumenta a distância vertical, então essa medida não entrou. Fator único para a folha toda: **0,94**, sem igualar as alturas das poses: 472, 480, 404, 397, 403, 432, 454, 453 px. **Centralização pela cintura:** âncora nova `cintura` do `regrid_sheet.gd`, que põe o meio do maiô (o maior grupo azul-petróleo) num ponto fixo. Em (256, 280) não cabe: o quadro 2 passaria 39 px da célula, e já com o meio do desenho em 280 os quadros 1 e 2 não cabem. Usei **(256, 229)**, o único y com 12 px de margem em todos: menor margem 12 (topo do 3, base do 2), 14 (esquerda do 5). Coincide com a cintura da acrobata parada, que fica em (256, 231) na célula dela, então o recorte usa o padrão (`ground_y` 486, `center_x` 256) e o corpo não pula na troca parado → pulo. Preparação: `regrid_sheet.gd ... 4 2 cintura limpar escala=0.94 alvo_y=229`. A limpeza tirou só grupos soltos de 58 a 121 px por quadro. **Conferido:** duas pernas e dois sapatos em todos os quadros. No 6, o sapato de trás aparece atrás do da frente num tom mais escuro (oliva), que se lê como sombra; aceito. Mesma identidade nas duas filas (coque, tiara, brinco de estrela, maiô com estrela e zigue-zague), olhos abertos, nariz achado em todos (x 340–360), só o braço de trás. Fundo claro sem franja. Recortado em `core/player/characters/acrobat/jump/` (uns 720 KB) e ligado como `jump_animation` no `acrobat_rig.tscn`; o código do rig é o mesmo do A5. **Fotos de um pulo real:** parado → 1…8 → pouso → parado, cabeça do mesmo tamanho do parado, cintura sem salto, braço da pistola no ombro. **Parry no ar:** a cambalhota toca inteira por cima do pulo e, no quique, volta ao quadro de subida. Pulo curto, alto e queda da beirada usam a mesma escolha por velocidade do A5. |
| — | bateria | 03/10, depois do A6: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Mais 5 rodadas só da rede ruim: 5 de 5 ok. A falha intermitente conhecida (`right box hit by the client: bonus damage (0)`) apareceu 1 vez em 10 rodadas de rede ruim desde o A5. Não mexi em rede nem no teste para esconder; segue anotada como pendência real (olhar o tempo do acerto do cliente na caixa certa do Mágico com atraso). |
| A7 | palhaco_balao_flutua.png | **No jogo (03/10).** Recebido em 1774 × 887 com alpha 0. Original em `originais/palhaco_balao_flutua_codex_1774x887.png`. Bordas da folha vazias e quadros separados. **Medida do oval** sem contar cabelo, chapéu, nó e barbante: uma elipse ajustada à silhueta de fora, só nos pontos em que logo depois do contorno vem rosa. Duas tentativas anteriores, pela borda de dentro e por raios, mediram errado e foram descartadas; a certa foi conferida desenhando a elipse por cima. Na escala da folha (1,1545), os quadros retos 1–6 medem 282–294 px de largura (mediana 290) e 300–309 de altura: o oval veio uns 12% maior que o alvo de 260. A diferença entre quadros é de até 4%, dentro do squash pedido. **Fator único 0,90.** Ovais depois: 256–266 × 269–282 px; o 7 e o 8, inclinados, só aproximados. Âncora nova `balao` do `regrid_sheet.gd`: meio do oval em (256, 240). Preparação: `regrid_sheet.gd ... 4 2 balao limpar escala=0.90 alvo_y=240`, 0 avisos, menor margem 24 px. A limpeza tirou só grupos soltos de 43 a 108 px. **Conferido:** mesmo balão e mesmo palhaço nos 8 quadros (cartola com margarida, cabelo, nariz), caras diferentes, o 6→1 sem salto de tamanho nem de posição, o 7 e o 8 inclinados para lados opostos com o barbante ao contrário. Fundo claro e escuro sem franja. O barbante é creme com contorno escuro (mais grosso que a linha simples pedida), mas no tamanho do jogo (uns 6 px de largura) aparece bem nos dois fundos, então não precisa de correção focal. **Integração, só o desenho:** recortado em `core/player/characters/clown/balloon/` (uns 790 KB). O oval de 260 px vira 132 no jogo, o mesmo do balão desenhado por código, com a origem no meio do oval. O `CharacterRig` ganhou `balloon_animation`; o `Player` passa os quadros ao `PlayerBalloon`, que toca 1–6 a 6 quadros por segundo e mostra o 7 no extremo direito do balanço e o 8 no esquerdo (seno do balanço acima de 0,92). O balanço usa a mesma conta do `Player`: o número 1,6 virou a constante `BALLOON_SWAY_SPEED`, com o mesmo valor. A acrobata, sem folha, continua com o balão de código. Subida, balanço, área do parry, resgate, Rede de Segurança, vida e rede não mudaram. **Fotos no jogo** (modo novo `screenshots.tscn -- balao`): o balão sobe com o loop e inclina nos extremos do balanço, do mesmo tamanho do antigo. |
| — | bateria | 03/10, depois do A7: 9 testes locais com 0 falhas e 0 erros de script (o online, o de itens e o do mapa cobrem cair e reviver); online normal e rede ruim ok; mais 3 rodadas de rede ruim, 3 de 3 ok. A falha intermitente conhecida da rede ruim (`right box hit by the client: bonus damage (0)`) segue anotada: 1 em 14 rodadas desde o A5. Nada foi mudado para escondê-la. |
| A8 | palhaco_balao_vira_resgate.png | **No jogo (03/10).** Recebido em 1774 × 887 com alpha 0. Original em `originais/palhaco_balao_vira_resgate_codex_1774x887.png`. Bordas da folha vazias. A cartola do 6 fica na própria célula. **Medidas** (na escala da folha, 1,1545): o oval do 4 e do 5 mede 310 e 302 px, contra uns 290 da A7. O nariz de bola, que não muda com o ângulo da cabeça, mede 45 px no parado, 50 na A7 normalizada e, nesta folha, 33–38 px nos quadros 1–3, 55–57 nos 4–5 e 45 no 7. Os quadros 1–3 vieram pequenos demais: a cabeça tonta ficaria uns 30% menor que a cabeça do palhaço no jogo. **Escala uniforme por grupo, sem deformar nenhum quadro:** 4, 5, 7 e 8 com 0,85, que dá o oval do 4 e do 5 com 263 e 257 px, como a A7, e o rosto do estouro do mesmo tamanho do parado (nariz de uns 19 px no jogo contra 20). Os 1–3 com 1,20: a cabeça do 1 fica do tamanho da cabeça do palhaço no jogo (nariz de 20 px), e o crescimento 1→4 continua subindo (nariz de 20 → 21 → 23 → 24,6 px no jogo; o loop tem 25). **Quadro 6** (ressalva do Codex): veio menor que o 5 (nariz 39 contra 47), mas mais estreito e alto (proporção 0,945 contra 1,03). Com escala uniforme de 1,02, o rosto fica do tamanho do 5 e o oval fica com a mesma largura e uns 10% mais alto, que é o "esticado" pedido; não precisou de correção focal nem de escala não uniforme. A cartola fica perto da cabeça, como o Codex avisou; aceito. **Pivôs:** 3–6 pelo meio do oval em (256, 240), como a A7. O 6 subiu 22 px (oval em 218) para o barbante caber com 12 px de margem; a base com o nó fica quase no mesmo lugar do 5, então lê como o balão esticando para cima. O 1 e o 2 pelo nariz, no mesmo ponto do nariz do 3 (293, 264): a cabeça incha sem andar. O 7 pelo nariz em (304, 236), perto do nariz do 6. O 8 pelo meio, no meio do estouro do 7. Preparação: `regrid_sheet.gd ... 4 2 balao limpar nao_limpar=7 nao_limpar=8 escala=0.85 escala_quadro=1:1.2 escala_quadro=2:1.2 escala_quadro=3:1.2 escala_quadro=6:1.02 nariz_quadro=1:293,264 nariz_quadro=2:293,264 meio_quadro=6:252,256 nariz_quadro=7:304,236 meio_quadro=8:249,204 alvo_y=240` (opções novas: `escala_quadro`, `nariz_quadro`, `meio_quadro` e `nao_limpar`). 0 avisos. A limpeza só nos quadros 1–6 (29 a 110 px soltos), porque o confete do 7 e do 8 é feito de pedaços soltos de propósito. Fundo claro e escuro sem franja. **Integração, só o desenho:** recortado em `core/player/characters/clown/balloon/` (`turn`, uns 710 KB; o balão inteiro do palhaço fica com uns 1,6 MB), com a mesma origem e escala da A7. `CharacterRig.balloon_turn_animation`. O `PlayerBalloon` toca 1–4 uma vez ao cair (10 quadros por segundo, 0,4 s) e depois entra o loop da A7. No resgate, `pop()` cria um efeito solto no lugar do balão com 5–8 (12 quadros por segundo, uns 0,33 s, e some sozinho). O resgate, a vida, a área do parry e a rede acontecem na mesma hora de antes: o `Player` continua escondendo o balão e mostrando o personagem na hora. Corrigido um defeito de 1 quadro: o balão do loop aparecia por um instante antes da transformação. **Fotos no jogo** (`screenshots.tscn -- balao`, agora com transformação, loop e resgate): cabeça tonta → incha → balão pequeno → cheio → loop sem salto; no resgate, feliz → esticado → estouro → confete, com o palhaço já voltando. |
| — | bateria | 03/10, depois do A8: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Mais 3 rodadas de rede ruim: 2 ok e 1 com a falha conhecida (`right box hit by the client: bonus damage (0)`). Agora são 2 em 18 rodadas de rede ruim desde o A5. A falha é no dano da caixa do Mágico pelo cliente com atraso, sem relação com o desenho. Não mudei rede nem teste; segue como pendência real. |
| A9 | acrobata_balao_flutua.png | **No jogo (03/10).** Recebido em 1774 × 887 com alpha 0. Original em `originais/acrobata_balao_flutua_codex_1774x887.png`. Bordas da folha vazias. A ponta do barbante da fila de cima chega perto da divisão entre as filas, mas não foi cortada. **Oval** (âncora `balao`, conferido desenhando a elipse por cima: contorno de fora, sem coque, franja nem brincos): 282–288 × 283–291 px na escala da folha, mediana 285. Veio uns 10% maior que o alvo, apesar do pedido de cópia exata. **Fator único 0,91** (260/285, mesmo critério da A7). Ovais depois: 256–262 px; o 7, inclinado, 257 × 248. Meio em (256, 240). Preparação: `regrid_sheet.gd ... 4 2 balao limpar escala=0.91 alvo_y=240`, 0 avisos, menor margem 41 px (topo do coque) e 45 (ponta do barbante). A limpeza tirou só grupos soltos de 45 a 97 px. **Conferido:** mesma cabeça nas duas filas (coque com tiara, franja, brincos de estrela, cílios), nariz de bola do mesmo tamanho do balão do palhaço (41 px na folha, uns 21 no jogo), caras diferentes, o 6→1 sem salto, o 7 e o 8 inclinados para lados opostos com o barbante ao contrário. Fundo claro e escuro sem franja; no fundo escuro, o coque preto se separa pelo contorno. Recortado em `core/player/characters/acrobat/balloon/` (uns 740 KB), com a mesma origem e escala do balão do palhaço, e ligado como `balloon_animation` no `acrobat_rig.tscn`. Sem folha de transformação ainda (A10): ao cair, o balão aparece direto no loop; no resgate, some como antes. **Fotos no jogo** (modo novo `screenshots.tscn -- balao2`, para o 2º jogador): dá para reconhecer a acrobata no tamanho do jogo, com loop e inclinação nos extremos; o resgate continua igual. Subida, balanço, área do parry, resgate, colisões e rede sem mudança. |
| — | bateria | 03/10, depois do A9: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok; mais 3 rodadas de rede ruim, 3 de 3 ok. A falha conhecida segue com 2 em 22 rodadas desde o A5. Nada foi mudado para escondê-la. |
| A10 | acrobata_balao_vira_resgate.png | **No jogo (03/10).** Recebido em 1774 × 887 com alpha 0. Original em `originais/acrobata_balao_vira_resgate_codex_1774x887.png`. Bordas da folha vazias. O `regrid_sheet.gd` avisou "encosta na borda" no 4 e no 7; conferido com zoom no original, nada foi cortado: o barbante do 4 termina num cacho fechado bem na divisão das filas, e uma estrela do 7 passa 5 px da divisão das colunas com o contorno completo. **Medidas** (na escala da folha, 1,1545): o oval do 4 e do 5 mede 282–288 px, como a A9 antes da normalização. O nariz não serve para a cabeça da acrobata: nas folhas de balão ele foi desenhado aumentado (uns 41–48 px, contra 16 no parado), e medir por ele encolheria a cabeça do quadro 1 para menos da metade. Usei a largura do rosto (pele) na linha do nariz: 195 px no 1, o que com 0,80 dá uns 156 px na folha e uns 79 no jogo, quase a largura da cabeça dela no jogo (78). Na folha do palhaço, a cabeça do 1 também mede uns 80% do balão. **Escala uniforme por grupo, sem deformar:** 1–2 com 0,80; 3 com 0,85 (o balão parcial veio do tamanho do cheio, e assim cresce até o 4: oval de 240 → 257); 4, 5, 7 e 8 com 0,91 (oval do 4 e do 5 com 257 e 262, como a A9; rosto do 7 com uns 160 px, igual ao 1). **Quadro 6** (ressalva do Codex): veio mais estreito e só uns 3% mais alto que o 5. Com 0,97 uniforme, o oval fica com 265 × 283 contra 262 × 259 do 5: uns 10% mais alto com a mesma largura, como pedido; o rosto fica uns 5% maior, que lê como o balão inchando. Não precisou de correção focal nem de escala não uniforme. **Pivôs:** 3–6 pelo meio do oval em (256, 240); o 6 cabe com o oval em 240 (margem de 31 px). O 1 e o 2 pelo nariz, no nariz do 3 (296, 267). O 7 pelo nariz em (305, 259), a altura do rosto do 5. O 8 pelo meio, no meio do estouro do 7 (250, 212). Preparação: `regrid_sheet.gd ... 4 2 balao limpar nao_limpar=7 nao_limpar=8 escala=0.91 escala_quadro=1:0.80 escala_quadro=2:0.80 escala_quadro=3:0.85 escala_quadro=6:0.97 nariz_quadro=1:296,267 nariz_quadro=2:296,267 nariz_quadro=7:305,259 meio_quadro=8:250,212 alvo_y=240`. Só os 2 avisos de borda já conferidos. Menor margem 12 px (topo do estouro do 7). A limpeza tirou só grupos soltos de 22 a 95 px nos quadros 1–6; o confete do 7 e do 8 não foi limpo. Fundo claro e escuro sem franja. **Integração, só o desenho:** recortado em `core/player/characters/acrobat/balloon/` (`turn`, uns 760 KB; o balão inteiro da acrobata fica com uns 1,5 MB) e ligado como `balloon_turn_animation` no `acrobat_rig.tscn`; o código é o mesmo da A8 (1–4 ao cair, 5–8 num efeito solto no resgate). **Fotos no jogo** (`screenshots.tscn -- balao2`): cabeça tonta do tamanho da cabeça dela → incha → balão pequeno → cheio → loop da A9; no resgate, feliz → esticado → estouro → confete, com ela já voltando na mesma hora de antes. |
| — | bateria | 03/10, depois do A10: 9 testes locais com 0 falhas e 0 erros de script; online normal ok. Na rodada da bateria, a rede ruim teve a falha conhecida (`right box hit by the client: bonus damage (0)`); as 3 rodadas extras passaram. Agora são 3 em 26 rodadas de rede ruim desde o A5, sempre a mesma verificação (dano da caixa certa do Mágico acertada pelo cliente com atraso). Nada mudado em rede ou teste. Pendência real para o usuário decidir: investigar o tempo desse acerto com atraso. |
| A11 | palhaco_dash.png | **No jogo (03/10).** Recebido em 1774 × 887. Original em `originais/palhaco_dash_codex_1774x887.png`. Bordas da folha vazias. **Fila de baixo:** o original tinha 315 pixels com alpha 1 (nenhum maior) espalhados; na folha preparada a metade de baixo ficou com alpha 0 em todos os pixels (conferido com contagem: 0 pixels com alpha > 0). As células 5–8 saem vazias porque o `regrid_sheet.gd` zera alpha abaixo de 0,03 e só cola os quadros com desenho. **Escala:** o nariz de verdade (o vermelho mais à frente da cabeça, com o grupo ligado a ele) mede 49–51 × 43 px nos quadros 2–4 na escala da folha, contra 52 × 39 no parado e 49–53 × 36–39 no pulo. Do topo do chapéu ao nariz: 74–75 nos quadros 2–3, contra 73 no parado; o 1 (cabeça inclinada para a frente, 83) e o 4 (para trás, 61) não entram na conta. Fator 1,0, sem ajuste. **Pivô:** o meio da caixa caía na gola ou no cabelo e mudava de lugar entre quadros. O meio do tronco xadrez foi medido em cada quadro (no olho, numa prévia) e posto em (250, 330) com `meio_quadro`; conferido com uma cruz em cima: cai no tronco nos 4 quadros. Preparação: `regrid_sheet.gd ... 4 2 ar meio_quadro=1:260,257 meio_quadro=2:224,231 meio_quadro=3:224,231 meio_quadro=4:281,246`, 0 avisos, menor margem 15 px; sem `limpar`, porque não havia grupos soltos visíveis. **Conferido:** duas pernas, dois sapatos e os botões em todos, só o braço de trás, sem pistola, mesmo palhaço do parado. A freada (4) veio mais em pé que inclinada para trás; com o pé da frente deslizando e o braço para a frente, lê como freio no jogo, então foi aceita. **Integração, só o desenho:** recortado em `core/player/characters/clown/dash/` (uns 510 KB). O `FrameAnimation` ganhou `pivot` (ponto de giro no espaço do rig), e o `cut_animation_sheet.gd` o grava quando a entrada tem `"pivot"`. O `CharacterRig` ganhou `dash_animation` e `dash_length`. O quadro sai do andamento do dash: 1 até 20%, 2 até 50%, 3 até 80%, 4 depois. O tempo é contado no próprio rig enquanto `dashing` é verdade, então funciona também no jogador remoto. A prioridade ficou parry > dash > pulo > corrida > parado. O braço da pistola segue o ombro de cada quadro. Na Pirueta, os quadros 1–3 giram na direção do dash, em volta do meio do tronco; a freada não gira e fica como o "endireitar" antes do pulo. O `Player` passa a duração do dash ao rig (com a Fumaça do Mágico, 75%), pela função nova `_dash_length()`, que também é usada no próprio dash, com a mesma conta de antes. Na Fumaça o personagem fica escondido durante o dash, como antes. Duração, velocidade, invencibilidade, dano da Bala de Canhão e rede não mudaram. **Fotos no jogo** (modo novo `screenshots.tscn -- dash`, uma foto por quadro de física): corrida → arranque → velocidade → freada → corrida, sem pulo de posição. Dash da Pirueta para cima: desenho girado para cima e freada em pé no fim. |
| — | correção (A8) | Ao medir o A11 vi que o "nariz do parado" de 45 px usado na A8 era um quadrado vermelho da roupa (o detector pegava o grupo vermelho mais redondo). O nariz de verdade mede 52 × 39 px no parado, uns 23 × 17,5 px no jogo. A cabeça tonta da A8 tem nariz de 40 × 32 px, uns 20 × 16 no jogo: a cabeça do quadro 1 ficou uns 10% menor que a cabeça do palhaço no jogo, e não igual. Em frente e de lado o nariz não se compara exatamente, então a diferença é pequena. A folha aprovada não foi mexida; se o usuário quiser, basta subir o `escala_quadro` dos quadros 1–3 de 1,20 para uns 1,32 e recortar de novo. Para as próximas: nariz de lado com `sidenose.gd` (scratchpad), e de frente com o grupo mais redondo. |
| — | bateria | 03/10, depois do A11: 9 testes locais com 0 falhas e 0 erros de script (o `test_items` cobre Pirueta, Fumaça e Bala de Canhão); online normal e rede ruim ok; mais 3 rodadas de rede ruim, 3 de 3 ok. A falha conhecida segue com 3 em 30 rodadas desde o A5. Nada mudado em rede ou teste. |
| A12 | acrobata_dash.png | **No jogo (03/10).** Recebido em 1774 × 887. Original em `originais/acrobata_dash_codex_1774x887.png`. Bordas da folha vazias. **Fila de baixo:** o original tinha 156 pixels com alpha de 1 a 4; na folha preparada, 0 pixels com alpha > 0 na metade de baixo (contado). **Escala** (na escala da folha, 1,1545, contra o parado aprovado): branco do olho 45, 41 e 43 px nos quadros 1, 2 e 4, contra 40–41; largura da cabeça na linha dos olhos 161 px no 1, contra 157 (nos 2–4 a cabeça inclinada aumenta a largura e a medida não serve; no 3 os olhos estão meio fechados); nariz de lado 18–19 × 16–18 px, contra 17–18 × 14–15. Tudo indica uns 6% maior: **fator único 0,94**, o mesmo da A6, sem igualar as alturas das poses. **Pivô na cintura** (âncora `cintura`, meio do maiô): em (256, 280) o quadro 3 passaria da borda esquerda. Pela conta das margens, com y = 280 só cabem x entre 288 e 314. Usei **(300, 280)** e `center_x` 300 no recorte, para a cintura cair no mesmo x do corpo parado; conferido com uma cruz em cima nos 4 quadros. Opção nova `alvo_x` no `regrid_sheet.gd`. Preparação: `regrid_sheet.gd ... 4 2 cintura limpar escala=0.94 alvo_x=300 alvo_y=280`, 0 avisos, menor margem 26 px. A limpeza tirou só grupos soltos de 96 a 161 px. **Conferido:** duas pernas e dois sapatos em todos, só o braço de trás, sem pistola; o 2 (pernas dobradas) e o 3 (espacate) são diferentes; o 4 inclina para trás e freia. Fundo claro e escuro sem franja. **Integração, só o desenho:** recortado em `core/player/characters/acrobat/dash/` (uns 360 KB), com `pivot` (300, 280), e ligado como `dash_animation` no `acrobat_rig.tscn`; o código é o mesmo do A11. **Fotos no jogo** (modo novo `screenshots.tscn -- dash2`, que passa o controle para a 2ª jogadora): dash reto corrida → arranque → mergulho → espacate → freada → corrida, sem tranco e com a cabeça do mesmo tamanho da corrida; Pirueta para cima com os quadros 1–3 girados e a freada em pé; pistola no ombro. Duração, velocidade, Fumaça, Bala de Canhão, colisões, tiro, rede e controles sem mudança. A A8 continua como aprovada, sem a escala extra. |
| — | bateria | 03/10, depois do A12: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok; mais 3 rodadas de rede ruim, 3 de 3 ok. A falha conhecida segue com 3 em 34 rodadas desde o A5. Nada mudado em rede ou teste. |
| A13 | palhaco_abaixado.png | **Recusada para o jogo (03/10), pedido focal A13b pronto.** Recebida em 1774 × 887. Original em `originais/palhaco_abaixado_codex_1774x887.png`; o `docs/referencias/pecas/palhaco_abaixado.png` ficou com a candidata normalizada (não recortada no jogo). **O que passou:** a folha preparada (âncora `pes`, sola em 486 e meio dos pés em x 256, como o parado; `limpar` só tirou 9 a 27 px soltos) tem 0 avisos, menor margem 26 px e 0 pixels com alpha na metade de baixo (o original tinha 109 com alpha 1). Pela área do nariz (preenchido a partir do centro dele, porque nos quadros 2 e 3 o detector pegava um tufo de cabelo), a cabeça fica 4–7% menor que no parado: dentro da tolerância, fator 1,0. Alturas 304, 257, 256, 307. **O que reprovou, visto no jogo** (modo novo `screenshots.tscn -- abaixado`, que também imprime onde ficam o ombro, a mão e a boca da pistola): no jogo de hoje, abaixado, o ombro da pistola fica 64 px acima dos pés e a boca a 67 (na folha: ombro em uns (322, 343), braço e pistola para a direita nessa altura). Essa altura do tiro não pode mudar. Nos quadros 2 e 3 a cabeça mergulha até os joelhos, exatamente nessa faixa: com o braço na frente, a pistola cobre os olhos; com o braço atrás do desenho (testado), a pistola some atrás da cabeça e o tiro parece sair do rosto. Nos 1 e 4 o braço passa pela boca. Usar o ombro do desenho (nariz + deslocamento) também não serve: com a cabeça baixa, o ombro calculado ficaria perto do chão e o tiro mudaria de altura. **Conta das pontes do trem:** a ponte baixa passa a 100 px acima do teto do vagão, e a caixa abaixada tem 84. O desenho abaixado de peças de hoje já passa disso (uns 166 px no jogo), e esta folha mediria uns 115, então a altura não é o defeito principal; a nota de 240–260 px da fila era uma estimativa minha e foi trocada por medidas do jogo. **Código que ficou** (sem efeito enquanto não há folha ligada): `CharacterRig.crouch_animation` (1 descendo, 2–3 em loop, 4 levantando, prioridade parry > dash > abaixado > pulo > corrida > parado) e, quando a animação não traz ombros, a pistola usa o ombro das peças (que continuam posicionadas escondidas), mantendo o tiro onde está; entrada no `cut_animation_sheet.gd` sem `shoulder_from_nose`. O teste do braço atrás do desenho foi desfeito, e os quadros recortados para o teste foram apagados. **Pedido A13b na fila** (medidas corrigidas, veja a linha "correção (medidas da cabeça)"): cabeça em pé e do tamanho real por cima do corpo agachado, com o braço saindo da gola logo abaixo do queixo; nariz em uns (386, 283), queixo por volta de 327, altura de uns 355–375 px. |
| — | bateria | 03/10, depois do A13 (com o abaixado desenhado desligado): 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. A falha conhecida segue com 3 em 35 rodadas desde o A5. Nada mudado em rede ou teste. |
| — | correção (medidas da cabeça) | 03/10, apontada pelo Codex antes de gerar a A13b: a primeira versão do A13b e do A14 era impossível. A medida "do topo do chapéu ao nariz, uns 73 px" vinha da opção `medir` do `regrid_sheet.gd`, que pegava a primeira linha com qualquer vermelho; no palhaço essa linha é a do cabelo vermelho. Medido de novo no `palhaco_parado.png` aprovado: topo em y 52, centro do nariz (50 × 39 px) em (352, 216), ou seja, **164 px** do topo ao nariz; queixo por volta de 260; ombro da pistola em pé em (288, 276), na gola, 16 px abaixo do queixo. Acrobata: topo em y 22, nariz (16 × 14) em (315, 141), **119 px**; queixo por volta de 180; ombro em pé em (270, 196). Com a cabeça do tamanho real e acima do braço da pistola abaixado, o palhaço abaixado mede uns 355–375 px na folha (uns 165 px no jogo, o mesmo do abaixar de peças de hoje) e a acrobata uns 350–370. Os pedidos A13b e A14 foram reescritos com essas contas. **Limite real de altura:** a caixa abaixada (84 px) não depende do desenho; o limite vem da altura do tiro abaixado. As pontes do trem (100 px acima do teto do vagão) já passam por cima do chapéu desenhado hoje; deixar o personagem abaixado inteiro abaixo da ponte pediria baixar a altura do tiro abaixado, decisão de mecânica do usuário. As escalas aprovadas não mudam: na A5, na A11 e na A13 a mesma medida (até o cabelo) foi comparada dos dois lados, e a A11 e a A13 também foram conferidas pelo nariz de verdade. Só o texto do pedido A11 descrevia errado ("até o nariz"). A opção `medir` foi corrigida: agora acha o nariz de verdade (vermelho mais à frente na metade de cima, preenchido) e dá 165 px no palhaço e 120 na acrobata. |
| A13b | palhaco_abaixado_v2.png | **No jogo (03/10).** Candidata irmã entregue em 1774 × 887. Original em `originais/palhaco_abaixado_v2_codex_1774x887.png`; o `palhaco_abaixado_v2.png` entregue continua ao lado. A versão normalizada substituiu o `palhaco_abaixado.png`, que era só a normalização da A13 recusada; o original da A13 continua em `originais/`. **Preparação:** `regrid_sheet.gd ... 4 2 pes limpar medir` (sola em 486, meio dos pés em x 256), 0 avisos; a limpeza tirou só grupos soltos de 47 a 76 px; metade de baixo com 0 pixels de alpha (o original tinha 66 com alpha 1). **Medidas** (com o `medir` corrigido): alturas 383, 371, 372, 378; do topo do chapéu ao centro do nariz 153–161 px, contra 165 no parado: a cabeça é uns 3–7% menor, dentro da tolerância, fator 1,0. Desvio registrado: os quadros 1 e 4 (meio caminho) ficaram mais agachados que os 395–410 px pedidos (383 e 378). Nas fotos, em pé (435–448) → 383 → 371/372 → 378 → em pé não pula, então foi aceito. **Conferência no jogo** (`screenshots.tscn -- abaixado`): rosto livre em todos os quadros; o braço da pistola sai da frente do tronco, logo abaixo da gola, e a pistola aparece inteira; ombro (29,5; −64,3), mão (59,0; −64,3) e boca (139,0; −67,0) idênticos aos de antes da folha, então a altura do tiro não mudou. A troca em pé → descendo → loop → levantando → em pé não tem tranco. **Integração, só o desenho:** recortado em `core/player/characters/clown/crouch/` (uns 470 KB) e ligado como `crouch_animation` no `clown_rig.tscn`; a animação não traz ombros, então a pistola segue o ombro das peças. Caixa, colisões, tiro, rede e controles sem mudança. |
| — | bateria | 03/10, depois do A13b: 9 testes locais com 0 falhas e 0 erros de script (inclui o trem com as pontes); online normal e rede ruim ok na bateria. Rodadas extras: rede ruim 9 (1 em que os dois processos não se conectaram e tudo falhou por tempo; pela forma, o cliente tentou conectar antes do host abrir a porta, porque o `run_online.sh` abre os dois juntos); online normal 11 (1 com 2 falhas no host e 3 no cliente, que não se repetiu nas 6 seguintes; o log foi sobrescrito, porque o `run_online.sh` reaproveita o mesmo arquivo, então não dá para dizer quais verificações). A falha conhecida da caixa do Mágico não apareceu desta vez (segue com 3 em 44 rodadas de rede ruim desde o A5). O abaixado desenhado só muda o visual, então nada indica relação com a arte. Nada foi mudado em rede ou teste. Pendências reais do online para o usuário decidir: investigar essas falhas raras e fazer o `run_online.sh` guardar o log de cada rodada que falhar. |
| A14 | acrobata_abaixado.png | **No jogo (03/10).** Recebido em 1774 × 887. Original em `originais/acrobata_abaixado_codex_1774x887.png`; o `acrobata_abaixado.png` ficou com a versão normalizada. **Preparação:** `regrid_sheet.gd ... 4 2 pes limpar medir` (sola em 486, meio dos pés em x 256), 0 avisos; a limpeza tirou só grupos soltos de 64 a 116 px; metade de baixo com 0 pixels de alpha (o original tinha 264 com alpha 1). **Medidas:** alturas 404, 373, 365, 403 (pedido: 350–370 nos 2–3 e 400–415 nos 1 e 4); coque-nariz 126–138 contra 120 no parado, mas a cabeça inclinada muda essa distância; o branco do olho (40–44 contra 40) e o nariz (14–16 × 15) batem com o parado. Fator 1,0, como o Codex sugeriu. **Conferência no jogo** (`screenshots.tscn -- abaixado2`): nos quadros 2 e 3 o braço da pistola sai do decote, abaixo do queixo, com o rosto e a pistola livres; ombro (41,1; −92,8), mão (79,0; −92,8) e boca (153,8; −95,4) idênticos aos de antes. **Defeito achado e corrigido no código, só visual:** nos quadros de meio caminho (1 e 4) o braço cruzava o rosto. Enquanto abaixa ou levanta, o ombro das peças (e o tiro) desce aos poucos da altura em pé até a abaixada e passava pela altura do rosto desses quadros. Agora o quadro de meio caminho só entra depois de 60% do abaixar (suavizado); antes disso fica o desenho em pé, com o braço descendo pelo tronco (`CROUCH_FRAME_FROM` no `CharacterRig`). O ombro e o tiro seguem as peças o tempo todo, iguais a antes. Fotos de novo dos dois personagens: o braço não cruza o rosto em nenhum quadro, nem descendo nem levantando; o palhaço continua certo. **Integração:** recortado em `core/player/characters/acrobat/crouch/` (uns 360 KB) e ligado como `crouch_animation` no `acrobat_rig.tscn`, sem ombros, como no palhaço. Caixa, colisões, tiro, rede e controles sem mudança. |
| — | bateria | 03/10, depois do A14: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Uma rodada só, sem repetições extras, como pedido. Pendências de teste anotadas no A13b (falhas raras do online e log sobrescrito pelo `run_online.sh`) continuam abertas. |
| A15 | palhaco_dano.png | **No jogo (03/10).** Recebido em 1774 × 887. Original em `originais/palhaco_dano_codex_1774x887.png`; o `palhaco_dano.png` ficou com a versão normalizada. **Preparação:** a limpeza só tirou pontinhos quase invisíveis (alpha < 0,1), conferido com um mapa do que saiu: estrelas, gotas e chapéu solto ficam inteiros; metade de baixo com 0 pixels de alpha (o original tinha 89 com alpha 1). **Escala:** narizes 42–49 × 36–37 px, contra 50 × 39 no parado. O quadro 1 tem o nariz mais estreito (42), mas a cabeça está reclinada e virada, e o chapéu, o olho e o cabelo têm o mesmo tamanho dos outros quadros; aceito, fator 1,0. Alturas 353, 353, 376, 406, sem igualar as poses. **Pivô:** o meio do tronco xadrez, medido em cada quadro, foi alinhado em (256, 332), o mesmo ponto do tronco no pulo e no dash do palhaço (`meio_quadro=1:246,254 2:256,259 3:261,254 4:251,269`), conferido com uma cruz em cima; 0 avisos, menor margem 40 px. **Ombro da pistola:** o recorte achava o "nariz" no xadrez da perna nos quadros 1 e 2 (corpo reclinado), e a regra nariz + (−64, 60) cairia na boca e no queixo. O `cut_animation_sheet.gd` ganhou a opção `shoulders` (ombro medido à mão por quadro): 1 = (285, 312) e 2 = (262, 272), na frente da gola; 3 e 4 pela regra. **Integração, só o desenho:** recortado em `core/player/characters/clown/hurt/` (uns 420 KB). O `CharacterRig` ganhou `hurt_animation` e `play_hurt(duração)`, com quadro pelo andamento do atordoamento (0,22 s) e prioridade logo abaixo do parry. O `Player` chama `show_hurt()` no golpe, e o `PlayerHealth` também a chama quando a vida chega pela rede, para o susto aparecer no PC do parceiro. **Ajuste visual do piscar:** antes, o piscar da invencibilidade começava escondendo o personagem na hora do golpe, e o quadro do impacto quase nunca aparecia. Agora o primeiro apagar acontece depois dos 0,22 s do susto (`_start_invincibility(tempo, primeiro_apagar)`); a invencibilidade conta desde o golpe, como antes, e o Nariz de Buzina e o reviver piscam como antes. Vida, empurrão, atordoamento, colisões, tiro, rede e controles sem mudança. **Fotos no jogo** (modo novo `screenshots.tscn -- dano`, uma foto por quadro de física): impacto com estrelas → jogado para trás → susto com gotas → recompondo → piscar → pouso. Limitação aceita: no quadro 3 o braço da pistola passa rente ao queixo (dura uns 0,055 s). |
| — | bateria | 03/10, depois do A15: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Uma rodada só. |
| A16 | acrobata_dano.png | **No jogo (03/10).** Recebido em 1774 × 887. Original em `originais/acrobata_dano_codex_1774x887.png`; o `acrobata_dano.png` ficou com a versão normalizada. Metade de baixo com 0 pixels de alpha (o original tinha 673 com alpha 1); a limpeza tirou só grupos soltos, e estrelas e gotas ficaram inteiras. **Escala:** o branco do olho mede 40 px nos quadros 1 e 4, igual ao parado (40); fator 1,0. O nariz ficou desenhado menor (12–15 px contra 16), um detalhe do desenho e não da escala: no jogo dá uns 6–7 px contra 8; aceito. A estrela da cintura do 3 aparece na borda do maiô, junto da coxa, e convence. **Pivô:** a âncora `cintura` errou no 3 (com as pernas encolhidas, o maior pedaço azul-petróleo é um sapato). A estrela da cintura de cada quadro foi localizada na régua e alinhada em (256, 280) com `meio_quadro` (1:256,240 2:271,207 3:271,222 4:230,256), conferido com uma cruz em cima; 0 avisos, menor margem 27 px. Mais alto que 265 não cabia sem encolher. Para o corpo não pular na troca dano ↔ pulo (no pulo a cintura fica em 229 com o chão em 486), o recorte usa `ground_y` 537: a cintura fica à mesma distância dos pés nas duas animações. **Ombro da pistola:** nos 3 e 4 a regra nariz + (−45, 55) cai na frente do decote; nos 1 e 2, reclinados, cairia no pescoço, então foi medido à mão: (250, 235) e (250, 232), no peito. **Integração, só o desenho:** recortado em `core/player/characters/acrobat/hurt/` (uns 400 KB) e ligado como `hurt_animation` no `acrobat_rig.tscn`; o código é o mesmo do A15, com o piscar começando depois do susto. **Fotos no jogo** (`screenshots.tscn -- dano2`): impacto com estrelas → arqueada → encolhida com gotas → recompondo → piscar → pouso; pistola saindo do peito. O topo da cabeça sai cortado nas fotos porque a caixa de recorte das fotos é menor que ela (o mesmo acontece em pé); não é defeito do jogo. Limitação aceita: no 3, o braço passa rente ao queixo, como no palhaço. Vida, empurrão, atordoamento, colisões, tiro, rede e controles sem mudança. Com isso, os blocos A1–A16 (jogadores) estão todos no jogo. |
| — | bateria | 03/10, depois do A16: 9 testes locais com 0 falhas e 0 erros de script; online normal e rede ruim ok. Uma rodada só. |
| B1 | leao/leao_salto.png | **Recusada para o jogo (03/10), pedido focal B1b pronto.** Recebida em 1254 × 1254 (não 2048 × 2048), 2 × 4. Original em `docs/referencias/pecas/leao/originais/leao_salto_codex_1254x1254.png`; o `leao_salto.png` entregue ficou como candidata, sem recorte nem ligação no jogo (depois substituído pela B1b aprovada). **Preparação de conferência:** o `regrid_sheet.gd` ganhou a opção `celula=LxA` (células de 1024 × 512 do leão); refeito o A1 com a ferramenta nova: 0 pixels diferentes do aprovado. Ampliada por 1,6332 até 2048 de largura; a limpeza tirou 54 a 286 px soltos por quadro (os 20 296 pixels com alpha 1 somem no corte de alpha < 0,03). Anatomia e expressões boas (quatro patas, uma cauda, juba, olhando para a esquerda). **O que reprovou:** a cabeça muda de tamanho entre os quadros. Nariz (marrom-escuro encostado no focinho creme, medido do mesmo jeito nas folhas aprovadas, que dão 31–34 × 23–27 px em todos os quadros do parado, do pulo e da corrida), na escala 2048: quadro 2 = 30 × 24 (como o aprovado), quadro 1 = 26 × 20, quadros 4, 5 e 7 = 21–23 × 16–18. A diferença entre o 2 e o 4/5/7 é de uns 35%, visível lado a lado. Com um fator único: para os 4/5/7 ficarem do tamanho certo (× 1,45), o 2 ficaria 45% maior que o aprovado e o voo do 4 passaria de 900 px; com o fator sugerido de 1,25–1,30, o 2 fica uns 20–25% grande e os 4/5/7 uns 15–20% pequenos. A proporção cabeça/corpo também mudou: o voo do 4 mede 626 px com nariz de 21 (corpo/nariz 30), contra 825 com nariz 31 no aprovado (27). Escala diferente por quadro deformaria o corpo e não foi usada. **Pedido B1b na fila:** cada quadro do mesmo tamanho dos quadros aprovados de `leao_pulo.png` (agachado 654 × 312, decolagem 747 × 431, voo 825 × 289, pouso 725 × 324) e nariz de 32 × 25 em todos, com as medidas também na escala de 1254 em que o gerador entrega. |
| B1b | leao/leao_salto_v2.png (no jogo como leao/leao_salto.png) | **No jogo (03/10).** Recebida em 1254 × 1254, 2 × 4; original guardado em `docs/referencias/pecas/leao/originais/leao_salto_v2_codex_1254x1254.png` (e a B1 recusada em `leao_salto_codex_1254x1254.png`). Ampliada por 1,6332 até 2048 (fator único; na escala 2048 é fator 1,0), limpeza de 92 a 288 px soltos por quadro, os 19 424 pixels com alpha 1 somem no corte de alpha < 0,03; fundo limpo no creme e no escuro. **Cabeça:** nariz medido com o `seedcolor.gd` corrigido (origem fixa; o bug apontado pelo Codex: a busca de ±30 px andava com o ponto) e conferido à mão, 34 × 24, 35 × 29, 31 × 19, 30 × 20, 31 × 21, 32 × 22, 32 × 24 e 32 × 24 nos quadros 1–8, contra 31–34 × 23–27 nas folhas aprovadas (os quadros 3–5 mais baixos porque a cabeça está deitada no voo; a largura bate). Cabeças lado a lado com o parado e o voo aprovado: mesmo tamanho de olho, focinho e juba. Corpo/nariz no voo: 772/30 e 784/31 (25–26), como o aprovado (825/31 = 27). **Desvios aceitos:** voo 4/5 com 772–784 de largura contra 825 (6% mais curto, desenho mais compacto, não esticado); pouso 8 com 621 × 337 contra 725 × 324; agachado 622 × 303 contra 654 × 312. **Alinhamento** (`regrid_sheet.gd` com `celula=1024x512` e `meio_quadro` por quadro, sem escala própria): quadros 1 e 8 com a sola em y 482 e o meio da caixa em x 506; quadros 2–7 com o tronco (média dos pixels dourados à direita da juba, `torso.gd` no scratchpad) em (649, 324), o mesmo ponto medido do mesmo jeito no voo do antigo `leao_pulo.png` (o "590, 335" do pedido era o mesmo ponto estimado a olho). Exceção: o quadro 6 ficou com o tronco 19 px mais alto, senão as patas passariam da margem de 12 px embaixo. Margens: 17 px em cima no quadro 2, 14 px embaixo no 6, as outras maiores. **No jogo:** `cut_animation_sheet.gd` com a entrada do leão trocada para `leao_salto.png` (8 quadros, mesmas células e escala do pulo antigo); `lion.gd`: agachado e deitado = 1, saída = 2 nos primeiros 0,12 s, subindo = 3, no alto = 4 e depois de 0,1 s o 5, descendo = 6 e depois de 0,1 s o 7, pouso = 8 (pela direção do voo, como antes; trajetória, tempo, colisão e rede iguais). As chamas da fase 3 agora ficam no meio da juba de cada quadro do salto (`LEAP_MANE`, medido na folha) e mudam de lugar junto com o quadro (antes, no voo, ficavam à frente da cabeça). Fotos com `screenshots.tscn -- leao` (agachado, arco inteiro e pouso, com e sem fogo). Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. O `leao_pulo.png` continua guardado na pasta. |
| B2 | leao/leao_fogo_parado.png | **No jogo (03/10).** Recebida em 1774 × 887 (não 2048 × 1024), 2 × 2; original em `docs/referencias/pecas/leao/originais/leao_fogo_parado_codex_1774x887.png`. Ampliada por 1,1545 até 2048; limpeza de 70 a 204 px soltos por quadro (os 8 660 pixels com alpha 1 somem no corte); fundo limpo no creme e no escuro. Quatro patas, uma cauda, juba de chamas presa à cabeça, chamas e caras diferentes nos 4 quadros. **Tamanho:** o gerador redesenhou o corpo uns 9% maior que o parado aprovado (patas de ponta a ponta 516–521 px contra 468–475; dorso a 228 px da sola contra 209–216; a cabeça na mesma proporção). Corrigido com um fator único de 0,92 na folha inteira (nada de escala por quadro): patas 475–480, dorso 209–210, caixa 512–523 × 381–401 (o parado: 513–556 × 387–396). Nariz (região marrom-avermelhada a partir de um ponto fixo, `darknose.gd` no scratchpad, porque o nariz desta folha tem degradê e o preenchimento por cor parava no meio): 33 × 25, 35 × 26, 30 × 22 e 34 × 25, contra 31–32 × 24–25 no parado medido do mesmo jeito. **Alinhamento:** sola em y 482 e o meio das patas em x 529 (o mesmo do parado; a caixa inteira não serve porque as chamas vão mais para a esquerda), por `meio_quadro`. **No jogo:** entrada `fire_idle` no `cut_animation_sheet.gd`; no `lion.gd`, parado com `on_fire` usa `FIRE_IDLE_ANIM` e esconde as chamas soltas (`fire_mane`), para não ter fogo em dobro; nas outras poses as chamas soltas continuam até chegarem as folhas delas. O tom alaranjado da fase 3 continua por código. Fotos com `screenshots.tscn -- leao_fogo` (6 quadros do parado normal e 10 em fogo, a cada 0,1 s): troca sem salto, patas na mesma linha, mesmo tamanho. Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| B3 | leao/leao_fogo_corrida.png | **No jogo (03/10).** Recebida em 1254 × 1254 (não 2048 × 2048), 2 × 4; original em `docs/referencias/pecas/leao/originais/leao_fogo_corrida_codex_1254x1254.png`. Ampliada por 1,6332 até 2048; limpeza de 185 a 384 px soltos por quadro (os 18 404 pixels com alpha 1 somem no corte); fundo limpo no creme e no escuro. Oito poses do galope iguais às do `leao_corrida.png`, quatro patas e uma cauda em todas, juba de fogo inclinada para trás, caras bravas variadas; o loop 8 → 1 fecha como na corrida aprovada. **Tamanho:** de novo uns 10% grande (vão das patas 2–15% maior por quadro, mediana 12%; nariz 33–38 contra 30–33 no aprovado, medidos do mesmo jeito com o `darknose.gd`). Corrigido com fator único 0,91 na folha inteira: vão das patas 288–672 contra 282–667 (média +2%), caixas 606–709 × 267–337 contra 645–705 × 283–347, nariz 30–34 × 21–26 contra 30–33 × 24–25. A cabeça do fogo fica até 20 px mais à esquerda que a da corrida normal nos quadros 5 e 7 (dentro do ciclo de fogo é coerente). **Alinhamento:** solas em y 481 nos quadros 1, 2, 4, 5, 7 e 8 (482 no 4, como no aprovado) e no ar nos quadros 3 e 6 (453 e 446, as mesmas alturas da corrida aprovada), caixa centrada em x 512 como a corrida aprovada (511–512), por `meio_quadro`, sem plantar todos no chão. **Manchas marrons sob o peito** (quadros 1, 5 e 8): é o resto da juba de pelo do lado de lá, por trás das patas da frente, como na corrida aprovada; no tamanho do jogo lê como sombra, e o B2 aprovado tem o mesmo. Aceito; o pedido B4 pede para a juba de fogo cobrir também essa parte. **No jogo:** entrada `fire_run` no `cut_animation_sheet.gd`; no `lion.gd`, correndo com `on_fire` usa `FIRE_RUN_ANIM` (14 quadros por segundo, como a corrida) e esconde as chamas soltas; salto, rugido e agachado continuam com as chamas soltas. Fotos com `screenshots.tscn -- leao_fogo` (segunda fila: parado em fogo, correndo a 1/14 s e parando): troca sem salto nas duas direções. Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| B4 | leao/leao_fogo_salto.png | **No jogo (03/10).** Recebida em 1254 × 1254 (não 2048 × 2048), 2 × 4; original em `docs/referencias/pecas/leao/originais/leao_fogo_salto_codex_1254x1254.png`. Ampliada por 1,6332 até 2048; limpeza habitual (os 16 209 pixels com alpha 1 somem no corte); fundo limpo no creme e no escuro. Oito poses do `leao_salto.png`, quatro patas e uma cauda em todas, fogo cobrindo também a parte sob o queixo e atrás das patas da frente (sem resto de juba de pelo), chamas para trás, caras bravas diferentes. **Tamanho certo desta vez, fator 1,0:** vão das patas por quadro 0–4% do aprovado (563/555, 124/120, 162/163, 579/560, 608/623, 565/555, 600/586); a silhueta do corpo sem a cabeça (x > 520 da célula) sobrepõe a do salto aprovado em 96–99% depois de alinhada (`register.gd` no scratchpad); nariz (`darknose.gd`) 31–38 × 20–25 contra 31–34 × 22–26 (o 7 com 38 × 24 contra 34 × 26: a mesma área, só mais largo; cabeça do 7 conferida lado a lado, mesmo rosto, mais bravo). **Alinhamento:** quadros 1 e 8 com a sola em 481; quadros 2 a 7 no ar, cada um posto onde a silhueta do corpo mais sobrepõe a do mesmo quadro do salto aprovado (o tronco pela cor não serve aqui, porque o amarelo das chamas é parecido com o dourado do corpo). **Desvios aceitos:** no quadro 2 as chamas sobem uns 25 px acima da juba de pelo; no lugar exato do aprovado passariam do topo da célula, então o 2 ficou 12–15 px mais baixo que o salto normal (sem cortar nada; margem de cima 14 px; é o quadro da saída, 0,12 s); o 6 ficou 8 px mais alto para as patas terem a margem de 12 px embaixo. **No jogo:** entrada `fire_leap` no `cut_animation_sheet.gd`; no `lion.gd`, agachado, no ar e pouso com `on_fire` usam `FIRE_LEAP_ANIM` (mesma escolha de quadros de `_leap_frame`); as chamas soltas só aparecem nas poses sem folha de fogo (`FIRE_DRAWN`), hoje só o rugido e a preparação dele. Fotos com `screenshots.tscn -- leao` (segunda fila: o arco inteiro em fogo, sem chamas soltas). Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| B5 | leao/leao_derrota.png | **No jogo (03/10).** Recebida em 1774 × 887 (não 2048 × 1024), 2 × 2; original em `docs/referencias/pecas/leao/originais/leao_derrota_codex_1774x887.png`. Ampliada por 1,1545 até 2048; limpeza habitual (os 6 939 pixels com alpha 1 somem no corte); fundo limpo no creme e no escuro. Quatro quadros com juba de pelo: cansado de língua de fora, deitando com bocejo, deitado de língua de fora com olhos semicerrados, dormindo (mesmo rosto, mesma pose do 3); quatro patas e uma cauda; cauda do 3 curvada junto às patas de trás (aceita). **Tamanho:** no quadro 1 o nariz bate com o parado (33 × 27, área igual, `darknose.gd`) e o corpo veio uns 4% maior (patas e dorso); nos deitados o nariz veio uns 10% maior (37–39 × 27–29). Fator único 0,95 na folha inteira: corpo do 1 a +1%, nariz do 1 uns 5% menor e dos deitados uns 4% maior que o parado (35–36 × 26–28), dentro da variação das folhas aprovadas; nada por quadro. **Alinhamento** (sem reduzir os deitados): ponto mais baixo dos 4 em y 482; quadro 1 com a pata da frente onde fica a do parado (x uns 292), para a cabeça não pular na troca; quadros 2–4 com a caixa centrada em x 512; o 4 movido 9 px para o nariz cair no mesmo lugar do 3 (troca 3 → 4 sem salto). **No jogo:** entrada `defeat` no `cut_animation_sheet.gd`; no `lion.gd`, `lie_down()` apaga o fogo e toca `DEFEAT_ANIM` uma vez (`DEFEAT_TIMES`: 0,35 / 0,35 / 0,8 s e depois dormindo), com a respiração do parado enquanto dorme; o achatado por código (1,05 × 0,8 no quadro do agachado) saiu. O agachado do salto continua só para o agachado. Fotos com `screenshots.tscn -- leao_derrota` (parado em fogo, `lie_down()`, foto a cada 0,15 s): fogo apaga, cansado, deita, língua de fora, dorme respirando, chão constante. Limitação antiga, não mexida: se a luta acabar com o leão no ar, ele deita onde estiver (a posição é dos ataques). Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. **Pendência real (fora do plano, não pedida):** o rugido em fogo. Na fase 3 o leão ruge em fogo nas Argolas Caindo (`falling_rings.gd`, enquanto avisa as ondas) e na entrada do fogo (`intro_fire.gd`), e o rugido ainda é o `leao_rugido.png` de pelo com as chamas soltas por código; o Pedido 3 de `codex_leao.md` só tinha parado, corrida e salto em fogo. Atualização de 03/10: decidido por delegação, o B6 `leao_fogo_rugido.png` entrou na fila (pedido pronto). |
| C1 | domador/domador_folha.png | **Aprovada como folha base (03/10)**; não entra no jogo (o Domador do jogo continua o SVG até o C2). Recebida em 1774 × 887 (não 2048 × 1024), com a primeira cabeça passando para a metade esquerda; original em `docs/referencias/pecas/domador/originais/domador_folha_codex_1774x887.png`. **Desenho:** corpo inteiro olhando para a esquerda, punho da frente vazio (luva branca), mão de trás no quadril, cartola preta de faixa vermelha, nariz de bola vermelho, bigodão enrolado, cabelo castanho, casaca vermelha com três botões e alamares dourados, uma dragona, cinto preto de fivela dourada, calça creme, botas pretas de friso dourado, aba da casaca para trás; três cabeças (convencido, bravo, apavorado com a cartola pulando e gotas de suor), o mesmo rosto. Botões e alamares invertidos em relação ao SVG: aceito, o desenho novo é o canônico. **Proporções** (contra o SVG, 19% / 25% / 31%): cartola uns 21% da altura, da aba ao queixo uns 24%, pernas (do cinto à sola) uns 33%; baixinho e troncudo como pedido. **Medidas:** nariz de bola do corpo 55 × 51 px na folha recebida, das cabeças 52–53 × 47–49 (uns 5% menores). **Reorganizada em 2048 × 1024** (`compose_folha.gd` no scratchpad, sem deformar nada): corpo ampliado pelo fator único 2048/1774 (930 px de altura, de y 54 a 984, x 54 a 682; acima dos 880 pedidos, aceito porque é só a folha de design); cada cabeça pelo mesmo fator × 1,05, uniforme, para o nariz ficar do tamanho do nariz do corpo (agora 63–65 × 57–59 nas três e 64 × 59 no corpo); as três lado a lado à direita do corpo (x 722, 1166 e 1612, centradas em y 450, 34 px entre elas, 32 px da borda); alpha < 0,03 zerado; limpo no escuro. |
| C2 | domador/domador_chicote.png | **No jogo (03/10).** Recebida em 2048 × 768 (não 2048 × 512): quatro colunas de 512 × 768 com as solas em 534; original em `docs/referencias/pecas/domador/originais/domador_chicote_codex_2048x768.png`. Fator 1,0 (sem ampliar nem escalar por quadro; altura 463 px nos quadros em pé, 412 no estalo pela pose); limpeza habitual. **Desenho:** os quatro olhando para a esquerda, mesmo personagem da `domador_folha.png` (três botões e alamares em todos), dois braços, duas pernas e botas, punho da frente vazio e visível, mão de trás no quadril, sem chicote; pronto convencido, punho ao lado da cartola gritando, estalo com o punho na altura do joelho, orgulhoso depois. Nariz de bola (`rednose.gd`) 33 × 29, 34 × 30, 34 × 28 e 33 × 31 contra 32 × 30 pedidos. Limpo no escuro. **Alinhamento** (`regrid_sheet.gd` com a célula de 512 e `meio_quadro`): solas em y 486 (as 534 sobem 48 px) e a fivela do cinto (`buckle.gd`) em x 255–260 nos 4. **No jogo:** entrada `whip` no `cut_animation_sheet.gd` (`center_x` 256, `ground_y` 486, `cell_height` 465, `rig_height` 260); no `tamer_boss.tscn` o `Body` virou `Node2D` com um `Frames` (Sprite2D) dentro, no lugar do SVG (o `tamer.svg` continua na pasta); no `tamer.gd`, `_show_frame` escolhe o quadro pela `whip_pose` (abaixo de 0,35 pronto, até 1,5 erguido, depois estalo; ao voltar do estalo, 0,35 s do "depois do estalo") e põe a `Hand` (começo do chicote, e de onde sai a tocha da fase 3) no meio da luva da frente de cada quadro (`HANDS`, medido com `glove.gd`). O chicote, a vida, a colisão e o tempo dos ataques não mudaram. Encolhido de medo (fases 2 e 3) e a reverência continuam por código sobre o quadro "pronto" até chegarem C3 e C4. Fotos com `screenshots.tscn -- domador` (a pose do chicote de 0 a 2 e de volta, a cada 0,1 s). Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| C3 | domador/domador_medo.png | **No jogo (03/10).** Recebida em 2048 × 768 (não 2048 × 512), colunas de 512 × 768, solas em 626, desenhos uns 25% grandes (a correção da cartola pulando aumentou tudo); original em `docs/referencias/pecas/domador/originais/domador_medo_codex_2048x768.png`. **Fator único 0,80** na folha inteira (proposta do Codex, conferida): nariz de bola 33 × 25 e 34 × 30 (`rednose.gd`; nos quadros 2 e 4 o nariz fica atrás do bigode e a medida não pega) contra 33–34 × 28–31 no C2; cartola, cabeça e botas do mesmo tamanho do C2 lado a lado. Encolhido: 370–371 px nos quadros 1, 2 e 4 e 401 no 3 com a cartola pulando (uns 31 px acima, mais que os 10 pedidos; aceito: corpo e rosto ficam na mesma altura, só a cartola e a mão de trás sobem, e no tremor lê como a cartola pulando de susto). Desenho: olhando para a esquerda, dois braços, duas pernas e botas, punho da frente vazio no peito, mão de trás na aba da cartola, sem chicote, três alamares; dentes batendo, olhar de lado com o bigode caído, boca em "O" com a cartola no ar, espiando com um olho. Limpo no escuro. **Alinhamento:** solas em 486; as botas já estavam no mesmo lugar nos 4 (caixa de x 112–114 a 397–400), então ficaram paradas (bom para o tremor) e a fivela cai em x 252–263 (o C2 tem 256). **No jogo:** entrada `fear` no `cut_animation_sheet.gd` (mesmos números do `whip`); no `tamer.gd`, com `cowering` mostra os quadros 1–3 a 12 por segundo e, a cada 2,4 s, o 4 por 0,5 s (`FEAR_FPS`, `PEEK_EVERY`, `PEEK_TIME`); a mão (o chicote pendurado) segue o punho de cada quadro (`FEAR_HANDS`); o achatado, a inclinação e o tremor grande por código saíram (fica um tremidinho de 1,5 px). Vida, colisão (ele não leva tiro com medo, como antes), tempos, tocha e chicote não mudaram. Fotos com `screenshots.tscn -- domador` (segunda fila: medo a cada 0,17 s, uma espiada e de pé de novo). Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| C4 | domador/domador_reverencia.png | **Recusada para o jogo (03/10), pedido focal C4b pronto** (depois aprovada a C4b, abaixo; os quadros 1 e 2 desta entram na folha final). Recebida em 2048 × 768 (colunas de 512 × 768, solas em 652); original em `docs/referencias/pecas/domador/originais/domador_reverencia_codex_2048x768.png`. **O que está bom:** olhando para a esquerda, dois braços e duas botas, punho da frente vazio na barriga, sem chicote, três alamares, cabelo encaracolado como no C3, cartola inteira na mão de trás; as quatro caras; fundo limpo; quadros 1 e 2 do tamanho do C2 (nariz 33 × 23 parcial pelo brilho, uns 34 × 30 à vista, e 34 × 30; rosto do nariz à orelha uns 150–155 px, como o C2). Aceitáveis: a cartola segura atrás, à direita (reverência de mestre de cerimônias), e os quadros 3 e 4 mais baixos que 330 (294 e 304: reverência funda). **O que reprovou:** a cabeça encolhe nos quadros 3 e 4: nariz 28 × 29 e 29 × 28 (`rednose.gd`) contra 33–35, rosto do nariz à orelha uns 130 px contra 150–155, o olho aberto do 4 menor que o do 1; uns 13–16% menor, e o 4 é o quadro que fica parado na tela até a vitória. Fator único não resolve (os quadros 1 e 2 já estão certos) e escala por quadro não foi usada. **Pedido C4b na fila:** irmã `domador_reverencia_v2.png`, refazendo só a cabeça (com o cabelo) dos quadros 3 e 4 no tamanho da cabeça dos quadros 1 e 2, sem mexer no corpo, botas, cartola e posições. |
| C4b | domador/domador_reverencia_v2.png (no jogo como domador/domador_reverencia.png) | **No jogo (03/10).** Recebida em 2048 × 768 (colunas de 512 × 768, solas em 654–655); original em `docs/referencias/pecas/domador/originais/domador_reverencia_v2_codex_2048x768.png`. O gerador não preservou os pixels fora das cabeças (traço e posição mudaram um pouco nos 4 quadros), então a folha montada usa os quadros 1 e 2 da C4 original e os quadros 3 e 4 da C4b (`merge_cols.gd` no scratchpad). **Cabeças:** nariz pelo critério mais largo do Codex (R > 0,39, R > 1,4 G, R > 1,5 B; `rednose2.gd`), medido igual nos quatro: 33 × 30, 34 × 30, 31 × 29 e 33 × 31; rosto, cabelo e olho do 4 do tamanho do quadro 1 e do C2 lado a lado; o 3 olha para baixo (nariz 6–9% menor pelo ângulo, cabelo e rosto do tamanho certo): aceito. Corpo e botas dos quadros 3 e 4 com mudanças pequenas de traço, coerentes com os quadros 1 e 2. Fator 1,0, sem escala por quadro. **Registro pelas botas** (`boots.gd`: as 20 linhas de baixo): solas em 486 e o meio das botas em x 245 nos 4 (antes 239, 224, 245 e 245; a caixa não serve por causa da cartola esticada para a direita). No jogo as botas da reverência e do medo ficam no mesmo lugar das botas do quadro "pronto" do chicote pelo `center_x` do recorte (199 na reverência, 211 no medo, 256 no chicote; meio das botas em x 245, 257 e 302 das células), sem mexer nos pixels: o medo do C3 passou de `center_x` 256 para 211 (o desenho do medo fica 26 px mais à direita no jogo, com as botas onde ficam em pé), e os pontos da mão foram refeitos. **No jogo:** entrada `bow`; no `tamer.gd`, com `bow` > 0 mostra a reverência pelo `bow` (quadro 2 a partir de 0,25, 3 a partir de 0,6, 4 a partir de 0,95, e o 4 fica), com o chicote saindo da luva (`BOW_HANDS`); a inclinação por código saiu. Fotos com `screenshots.tscn -- domador` (terceira fila): botas paradas do "pronto" até a reverência, e do medo até ficar de pé. Bateria: 9 testes locais com 0 falhas, online normal ok; **online com rede ruim falhou uma vez** (host e cliente: `wrong box opened on this PC` e `right box hit by the client: bonus damage (0)`; cliente: `purchase in the save on this PC`; no log do host, um RPC chegou antes da cena do Mágico existir: `Node not found: "MagicianFight/PlayerSpawner"`). É a mesma família da falha intermitente já conhecida (caixas do Mágico com rede ruim), num trecho que esta mudança não toca; como apareceram duas linhas novas, rodei só o online com rede ruim de novo: 0 falhas. Logs da falha guardados em `scratchpad/online_fail_c4/`. Nada foi mexido na rede nem no teste. |
| D1 | palhaco_torta.png | **No jogo (03/10).** Recebida em 1774 × 887 (4 × 2 de 443,5); original em `docs/referencias/pecas/originais/palhaco_torta_codex_1774x887.png`. Oito quadros olhando para a direita, o mesmo palhaço do parado e da corrida (xadrez, gola, cabelo vermelho, cartola com margarida, dois botões dourados), dois braços e luvas, sem pistola; a torta (forma de alumínio, crosta, creme e cereja) nas mãos nos quadros 1–4 e mãos vazias nos 5–8; limpa no creme e no escuro. **Tamanho:** a cabeça veio do tamanho certo (nariz 50–53 × 38–40 na ampliação até 2048, contra 52 × 39 no parado, mesmo critério), mas o corpo uns 6% mais alto (quadro 8 com 462 px) e os sapatos uns 12% mais largos (vão 291–317 contra 274). Fator único 0,961 na folha inteira (o 1,11 proposto pelo Codex sobre a folha recebida): cabeça uns 4% menor que a do parado, altura do quadro 8 em 444 (dentro dos 435–448 combinados), sapatos uns 8% maiores; sem escala por quadro. **Alinhamento pelos sapatos** (`boots4.gd`: as 20 linhas de baixo): solas em 486 e o meio dos sapatos em x 260 nos 8 (como o parado; antes variava de 219 a 284), para ele não deslizar; margens de 9 a 56 px (quadro 4 com 21 px à direita). **Desvios aceitos:** o arremesso (4) é a torta à frente na altura do peito, sem o braço chicoteando; o 3 inclina pouco para trás; o sorriso do 1 e a piscada do 8 são discretos. No jogo, com a torta saindo da mão no quadro 4, o gesto lê como arremesso. **No jogo:** entrada `pie_throw` no `cut_animation_sheet.gd` (`core/player/characters/clown/special/`); `special_animation` novo no `CharacterRig` (prioridade logo depois do parry; esconde o braço e a mão da pistola, como o parry); o `GrandNumber` ganhou `drawn_frame(count)` (padrão: pelo tempo) e o `PlayerSpecial.drawn_frame`; o `Player` avisa `rig.special_frame` antes de montar a pose (local e remoto). Na Torta na Cara (`pie_throw.gd`): quadros 1–3 até soltar a torta (0,38 s), 4 logo depois e 5–8 até o fim (0,75 s); com a folha desenhada a torta solta na mão não aparece e a torta voando sai do meio da torta desenhada no quadro 4 (`DRAWN_RELEASE`, (82, −105) no espaço do desenho). Duração, invencibilidade, dano, colisão, mira e rede iguais; a direção da torta continua a da mira (o desenho arremessa para a frente). Fotos com `screenshots.tscn -- torta` (cópia só visual, no chão e em cima do pedestal). **Observação para o usuário:** a torta voando (o SVG do jogo, 171 × 117 na tela) é umas três vezes maior que a torta na mão do desenho; a área de dano (raio 78) combina com a torta grande. O D2 desenha a torta voando nesse tamanho; se preferir a torta do tamanho da mão, é uma decisão de jogo. Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| D2 | torta.png | **No jogo (03/10).** Recebida em 1774 × 887 (4 × 2 de 443,5); original em `docs/referencias/pecas/originais/torta_codex_1774x887.png`. A mesma torta do D1 (forma de alumínio canelada, crosta, creme, cereja); 1–4 inteira balançando (o 3 inclina um pouco mais que 8°), 5 impacto com a cereja solta, 6 estouro com a forma recuando, 7 creme escorrendo e a forma caindo, 8 os últimos pingos; sem personagens nem parede; limpeza habitual (88 a 506 px soltos por quadro); limpa no claro e no escuro. **Tamanho:** ampliada até 2048 vinha uns 5–9% maior que os 380 × 260 pedidos; fator único 0,935: torta de 372–387 × 260–261 nos 4 quadros do voo, estouro do 6 com 406 px; no jogo a torta em pé (386 px) vira 171 px, o mesmo tamanho da torta de antes na tela (o SVG a 0,9); sem escala por quadro. **Registro:** voo pelo centro do desenho (centroide do alpha) em (256, 256) nos 4 (o 3, que vinha 15 px mais baixo, e o 1 inclinados ficam no mesmo centro, sem salto no loop 4 → 1); esborrachar pelo núcleo do creme (centroide dos pixels marfim, sem a forma nem as gotas soltas pesarem como a caixa) em (256, 256) nos 4, com a forma recuando para a esquerda em volta; nada cortado nem deformado. **No jogo:** `cut_animation_sheet.gd` ganhou a opção `first` (recortar a partir de um quadro); entradas `pie_fly` (1–4) e `pie_splat` (5–8) em `core/player/characters/clown/grand_number/`; componentes novos `FrameLoopSprite` (`components/fx/frame_loop_sprite.gd`, loop a 12 por segundo, a origem no ponto do nó) e `FrameBurst` (`components/fx/frame_burst.gd`, toca uma vez a 14 por segundo e some; virado para a esquerda ele espelha em vez de ficar de cabeça para baixo); `pie.tscn`: o `Sprite` toca a torta voando, o balanço por código (`wobble`) foi zerado porque o desenho já balança; `pie_splat.tscn` (esborrachar desenhado + as gotas de creme de antes) no fim da torta e no PRIMEIRO acerto (`first_hit_effect`, export novo e opcional do `PiercingProjectile`; os acertos seguintes continuam só com as gotas). Motivo do primeiro acerto: jogada para a frente, a torta acaba fora da tela (passa da borda da arena), então o efeito do fim quase nunca aparece; no primeiro acerto ele cai na cara do chefão, e a torta segue afundando e acertando como antes. Área de dano, vários acertos atravessando, desaceleração, mira, duração e rede iguais; o tamanho na tela não mudou. Fotos com `screenshots.tscn -- torta_voo` (a tela inteira a cada 0,08 s; o voo e o esborrachar na cara do Domador) e um teste à parte do efeito para os dois lados. Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| D3 | acrobata_salto_mortal.png | **No jogo (03/10).** Acabamento depois (pedido do Codex): `offsets` por quadro no recorte para o 7 não saltar (21 px no rig), e a pose final do número ("ta-dá") aparece por 0,35 s quando ela fica parada no chão logo depois (`play_special_ending`, só desenho; ver "Acabamento do D3" na fila); capturas `-- salto_mortal` (pedestal) e `-- salto_mortal2` (chão); bateria depois: 9 locais com 0 falhas, online normal e rede ruim ok. Recebida em 1774 × 887 (4 × 2 de 443,5); original em `docs/referencias/pecas/originais/acrobata_salto_mortal_codex_1774x887.png`. Oito poses: agachada, saída, encolhida a 90° (cabeça para a frente e para baixo), de cabeça para baixo, encolhida a 270°, preparando o chute, o chute com estrelas, pouso; dois braços, sem pistola; a volta lê como uma cambalhota para a frente; limpeza habitual; limpa no escuro. **Tamanho:** fator único (a ampliação até 2048, 1,1545); cabeças lado a lado com o nariz alinhado (parado, pulo e os quadros 1, 2 e 8): coque, olho e rosto do mesmo tamanho. Corpo mais compacto que o do parado (pernas mais grossas), como o parry aprovado; aceito, porque as poses são encolhidas e passam rápido. Desvios aceitos: espacate do 4 com joelhos dobrados; braços do 8 com cotovelos dobrados. **Registro:** quadros 1 e 8 com a sola em 486 e os pés em x 256; quadros 2–7 com o meio do tronco em (256, 250) (pelo maiô, `leotard.gd`, onde ele aparece inteiro, e à mão nos encolhidos, onde o maiô some atrás das pernas); o 7 ficou 37 px à esquerda para o pé do chute caber. **No jogo:** entrada `somersault` no `cut_animation_sheet.gd` (`core/player/characters/acrobat/special/`); `special_animation` no `acrobat_rig.tscn`; `somersault.gd`: `drawn_frame` (agachada nos 0,12 s; a volta 2–7 até 60% do arco, mais rápida no meio; o chute segura até 88%; o pouso no fim) e `spin()` zerado com a folha (o giro de duas voltas por código saiu). Arco, dano, invencibilidade, tiro e rede iguais. **Em movimento** (`--fixed-fps 60 res://tests/screenshots.tscn -- salto_mortal`, uma foto por quadro de física e `salto_mortal.csv`): agachada 8 quadros, saída 7, a volta 3 quadros por pose, o chute 14; ela pousou no pedestal do meio aos 0,68 s e o número acabou no chute (pousando num pedestal o pouso desenhado não aparece; no chão ele aparece nos últimos 12% do arco); depois correu e parou sem salto. Bateria: 9 testes locais com 0 falhas, online normal e com rede ruim ok. |
| D4 | acrobata_chute_torta.png | **Recusada para o jogo (03/10), pedido focal D4b pronto.** **Depois: D4b no jogo** (ver "Resultado do D4b" na fila: nariz 16–17 × 17–18 nos 4, cabeça do tamanho do parado, quadro 4 devolvido ao lugar por `offsets`, a acrobata desenhada vai em cima da torta e chuta; dano na mesma hora; fotos `-- dupla`; bateria completa ok). Recebida em 1774 × 887 (células de 443,5 × 887); original em `docs/referencias/pecas/originais/acrobata_chute_torta_codex_1774x887.png`, a candidata fica no lugar sem recorte nem ligação. Poses, caras, Torta de Ouro e fundo bons. Medidas (escala 2048, cabeças lado a lado alinhadas pelo nariz): branco do olho 37 × 54 contra 25 × 41 no parado e 22 × 38 na corrida; nariz 20 × 21 contra 18 × 15 e 15 × 13 (mesmo critério, `rednose2.gd`); torta uns 367 de largura contra 345 da torta voando (D2). Acrobata uns 30% grande e torta uns 6%: um fator único (0,76) acertaria a acrobata e deixaria a torta 19% pequena; partes com escalas diferentes não. Pedido D4b: irmã `acrobata_chute_torta_v2.png` com a acrobata redesenhada 24% menor e a torta 6% menor, medidas na escala de 1774. |
| B6 | leao/leao_fogo_rugido.png | **No jogo (03/10).** 1774 × 887, uns 9% grande como B2/B3; fator único 0,91: patas 479–522 contra 480–523, nariz 36 × 24–25 contra 35 × 27–28 (mesmo critério); patas em 482 e no x do rugido aprovado. `FIRE_ROAR_ANIM` no `lion.gd`; nenhuma pose em pé usa mais as chamas soltas. Captura `-- rugido_fogo` (entrada do fogo e Argolas Caindo, pelo cérebro do chefão). Bateria completa ok. Ver "Resultado do B6" na fila. |

### Resumo para retomar a frente de arte (se o contexto se perder)

- **Entregas:** A1 palhaco_parry, A2 acrobata_parry e A3 palhaco_parado no jogo; A4 recusada por escala; A4b também recusada (proporção); A3 (com o quadro 6 da A3c) e A4 (versão A4c) no jogo; A5 palhaco_pulo no jogo (escala única 1,26, `jump_animation` no `CharacterRig`); A6 acrobata_pulo no jogo (escala única 0,94, âncora `cintura` com `alvo_y=229`, a altura da cintura do parado). A7 palhaco_balao_flutua no jogo (fator 0,90, âncora `balao` com `alvo_y=240`, `balloon_animation` no `CharacterRig`, recorte com `ground_y` 240, `cell_height` 260 e `rig_height` 132). A8 palhaco_balao_vira_resgate no jogo (`balloon_turn_animation`: 1–4 ao cair, 5–8 num efeito solto no resgate; escala por grupo, 0,85 e 1,20, e 1,02 no 6; pivôs por quadro). A9 acrobata_balao_flutua no jogo (fator 0,91, `balloon_animation` no `acrobat_rig.tscn`; fotos com `screenshots.tscn -- balao2`). A10 acrobata_balao_vira_resgate no jogo (escala por grupo 0,80, 0,85, 0,91 e 0,97 no 6; a cabeça da acrobata medida pela largura do rosto, não pelo nariz, que nas folhas de balão é aumentado). A11 palhaco_dash no jogo (`dash_animation` e `dash_length` no `CharacterRig`, `pivot` no `FrameAnimation`, quadro pelo andamento do dash e giro na Pirueta). A12 acrobata_dash no jogo (fator 0,94, cintura em (300, 280) com `center_x` 300; fotos com `screenshots.tscn -- dash2`). A13 palhaco_abaixado recusada (cabeça na linha do tiro); A13b no jogo (cabeça em pé, braço saindo do tronco abaixo da gola, tiro na mesma altura). A14 acrobata_abaixado no jogo (e o quadro de meio caminho só depois de 60% do abaixar, para o braço não cruzar o rosto). A15 palhaco_dano no jogo (`hurt_animation`, `play_hurt`, `shoulders` à mão nos quadros reclinados, e o piscar começando depois do susto). A16 acrobata_dano no jogo (estrela da cintura em (256, 280) com `ground_y` 537, ombros à mão nos quadros 1 e 2). Bloco A completo. B1 leao_salto recusada (cabeça de tamanhos diferentes entre os quadros); B1b no jogo como `leao_salto.png` (8 quadros do salto pela direção do voo, chamas da fase 3 no meio da juba de cada quadro, fotos com `screenshots.tscn -- leao`). B2 leao_fogo_parado no jogo (fator único 0,92; parado em fogo sem as chamas soltas). B3 leao_fogo_corrida no jogo (fator único 0,91; correndo em fogo sem as chamas soltas). B4 leao_fogo_salto no jogo (fator 1,0; voos alinhados pela silhueta do corpo com o `register.gd`). B5 leao_derrota no jogo (fator único 0,95; `lie_down()` toca a derrota). Bloco B completo (o B6, rugido em fogo, entrou depois por delegação; pedido pronto na fila). C1 domador_folha aprovada como folha base (reorganizada em 2048 × 1024, cabeças do tamanho da do corpo). Decidido com o Codex: o Domador é desenhado com uns 465 px de altura na célula de 512 e reduzido para 260 no jogo (como a acrobata). C2 domador_chicote no jogo (o Domador deixou de ser SVG; quadro pela pose do chicote, mão por quadro). C3 domador_medo no jogo (fator único 0,80; tremor em loop e espiada). C4 domador_reverencia recusada (cabeça 13–16% menor nos quadros 3 e 4). C4b no jogo (quadros 1 e 2 da C4 + 3 e 4 da C4b; botas registradas com o chicote e o medo pelo `center_x`). Bloco C completo. D1 palhaco_torta no jogo (fator 0,961, sapatos alinhados; `special_animation` no rig). D2 torta no jogo (fator 0,935; voo em loop e esborrachar no primeiro acerto e no fim). D3 acrobata_salto_mortal no jogo (conferida em movimento com `-- salto_mortal`; giro por código substituído). D4b no jogo (Grande Número em Dupla com a acrobata chutando a torta). B6 no jogo (rugido em fogo; o leão não usa mais chamas soltas em pé). Eco dourado na acrobata do número em dupla (decidido por comparação). Desde 03/10 (pedido do usuário): o mapa é o mundo 3D da aventura (marco M0; ver "Piloto do mundo 3D"). Próximo: M0 visual em três rodadas (ver "M0 visual, terceira rodada": caminhada medida com `-- caminhada`, oclusão, chão, entradas e bordas, fotos com `-- mundo` e `-- entradas`); as texturas T1 (terra) e T2 (grama) já estão no jogo (ver "Textura T2"); falta só a avaliação humana, que não trava o M1; W1–W8 suspensas; MV1 pausada; Malabaristas: E1 aprovada tecnicamente (`malabaristas_folha.png`); E2 recusada como pedida e no jogo como "chuveiro" no parado dos dois irmãos, com o acabamento E2b (12 desenhos, clave pelo cabo; ver "Acabamento E2b"); E3 (arremesso por baixo) no jogo, ver "E3 dos Malabaristas"; E4 (tonto, suavizado na E4b) e E5 (salto mortal) no jogo, ver "E5 dos Malabaristas"; entradas do totem e do monociclo pilotadas; E6 (derrota) no jogo, ver "E6 dos Malabaristas"; Mágico: M1 aprovada tecnicamente e M2 (parado), M3 e M3b (feitiço e lançamento) no jogo; M4 (cartola), M5 (sumir) e M6 (reverência e medo) no jogo; marco de gameplay do Mágico (cartas pretas que perseguem, alvos P1/P2 alternados, rosas alcançáveis, embaralhar sem desfazer) e a revisão dele (parry nos dois e pela rede, saída real, Três Caixas sem deslize) feitos, falta o teste humano; M7 (mãos gigantes) e M8 (rosto gigante) no jogo, o Mágico todo desenhado; o piloto por peças do tonto não é viável (a cabeça tapa a gola; a E4b continua); a falha rara do Leque no cliente teve causa provável no próprio teste (esperava um ataque ainda no fim) e foi corrigida no teste, sem declarar resolvida; o tonto segue com a E4b, com um piloto híbrido por peças possível depois do Mágico, ver "M4 do Mágico (cartola) no jogo"; o meio do pêndulo do tonto foi recusado duas vezes (E4c e E4d) e o tonto segue com a E4b, ver "E4d recusada"; M2 em andamento (aviso de teclas, lista de controles e placa de controles no mapa feitos; falta jogar a Área 1 pelo executável novo, avaliação humana). Desde 03/10: decisões delegadas e marcos da versão 1.0 (DESIGN.md); toda animação nova passa pela captura a 60 quadros por segundo (`--fixed-fps 60 res://tests/screenshots.tscn -- corrida` ou `corrida2`, que gravam `corrida.csv` e uma foto por quadro) e, se for de andar, pela medida do pé de apoio (`soles.gd` e `slide_log.gd` no scratchpad). Ordem da fila (04/10): Malabaristas com as poses em pé desenhadas; próximo, o Mágico (a preparar); nenhum pedido de imagem do mundo aberto (T1 e T2 no jogo); MV1 pausada (se voltar, medir o deslize de novo depois de integrar, não antes); depois o bloco E. O B6 já está no jogo. Online com rede ruim: as duas falhas de 03/10 (caixas do Mágico, logs em `scratchpad/online_fail_c4/`, e o jogador do cliente que não nascia, logs em `scratchpad/online_fail_piloto/`) tinham a mesma causa, o aviso "carreguei a fase" perdido; corrigido no `player_spawner.gd` (ver "Rede: falha intermitente com rede ruim corrigida na causa"); depois disso 4 rodadas com rede ruim e 1 normal sem falhas, a acompanhar nas próximas baterias. As folhas de fogo vieram uns 9–10% grandes duas vezes: medir o vão das patas (`body.gd`) e o nariz (`darknose.gd`) contra a folha normal equivalente e corrigir com fator único. Para alinhar o leão: tronco = média dos pixels dourados à direita da juba (`torso.gd` no scratchpad), no voo em (649, 324); nariz com o `seedcolor.gd` de origem fixa. Para medir o nariz do leão: `lionnose2.gd` no scratchpad (marrom-escuro encostado no focinho creme); o `regrid_sheet.gd` aceita `celula=1024x512`. O salto do leão usa os 8 quadros de `leao_salto.png` (`LEAP_ANIM` e `_leap_frame` no `bosses/tamer/lion.gd`; entrada do `cut_animation_sheet.gd` com células de 1024 × 512, `center_x` 512, `ground_y` 486, `cell_height` 396, `rig_height` 297). Integração do abaixado: `crouch_animation` já existe no `CharacterRig`; a entrada do `cut_animation_sheet.gd` não leva `shoulder_from_nose` (a pistola fica no ombro das peças, tiro na mesma altura). Conferir com `screenshots.tscn -- abaixado` (ou `abaixado2`), que imprime ombro, mão e boca da pistola: a cabeça não pode ficar na faixa do braço. Para comparar rostos entre folhas de ângulos diferentes, usar o diâmetro do nariz de bola (`nose.gd` no scratchpad; o `_round_nose` do `regrid_sheet.gd` faz o mesmo). Para medir cabeça em poses inclinadas: largura da cabeça na linha dos olhos e altura do branco do olho são mais confiáveis que coque/chapéu-nariz. Para trocar só um quadro: juntar o original aprovado com o quadro novo antes do regrid (script `merge_frame6.gd` no scratchpad; refazer em `tools/` se for usar de novo). Opções do `regrid_sheet.gd`: `limpar`, `medir` (mostra também o nariz em px do topo), `altura=N` (por fila), `escala=F` (um fator só para a folha inteira, que mantém as diferenças de altura entre as poses) e a âncora `cintura` com `alvo_y=N` (meio do maiô da acrobata num ponto fixo). Para integrar uma versão v2: normalizar com `pes`, conferir as alturas (diferença de até 15 px) e copiar sobre o nome sem `_v2` só depois de aprovar. Parado: âncora `pes` e entrada com `shoulder_from_nose`.
- **Normalizar uma folha do Codex** (que vem em 1774 × 887):
  1. guardar o original em `docs/referencias/pecas/originais/<nome>_codex_1774x887.png`;
  2. `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/regrid_sheet.gd -- <original> <saída> 4 2 ar|chao|chao_fixo`
     - `ar`: o meio de cada quadro em (256, 280);
     - `chao`: a sola de cada quadro em 486 e o meio em x = 256;
     - `chao_fixo`: o mesmo deslocamento para todos os quadros (pés plantados no mesmo lugar);
     - a ferramenta separa os quadros pelo vão transparente mais perto da linha da grade;
     - salvar primeiro no scratchpad, conferir a imagem e só depois copiar para `docs/referencias/pecas/`.
  3. Recortar só a folha nova: `--script res://tools/cut_animation_sheet.gd -- <folha.png>`, com uma entrada em ANIMATIONS:
     - palhaço: `cell_height` 406, `rig_height` 198;
     - acrobata: 465 e 268;
     - `ground_y` 486, `center_x` 256;
     - no chão, `shoulder_from_nose`: palhaço (-64, 60), acrobata (-45, 55).
  4. Ligar o `.tres` no `<personagem>_rig.tscn`. O `CharacterRig` tem `run_animation`, `parry_animation`, `idle_animation` e `jump_animation` (A5).
- **Validar:** fotos com `--path . --resolution 1920x1080 res://tests/screenshots.tscn -- parry <pasta>` (tira do parry; para o parado há um modo próprio) e `sh tests/run_all.sh`.

## Sozinho vale dobrado e executável novo (04/10/2026)

- **Pedido do usuário:** sozinho, o chefão precisa morrer mais rápido, como se fossem 2 atirando.
- **Feito:** `BossBrain.SOLO_DAMAGE = 2`. No "Testar sozinho" cada tiro dos jogadores no chefão vale por dois
  (vale para os 3 chefões; nos Malabaristas o dano dobrado vai para o irmão atingido, com os mesmos limites de
  tontura). Online vale 1. A barra e as fases continuam iguais; só o dano por tiro muda.
- **Teste:** `test_magician` confere que sozinho vale 2 e a caixa certa tira 30 (10 × 1,5 × 2). Bateria
  completa: 9 locais sem falha, online normal e ruim ok.
- **Executável:** exportado em `build/RespeitavelPublico.exe` (release, com tudo até a M8, as revisões e a
  falha rara) e `build/RespeitavelPublico.zip`. O exe antigo (02/10) ficou em `build/antigo_02-10/`. Os zips
  antigos de `build/` já não estavam lá quando fui guardá-los.
- **Pedido seguinte (mesmo dia):** online, quando um cai, o outro também fica "sozinho". Agora
  `damage_scale()` vale 2 também online com só um jogador de pé (parceiro caído ou fora da partida) e volta a 1
  quando ele é revivido. O host aplica o valor na hora em que o tiro chega (`apply_shot`, usado pelos tiros do
  host e pelos do cliente via `BossSync`). `test_online` confere 2 com o cliente caído e 1 depois do parry no
  balão (passou nas 3 rodadas: bateria normal e ruim). Bateria completa verde; executável exportado de novo.

## Mapa 3D: "cima" não andava (achado pelo usuário no executável, 04/10/2026)

- **Defeito:** no mapa 3D, W e a seta para cima não andavam para a frente, então não dava para chegar nas tendas
  nem na loja. Causa: a opção "Cima também pula" (ligada por padrão) troca a tecla de cima do teclado por pulo
  e zera o "cima" do movimento. No mapa não existe pulo, então a tecla não fazia nada. Os testes não pegavam
  porque apertavam a ação `move_up` direto, sem a tecla física.
- **Correção:** `PlayerInput.up_can_jump`; o `WorldWalker` desliga, e no mapa "cima" sempre anda. Na luta e
  no Trem nada muda.
- **Teste novo** (`test_map`): tecla física W com a opção ligada. Com a correção desligada falha (0,00 m);
  com ela anda 1,66 m. Bateria completa verde.
- **Executável:** `build/RespeitavelPublico.exe` e `build/RespeitavelPublico_teste_04-10.zip`. O exe e o zip
  com o defeito ficaram em `build/antigo_04-10_sem_andar_frente/`.

## Teste em dupla do usuário: Domador, Malabaristas, vida, loja, menus e Camarim (04/10/2026)

O usuário jogou em dupla com um amigo e pediu (todos feitos, com teste automático):
- **Domador, fases 2 e 3:** em cima do pedestal, do lado do domador, ninguém tomava dano e dava para ganhar só
  atirando dali. Agora ele continua levando tiro, machuca quem encosta e, a cada 2,6 s, estala o chicote de
  medo para um lado do pedestal (alternando; chicote erguido 0,5 s antes como aviso; o estalo machuca 0,25 s).
  `test_tamer` (novo): parado em qualquer beira do pedestal toma dano; no chão ao lado, não; nada durante as
  trocas de fase; para na derrota. Fotos reproduzíveis: `-- domador_chicote <pasta>` no screenshots.
- **Malabaristas tontos:** o tonto pulava (Troca de Lugar) e arremessava, com o desenho tonto pulando. Agora,
  separados, o tonto fica parado no desenho de tonto: não arremessa, não troca de lugar (a troca não é escolhida;
  se ficar tonto agachado, desistem) e as Bolas Quicando são do outro. `test_jugglers` confere 0 quadros fora do
  desenho tonto. No totem continua como era.
- **Vida 20% menor:** Domador 1200, Malabaristas 1200 (600 cada), Mágico 1280. `test_online` usa
  `phase_end_health()` em vez de números fixos.
- **Loja:** o usuário apontou o Coração de Pano e o Nariz de Buzina como baratos demais: 3 → 6 ingressos.
- **Camarim:** "Voltar" caía no menu de pausa; agora fecha tudo e volta ao mapa (`test_shop` aperta o Voltar de
  verdade pela tenda).
- **Menus:** todos no estilo do cartaz de vitória (papel creme, moldura vermelha, lâmpadas, fita de título,
  botões de ingresso, estrelas no botão escolhido, chave liga/desliga desenhada): `UiTheme` refeito e
  `PosterPanel` novo, usados no menu inicial, pausa, configurações, Camarim e loja (preço num canhoto dourado,
  detalhes num cartão). Fotos antes/depois pelos modos `menus` e `loja` do screenshots (o `loja` usava o mapa
  2D antigo e foi corrigido).
- **Ficou de fora:** o desenho dos Malabaristas em totem (o usuário sabe que a arte não está pronta) e os
  corações voando para pegar vida (o usuário escolheu deixar assim e testar primeiro com a vida menor).
- **Grande Número com 2 s de proteção** (pedido seguinte): os dois personagens ficam invencíveis pelo menos
  2 s desde o começo do número (`PlayerSpecial.GRAND_MIN_INVINCIBLE`); o que sobra depois da animação pisca.
  `test_special` mede 2,00 s (palhaço) e 2,02 s (acrobata). O Tiro EX continua sem proteção.
- **Miniaturas do mapa mais bonitas** (pedido seguinte: "muito feio eles no mapa"): a câmera do mapa fica
  alta e atrás, então só aparecia a nuca (o palhaço era um ovo branco, a acrobata uma bola preta). Agora,
  parados por 0,6 s, os dois se viram de frente para a câmera; a cabeça fica erguida para o rosto aparecer;
  parados, trocam o peso de um pé para o outro; o palhaço ganhou uma coroa de tufos vermelhos atrás da cabeça;
  quadris mais altos (os joelhos ficavam dobrados parados); 15% maiores (`MINI_SCALE` 1,35 → 1,55). Fotos pelos
  modos `miniaturas` e `loja` do screenshots.
- **Prompt do totem dos Malabaristas** para o usuário levar ao ChatGPT/Codex: Pedido E7 na fila
  (`docs/prompts/fila_animacoes_codex.md`). Conflito achado: desenhado no tamanho normal, o totem não passa
  por baixo do pedestal; o usuário escolheu os irmãos menores no totem. Uma folha com os dois (o Tico embaixo,
  o Teco em cima); quando a base for o Teco, o jogo troca as cores.
- **Pausa do host para os dois** (pedido seguinte): online, a pausa do host congela os dois PCs; o cliente vê
  a faixa "Pausa do host". A pausa do cliente continua só dele. O Camarim pela tenda não congela o parceiro.
  Quem entra com o host pausado também congela. `test_online` seção 12: o relógio da luta do cliente para, a
  faixa aparece e some, e a pausa do cliente não congela o host.
- **Falha intermitente nova no teste online:** numa rodada, o "Número Perfeito" não deu a estrela nos dois PCs
  (`perfect bonus star (0.00)`), logo depois do Grande Número em Dupla. Não se repetiu nas 2 rodadas seguintes.
  Logs em `docs/medidas/online_falhas/04-10_perfeito_*.log`. Causa não achada; não está resolvida.

## E7: totem dos Malabaristas no jogo (04/10/2026)

- **Entrega:** a candidata do Codex (1774 × 887, uma chamada) foi revisada, normalizada (escala única,
  âncora nos pés) e integrada. O resultado completo, os desvios aceitos e as limitações estão na fila
  (`docs/prompts/fila_animacoes_codex.md`, "Resultado da E7").
- **Escala:** 0,477 no jogo. Com 0,5 o quadro mais alto entrava 9 px na tábua pendurada; com 0,477 fica 2 px
  abaixo dela.
- **Defeitos achados no piloto e corrigidos:**
  - o Totem Andante voltava o de cima para "sentado" a cada quadro (`place_group`), e o arremesso sumia;
  - a soltura vinha do tempo da pose, e agora vem do ataque (`throw_released`);
  - nas Claves em Linha a clave nascia longe da mão;
  - a caminhada a ritmo fixo deslizava, e agora avança pela distância andada.
- **Piloto a 60 quadros por segundo,** com o Tico e com o Teco de base:
  - ninguém leva dano na tábua;
  - a clave nasce na luva desenhada (0,0 px);
  - a bola de cura chega à cabeça desenhada;
  - teste novo no `test_jugglers`;
  - a bateria completa passou.
- **Próximo pedido de imagem:** a E8 (o monociclo, a fase 3). Já está na fila, pronta para colar, com a
  restrição dos pés: no máximo uns 8 px de jogo abaixo do selim, porque a tábua passa no vão do monociclo.
- **Continua aberto:**
  - a E4b do tonto (29,1 px no nariz, 8,4 px no sapato);
  - a falha intermitente do "Número Perfeito" no teste online;
  - nenhuma aprovação visual humana.

## Piloto 3D: palhaço modelado no Blender e trecho Camarim → Barraca (04/10/2026)

- **Pedido do usuário:** acabamento 3D com modelagem, animação, câmera, luz e ambiente juntos. Um piloto: UMA
  miniatura (o palhaço) e UM trecho. O Blender 4.5.14 LTS portátil foi preparado pelo Codex fora do projeto; usei
  só depois de conferir o arquivo e o `--version`. Nada pago, nada de Higgsfield.
- **Plano, baseline, resultado e limites:** `docs/medidas/mundo3d/plano_piloto_3d.md` (escrito antes de
  mexer).
- **Modelo:** um script do Blender, reproduzível. O jogo continua usando o andar procedural, por um esqueleto de
  controle.
- **Trecho:** pedras, capim, margaridas, varal âmbar com luzes e placa, tudo em MultiMesh.
- **Comparação reproduzível:** `-- mundo_piloto <pasta> [boneco] [sem_trecho] [desempenho]`, mais os vídeos do
  Movie Maker.
  - O pé desliza menos em todos os trechos (mediana de 4–9 mm contra 7–18; pior 26 contra 38).
  - O desempenho foi de 39,9 para ~42,7 quadros por segundo (jogo aquecido).
  - Câmera e escala ficaram iguais (o motivo está no plano).
- **Decisão:** integrar, preservando a baseline pelas chaves.
- **Bateria completa:** passou, inclusive online.
- **Pedido de imagem aberto:** o P3D1 (folha de modelagem do palhaço em 4 vistas). A E8 fica pronta, em
  espera.
- **Próximo defeito real:** o mapa 3D abaixo de 60 quadros por segundo neste PC (~40 a 43, com ~2700 chamadas
  de desenho, quase todas do cenário montado por peças). Depois: a acrobata no mesmo processo, se o usuário
  aprovar o piloto.
- **Continua aberto:**
  - a falha intermitente do "Número Perfeito" (causa desconhecida);
  - a E4b do tonto;
  - nenhuma aprovação visual humana.
