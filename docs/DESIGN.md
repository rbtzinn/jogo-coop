# Documento de Design — Respeitável Público

> Documento vivo. Atualizar sempre que uma decisão for tomada.

## Documentos detalhados

- [combat.md](combat.md) — vida, balão (reviver), parry, especial (Aplausos), nota
- [shop.md](shop.md) — loja, ingressos, Camarim e todos os itens
- [bosses.md](bosses.md) — chefões da Área 1 e ideias futuras
- [REFERENCIAS.md](../REFERENCIAS.md) — pranchas visuais dos chefões, loja, itens, combate e personagens (imagens em `docs/referencias/`)

## Visão geral

Jogo **2D de plataforma com chefões (boss fights)** para **2 jogadores online em cooperativo**, inspirado em **Cuphead**: fases curtas e intensas, chefões com várias fases de ataque, padrões para aprender, dificuldade justa e vontade de tentar "só mais uma vez".

A ideia anterior (3D em primeira pessoa no estilo It Takes Two) foi trocada por esta: é bem mais simples de produzir e continua muito divertida. A ideia de missões em que um jogador depende do outro pode voltar em partes, dentro das fases e dos chefões (ver "Decisões em aberto").

### Pilares

1. **Chefões memoráveis**: cada boss tem personalidade, 2–4 fases e padrões de ataque legíveis.
2. **Controle preciso e responsivo**: pular, atirar, dash e parry com resposta imediata. Morrer tem que parecer culpa do jogador, nunca do jogo.
3. **Cooperação**: os dois lutam juntos, podem reviver um ao outro e, em alguns momentos, precisam se coordenar.
4. **Visual com estilo forte**: 2D com shaders e pós-processamento que dão identidade (ex.: grão de filme, vinheta, paleta limitada), animações fluidas que não atrapalham a leitura dos ataques.
5. **Progressão por partes**: mundo dividido em ilhas/áreas, cada uma com alguns chefões e fases de plataforma.

## Decisões já tomadas

| Tema | Decisão |
|---|---|
| Nome | **Respeitável Público** (frase do apresentador de circo) |
| Gênero | Plataforma 2D run-and-gun + boss rush (estilo Cuphead) |
| Engine | **Godot 4** (gratuita; 2D excelente; código em texto via GDScript) |
| Câmera | Lateral 2D; nas lutas de chefe a arena é fixa ou com pouco movimento |
| Multiplayer | Host/cliente, PC a PC. O host cria o lobby e é a autoridade (chefão, dano, fases da luta) |
| Conexão (desenvolvimento) | **Atualizado em 02/10/2026:** o PC do jogador 1 não tem administrador (não instala Tailscale nem libera o Firewall). Por isso **o jogador 2 hospeda usando um túnel gratuito do playit.gg** (UDP, porta local 24680) e o jogador 1 entra digitando "endereço:porta". Tailscale ou IP direto continuam funcionando se um dia os dois tiverem administrador. Consequência: **o save fica no PC do jogador 2** (quem hospeda) |
| Steam | **Não agora.** Código preparado para adicionar Steam no futuro sem refazer |
| Save | Arquivo local no PC do host: chefões vencidos, área atual, upgrades/equipamentos de cada jogador |
| Assets | Gratuitos (Kenney, itch.io, OpenGameArt) como base/placeholder. Higgsfield (conta free, ~10 créditos) só para artes pontuais, ex. capa ou retrato de chefão |
| Custo | **Zero.** Distribuição entre os dois via executável ou itch.io (privado). Venda: decisão para depois da primeira área pronta |
| Produção | Por partes: um chefão de cada vez |
| Estilo visual | **Cartoon dos anos 30, recortado (cutout)**. Personagens e chefões montados em peças separadas (cabeça, tronco, membros) e animados por esqueleto (`Skeleton2D`/`Bone2D`) e tweens/`AnimationPlayer` na Godot, sem animação quadro a quadro. Shader de filme antigo por cima (grão, vinheta, leve tremido, cor desbotada). Os ataques precisam continuar bem legíveis sob o filtro |
| Tema | **Circo assombrado**, estilo anos 30. Os dois jogadores são artistas de circo que enfrentam as atrações de um circo amaldiçoado; cada atração é um chefão (ex.: domador, palhaço, mágico) |
| Personagens | **Jogador 1: palhaço** baixinho e redondo (roupa arlequim vermelho/creme, nariz vermelho, cartolinha com margarida). **Jogador 2: acrobata** alta e magra (collant azul-petróleo com estrelas douradas, coque). Silhuetas opostas para distinguir na hora no co-op. Os dois atiram com **pistolas de rolha**. Mesma caixa de colisão para os dois (jogabilidade idêntica) |
| Paleta | Contorno `#1b1410`. Fundo escuro e dessaturado (vermelho `#4f1f1f`, creme `#6f5d47`, noite `#2a1f2e`) para os personagens saturados se destacarem. Tiros do jogador: **branco + ciano `#5fe3ff` com contorno escuro**, legíveis sobre qualquer fundo (desde 05/10/2026 os tiros são desenhados, cada pistola com o seu: rolha, confete, clave e bolha). Reservado para o futuro: ataques do chefão em laranja/magenta, objetos de parry em rosa `#ff5fa2` |
| Arte | **Arte atual é provisória (mas caprichada):** o usuário pretende fazer a arte final com outra IA e só mantém a do Claude se gostar. Por isso a arte precisa ser **fácil de trocar**: cada personagem é uma cena com peças separadas (cabeça, piscar, tronco, sapatos, mãos) e pontos de encaixe (ombros, quadris, pescoço, cano da arma); a arte nova só precisa respeitar essas peças e pivôs. Desde 02/10/2026: peças ilustradas em **PNG com transparência** recortadas das folhas geradas por IA (escala uniforme, resolução 2x), detalhes em [personagens-visuais.md](personagens-visuais.md). Os SVGs anteriores continuam na pasta, sem uso. As cenas continuam animadas pelo mesmo código (`CharacterRig`): corrida, pulo, dash, mira, recuo do tiro, aterrissagem, piscar. Braços e pernas "de mangueira" (rubber hose) desenhados por código |
| Configurações | Menu de pausa (Esc / Start) com **Configurações** salvas em `user://settings.cfg`. **Controles:** toda ação pode ser trocada (2 teclas + 2 botões de controle por ação). **Vídeo:** qualidade gráfica (Baixa/Média/Alta), modo de tela, tamanho da janela, limite de FPS, VSync, mostrar FPS. Qualidade Baixa desliga o filtro de filme e as partículas |
| Dependência entre jogadores | **Base Cuphead + momentos de dupla.** Cada jogador luta de forma independente, com vida própria, e pode reviver o parceiro; se os dois caírem, a luta acaba. Alguns chefões têm fases ou ataques que exigem coordenação (distrair/atacar, parry duplo com janela de tolerância), mas nem todos |
| Jogar sozinho | **Decidido em 04/10/2026:** com um só atirando, cada tiro no chefão vale por dois: no "Testar sozinho" e online enquanto o parceiro está caído ou saiu. Com os dois de pé, vale 1. Regra em docs/combat.md ("Dificuldade") |
| Jogar sozinho | **Decidido em 06/10/2026 (pedido do usuário):** "Jogar sozinho" usa um personagem só, no mapa e nas lutas, com saves só dele, separados dos do jogo em dupla (ver "Dois saves para cada jeito de jogar"); Tab no mapa troca o palhaço pela acrobata no mesmo lugar e a escolha fica no save (`solo_character`). O "Testar sozinho" (modo de teste de 05/10/2026) saiu do menu e do código: o usuário já testou tudo. Hospedar sem ninguém entrar também joga com um personagem só (o palhaço). Na versão de desenvolvimento, F2 no mapa dá +50 ingressos e F1 nas lutas enche as estrelas. A pausa nas lutas e no trem tem "Voltar ao mapa" (online, só o host). |
| Mapa da Área 1 = a pintura de referência | **Decidido em 05/10/2026 (pedido do usuário):** o mapa é uma pintura (desde a etapa 3c, o mapa ampliado em quatro partes 2 × 2, com a câmera seguindo a dupla e mostrando uma região por vez), e os personagens andam por cima dela só pela terra pintada, escorregando pela beira; as portas ficam nas entradas pintadas. Velocidade no mapa 4,6 m/s. No mapa os personagens usam os mesmos desenhos PNG da luta (parado e corrida), menores; a miniatura 3D saiu. Detalhes em REMAP_VISUAL.md (etapa 3b). |
| HUD das lutas | **Decidido em 05/10/2026 (pedido do usuário):** o ingresso de cada jogador ficou maior, com corações e estrelas grandes e com contraste (vazio escuro, cheio vivo); a estrela que está carregando enche de baixo para cima, e com as 5 cheias aparece um brilho atrás delas (Grande Número pronto). |
| Limpeza de 06/10/2026 | **Pedido do usuário:** saiu o que não era mais usado: o mapa 2D antigo (`levels/circus_map/`), a arena de teste, o mundo 3D antigo (miniaturas, modelo do palhaço, terreno, cenário pré-renderizado e as peças 3D das tendas), shaders sem uso, SVGs de origem da arte provisória, e os scripts do Blender do parque antigo. A porta do mapa (`WorldDoor`) ficou só com a área de entrada e o aviso. O modo de teste ficou **guardado no código e escondido**: para usar, trocar `SHOW_TEST_MODE` para `true` em `core/ui/main_menu.gd`. |
| Trem do Circo maior e uma vez só | **Decidido em 06/10/2026 (pedido do usuário):** a fase do Trem ganhou 5 vagões (de 7 para 12, mais a locomotiva; 6900 → 11100 px), com 3 caixotes e 9 inimigos a mais; os 3 ingressos escondidos são os mesmos, espalhados pela fase. Depois de concluída, a entrada no mapa mostra "Concluída" e não abre mais naquele save (`WorldDoor.once`; o modo de teste deixa jogar de novo). |
| Desafios dos vagões do Trem | **Decidido em 06/10/2026 (pedido do usuário: o Trem era simples e acabava em menos de 1 minuto):** os cinco últimos vagões viraram desafios, cada um com um **desafiante novo** (nada aproveitado dos chefões): ACROBATAS, o Saltimbanco de Mola (salta por cima do vagão; ao cair solta uma onda rente ao teto); TRAPÉZIO, a Trapezista do Além (passa na altura da cabeça: abaixar) e depois um vão largo demais para pular, atravessado num balanço; LEÕES, os Leõezinhos de Pelúcia (saem das escotilhas e cospem novelos; só levam tiro fora); BALÕES, uma pilha de carga alta demais (sobe-se num balão-elevador) com o Baloeiro Assombrado soltando bexigas d'água; FANTASMAS, as Sombras do Lanterninha (com a lanterna apagada os tiros atravessam). Vãos maiores entre os vagões (até 300 px), pontes a cada 9 s (eram 13; não machucam no balanço nem no balão), fase com 13140 px. Arte dos pedidos D1 a D5 (`docs/prompts/chatgpt_trem_desafiantes.md`), recortada por `tools/cut_train_challengers.gd`. |
| Tiro some ao sair da tela | **Decidido em 06/10/2026 (pedido do usuário: dava para derrubar inimigo que ainda nem tinha aparecido, e por isso o Trem ficava fácil):** os tiros dos jogadores (e o Rolhão do Tiro EX) somem ao sair da tela de quem atirou, além do tempo de vida de cada pistola. |
| Dois saves para cada jeito de jogar | **Decidido em 06/10/2026 (pedido do usuário):** "Hospedar partida" e "Jogar sozinho" abrem a escolha entre **Save 1 e Save 2** (cada jeito de jogar tem os seus dois). Cada save mostra quantas atrações já foram concluídas e tem "continuar" ou "Do zero" (pede confirmação com um segundo clique, "Apagar?"). O Save 1 é o arquivo que já existia (`user://save.json` na dupla, `user://save_solo.json` sozinho); os novos são `save_coop_2.json` e `save_solo_2.json`. O save sozinho novo começa do zero (não copia mais o da dupla). Quem entra na partida joga com o save de quem hospeda, como antes. |
| HUD menor | **Atualizado em 06/10/2026 (pedido do usuário):** o ingresso dos jogadores (corações e estrelas) ficou 40% menor (`FightHud.TICKET_SCALE`), no mesmo canto de baixo, porque tapava os golpes. |
| Pausa online | **Atualizado em 06/10/2026 (pedido do usuário):** a pausa de **qualquer um** congela os dois PCs, e o outro vê a faixa "Pausa do parceiro"; se os dois pausarem, o jogo volta quando os dois continuarem. (Em 04/10/2026 só a do host congelava.) O Camarim aberto pela tenda do mapa não congela o parceiro. As configurações são de cada PC (`user://settings.cfg`), cada um com as suas. |
| Mundo 3D (piloto 04/10/2026) | **Palhaço modelado no Blender** (`tools/blender/palhaco_miniatura.py` → `core/world/models/clown.glb`, com esqueleto e pele), dirigido pelo andar procedural de sempre (pés plantados por IK). O **trecho Camarim → Barraca** ganhou acabamento: pedras, capim, margaridas, varal de lâmpadas âmbar e placa. Câmera e escala sem mudança. Resultado, comparação e limites em `docs/medidas/mundo3d/plano_piloto_3d.md`. A acrobata e o resto do parque só depois da avaliação humana do piloto. |
| Mecânicas do jogador | Ver seção "Mecânicas do jogador" abaixo |
| Hardware | Jogador 1 (desenvolve e joga no mesmo PC): **Intel UHD Graphics 630 integrada**, i5-8500T, 16 GB RAM. Jogador 2: placa de vídeo dedicada (modelo a confirmar). O PC mais fraco é a referência |
| Renderizador | **Compatibility (OpenGL)** da Godot 4: roda bem em vídeo integrado e cobre tudo que o 2D precisa (shaders, pós-processamento). Meta: **60 FPS estáveis no PC do jogador 1**. Efeitos pesados (muitas partículas, blur grande) devem ter opção de desligar. **FPS ilimitado e VSync desligado por padrão** (pedido do usuário); limite de FPS e VSync ajustáveis em Configurações > Vídeo. Física a 60 Hz com **interpolação de física** ligada, para o movimento ficar liso em qualquer FPS |

### Mecânicas do jogador

| Mecânica | Detalhes | Entra em |
|---|---|---|
| Andar | Aceleração rápida, sem "patinar" | Etapa 2 |
| Pulo | **Altura fixa** (tocar ou segurar dá o mesmo pulo, pedido do usuário), coyote time, buffer de pulo | Etapa 2 |
| Tiro | 8 direções; botão para travar posição e só mirar | Etapa 2 |
| Dash | Avanço rápido no chão e no ar, para desviar | Etapa 2 |
| Abaixar | Segurar **Baixo** no chão (sem travar a mira): para de andar, caixa de dano baixa de 132 para 84 (desvia de ataques altos) e atira reto rente ao chão | Etapa 2 |
| Descer da plataforma | **Abaixado + dash** em cima de uma plataforma: atravessa para baixo (no chão firme o dash é normal). Plataformas ficam na camada de física 5 ("plataformas"); os tiros passam por elas | Etapa 2 |
| Parry | Pular em objetos rosa no ar para quicar; enche a barra de especial | Etapa 4 (1º chefão) |
| Golpe especial | Ataque forte que gasta a barra (enche com dano causado e parries) | Etapa 4 (1º chefão) |
| Equipamento | Pistola, Truque (dash), Adereço e Número de dupla, comprados na loja (ver "Loja e equipamento") | Etapa 5 |
| Reviver parceiro | Ver "Dependência entre jogadores" | Etapa 4 |

Fases de plataforma "puras" existem, mas são poucas e curtas, entre os chefões (a primeira na etapa 5).

### Loja e equipamento (etapa 5) — detalhes em [shop.md](shop.md)

Ideia do usuário: comprar itens com o que se ganha vencendo chefões, numa loja do circo. Parecido com o Cuphead no espírito, mas **diferente em pontos-chave**.

Cada jogador equipa **4 espaços**:

| Espaço | O que é | Exemplos |
|---|---|---|
| Pistola | Tipo de tiro | Rolha padrão, leque de 3 rolhas, rolha teleguiada, rolha que quica |
| Truque | **Modifica o dash** (diferencial: no Cuphead o dash não é personalizável) | **Fumaça do Mágico**: some numa nuvem e reaparece à frente, invencível, deixando um boneco de fumaça que distrai o chefão por um instante. **Bala de Canhão**: o dash causa dano. **Pirueta**: dash também na diagonal para cima |
| Adereço | Passivo | +1 vida, parry automático no 1º objeto rosa, barra de especial enche mais rápido |
| Número de dupla | Combo que só funciona com o parceiro (diferencial cooperativo) | **Catapulta**: dash em direção ao parceiro arremessa você. **Rolha turbinada**: tiro que atravessa o parceiro sai mais forte |

**Moeda: ingressos, em quantidade limitada (sem farm).** A 1ª vitória contra cada chefão dá ingressos; melhorar a melhor nota naquele chefão (B → A → S) dá bônus; alguns ingressos ficam escondidos nas fases de plataforma. Assim o total é conhecido e a dificuldade pode ser calibrada, e revisitar chefões tem objetivo (nota melhor).

**Carteira individual.** Cada jogador tem seus ingressos (os dois ganham a mesma quantidade por vitória) e pode **doar ingressos ao parceiro**. Itens comprados são de quem comprou. O save do host guarda carteira e itens de cada jogador.

**Lojista: boneco de ventríloquo assombrado**, que fala sozinho (sem ventríloquo nenhum por perto), numa barraca de curiosidades no parque do circo. Tom cômico e sinistro. Nome e falas a definir (ficam em `dialogues/`).

### Controles

| Ação | Teclado (layout 1) | Teclado (layout 2, estilo Cuphead) | Controle |
|---|---|---|---|
| Mover / mirar | WASD | Setas | Analógico esquerdo ou direcional |
| Pular | **Cima** (W) ou Espaço | **Cima** (Seta ↑) ou Z | A |
| Atirar (segurar) | J | X | X |
| Dash | K | Shift | B |
| Travar mira (fica parado e mira em 8 direções; com ela, Cima mira para cima em vez de pular) | L | C | RB |

No chão, sem travar a mira, **Baixo abaixa** o personagem (não mira para baixo). Abaixado em cima de uma plataforma, **dash desce** dela.

**Cima pula (pedido do usuário, só no teclado).** Sem travar a mira, a tecla de cima pula e não mira; segurando "Travar mira", o boneco para e Cima volta a mirar para cima. Só um aperto novo de Cima pula (soltar a trava segurando Cima não faz pular). No teclado, mirar para cima ou na diagonal para cima exige travar a mira. Pode ser desligado em Configurações > Controles. No controle de videogame o analógico continua mirando normalmente e o pulo é o A.

Estes são os controles **padrão**; o jogador pode trocar qualquer um em Configurações > Controles.

### Contexto de rede dos jogadores

- Jogador 1 em **Suape (Ipojuca-PE)**, jogador 2 em **Olinda-PE** (~50 km, mesma região metropolitana).
- Ping esperado em conexão direta: ~10–40 ms. Via relay da Steam (São Paulo) seria pior (~60–90 ms), por isso Tailscale/direto é preferível.
- Jogo de ação precisa de cuidado com latência:
  - Movimento, pulo e tiro do jogador local com **predição no cliente** (resposta instantânea).
  - Jogador remoto e projéteis com **interpolação**.
  - Chefão e seus ataques simulados no host; padrões determinísticos sempre que possível (host manda "começou o ataque X no tempo T", e cada PC simula), para economizar rede e ficar suave.
  - Dano recebido pelo cliente decidido de forma justa para quem joga (evitar "fui atingido por algo que já tinha desviado").
- Atenção a **CGNAT** das operadoras: por isso Tailscale.

## Decisões em aberto

### Reformulação visual autorizada em 05/10/2026

Todo o layout será renovado por etapas com Blender, mantendo identidades e lógica do jogo. Publicar cada etapa com commit e push para main. Direção, limites de gameplay e conferência em [REMAP_VISUAL.md](REMAP_VISUAL.md).

1. ~~**Estilo visual**~~ — decidido (ver tabela acima).
2. ~~**Tema**~~ — decidido: circo assombrado. **Ainda a detalhar** (pode ser depois da etapa 2): nome dos dois artistas, por que o circo foi amaldiçoado, como as áreas se dividem (ex.: tendas, picadeiros, trem do circo).
3. ~~**Quanto um depende do outro**~~ — decidido (ver tabela acima).
4. ~~**Mecânicas do jogador**~~ — decidido (ver seção acima).
5. ~~**Hardware**~~ — decidido (ver tabela acima).
6. ~~**Nome do jogo**~~ — decidido: **Respeitável Público**.

## Roadmap

1. **Conceito** — fechar as decisões em aberto acima. ✔ concluída
2. **Base jogável** — dois jogadores pulando e atirando no mesmo cenário, conectados online (host/cliente), com predição e interpolação. Controle precisa ficar gostoso aqui.
   - **2a — Controle local**: um jogador anda, pula, dá dash e atira em 8 direções numa arena de teste. Inclui (a pedido, adiantando parte da etapa 3): personagens desenhados e animados, arena de circo, filtro de filme antigo, efeitos e menu de Configurações. ✔ concluída
   - **2b — Conexão**: tela inicial com "Hospedar" / "Entrar na partida" (IP) / "Testar sozinho"; porta **24680** (UDP); host = palhaço, cliente = acrobata; cada PC controla o próprio personagem e envia o estado ao outro; tiros aparecem nos dois PCs; aviso de "esperando parceiro" com os IPs e de "parceiro saiu"; online a pausa não congela o jogo. ✔ concluída (testada pelo usuário com 2 janelas)
   - **2c — Rede de verdade**: predição do jogador local, interpolação do remoto, teste com o parceiro (agora via playit.gg). Feito: interpolação do jogador remoto (mostrado 100 ms no passado; tiros no mesmo tempo), simulador de internet ruim e ping na tela (Configurações > Rede). Executável gerado (`build/RespeitavelPublico.exe`, um arquivo só, ~105 MB; a pasta build não vai para o git). ✔ concluída: testada de verdade em 02/10/2026 com o parceiro hospedando via playit.gg, lutando contra o Domador com ~210 ms de ping, e deu para jogar tranquilo.
3. **Visual base** — shaders, pós-processamento, "cara" do jogo. (Parte já adiantada na 2a; aqui entra o refinamento.)
4. **Primeiro chefão** completo (com todas as fases da luta), tela de vitória/derrota e save. Decidido em 02/10/2026 começar por aqui (mapa e itens dependem dos chefões); a etapa 3 vai sendo refinada junto. Dividida em partes testáveis:
   - **4a — Luta básica**: vida dos jogadores (3 PV, 1,5 s invencível piscando, empurrão; o dash atravessa ataques), "caído" quando a vida acaba (o balão vem na 4c), chefão com vida e a fase 1 do Domador (Chicotada, Argolas de fogo, Rugido), letreiro de abertura, "Nocaute!", tela de vitória/derrota com "Tentar de novo", placar de vida dos jogadores e barra de vida do chefão no topo (o Cuphead não mostra; dá para tirar se atrapalhar). "Testar sozinho" e "Hospedar" abrem a luta (a arena de teste continua no projeto, sem entrada no menu). A arte do Domador e do Leopoldo é provisória (SVG), trocável por arte de IA. ✔ concluída (testada sozinho e online)
   - **4b — As três fases** (adiantada a pedido do usuário): "O Número Ensaiado" (100–60%), "Fora de Controle" (60–25%) e "O Leão de Fogo" (25–0%), com animação de troca e letreiro; barra de vida do chefão com estrelas marcando o início de cada fase; placar, letreiros e tela de fim em estilo de circo (letreiro com lâmpadas, ingressos, faixas, cartaz). ✔ concluída
   - **4c — Parry, reviver e Aplausos**. Feito: parry (pular de novo no ar encostando no rosa: quica, gira, 0,35 s protegido, +1 estrela, o objeto estoura nos dois PCs); balão de reviver (caído vira balão rosa com a própria cara, sobe ~6 s; parry do parceiro revive com 1 PV e 2 s invencível; se sair pela tela, fica fora); estrelas de Aplauso no ingresso (enchem com dano: 45 de dano = 1 estrela, e com parry). **Parte 2 (02/10/2026):** botão **Especial** (rebindável: I / V / Y), **Tiro EX** "Rolhão" (1 estrela), **Grande Número** (5 estrelas: "Torta na Cara" e "Salto Mortal"), **Número Perfeito** e **Grande Número em Dupla** (Torta de Ouro), tudo também online; mais ataques rosa no Domador (onda rosa na Chicotada, onda rosa na Patada, brasas rosa nos Pulos). Detalhes e números em docs/combat.md. Testes automáticos em `tests/`. ✔ concluída (testada pelos testes automáticos; falta o teste do usuário)
   - **4d — Nota e save** (02/10/2026): nota C/B/A/S no cartaz de vitória (regras em docs/combat.md) e save automático ao vencer, em `user://save.json` no PC do host (no "Testar sozinho", no próprio PC): chefões vencidos com melhor nota e melhor tempo, área atual e, para cada jogador, ingressos, itens e equipamento (começa com Rolha e Cambalhota). Ingressos como em docs/shop.md: 3 na 1ª vitória, +1 na 1ª nota A ou melhor, +1 na 1ª S. O save ainda não é usado por nenhuma tela (o mapa e a loja vêm na etapa 5). ✔ concluída (testes automáticos; falta o teste do usuário)
   - **4e — Acabamento online** (02/10/2026): quem sai da partida avisa o outro PC na hora (antes o host só percebia depois de vários segundos); o parceiro que cai e volta no meio da luta recebe do host a fase e a vida atuais do chefão (antes voltava na fase 1 com vida cheia); no fim da luta online o cliente espera o host mandar o resultado (com a nota). Teste online automático com dois processos sem janela (`sh tests/run_online.sh`, também com internet ruim simulada): Especial, Número Perfeito, Grande Número em Dupla, vitória com nota, "Tentar de novo", queda e volta do parceiro, balão e reviver. ✔ concluída (testes automáticos; falta o teste do usuário com o parceiro)

### Arte em andamento (02/10/2026)

- O usuário gera a arte com ChatGPT/Codex em paralelo; o Claude escreve os prompts (em `docs/prompts/`) e encaixa as folhas no jogo com `tools/cut_animation_sheet.gd` (e `tools/normalize_sheet.gd` quando a folha não respeita a grade). Detalhes em [personagens-visuais.md](personagens-visuais.md).
- **No jogo:** corrida, parry (cambalhota), parado e pulo desenhados do palhaço e da acrobata, o dash dos dois, o abaixado dos dois, o dano dos dois, e o balão do palhaço (virando balão, flutuando e estourando no resgate) e o da acrobata (virando balão, flutuando e estourando) (03/10/2026; todas as poses de movimento dos jogadores já são desenhadas; o braço da pistola continua por código, de propósito, e a Torta na Cara do palhaço, a torta voando e esborrachando e o Salto Mortal da acrobata já são desenhados (D1, D2, D3, 03/10/2026); os outros especiais ainda usam o desenho de peças; fila e andamento em `docs/prompts/fila_animacoes_codex.md` e `docs/diario-autonomo.md`); Leopoldo inteiro desenhado (parado, rugido, galope e o salto em 8 quadros: agachado, saída, subindo, dois no alto, descendo, perto do chão e pouso; 03/10/2026). Na fase 3, o parado, o rugido, a corrida e o salto têm a juba de fogo desenhada, e a derrota (cansado, deitando, dormindo) é desenhada (03/10/2026).
- **Pedidos pendentes** (o usuário avisa quando chegarem): Pedido 3 do leão (`docs/prompts/codex_leao.md`) já está todo no jogo (salto, juba de fogo no parado, corrida e salto, derrota) e parry, balão e especiais dos personagens (`docs/prompts/codex_parry_balao_especiais.md`: cambalhota desenhada no lugar do desenho girando, balão com transformação/flutuar/vento/resgate, Torta na Cara, torta, Salto Mortal e chute da torta em dupla). Depois: pulo, dash, abaixado, parado e dano dos personagens, e a arte do Domador (a folha base `domador_folha.png` foi aprovada em 03/10/2026 e o chicote, o medo e a reverência já são desenhados (C2, C3, C4); os quadros são desenhados com uns 465 px de altura na célula de 512, reduzidos para 260 no jogo).
- **Regras de arte (pedido do usuário):** nada de desenho parado deslizando pela tela (cada movimento com quadros próprios + "suco" no código) e **expressões faciais diferentes em cada quadro** em todos os pedidos novos (sem refazer os antigos).
- Ideia aprovada para depois: juba/cauda em camada separada com um shader de vento.
- **Pedidos ao ChatGPT de 05/10/2026** (A: pistolas e tiros; B: fase do Trem; C: ícones dos itens; monociclo em peças; D: efeitos do Domador, ainda não chegou): as folhas ficam em `docs/referencias/pecas/armas/`, `trem/`, `itens/` e `malabaristas/`. A ligação no jogo foi dividida em fases (decidido pelo Claude a pedido do usuário): **1** pistolas e tiros, **2** ícones da loja e do Camarim, **3** monociclo em peças, **4** fase do Trem (4a cenário, 4b inimigos, 4c ingresso escondido), **5** efeitos do Domador.
  - **Fase 1 no jogo (05/10/2026):** a luva troca de desenho com a pistola equipada (`GunLooks`, `CharacterRig.set_weapon`), cada pistola com a boca e o clarão dela; os tiros e os acertos das 4 pistolas são desenhados (a rolha gira, o confete gira, a clave gira em 8 posições, a bolha balança e fica sempre em pé); os Tiros EX também: o Rolhão, o Canhão de Confete (no lugar do anel) e a Bolhona com o estouro. Recorte por `tools/cut_weapon_art.gd`; tamanhos iguais às caixas de colisão de antes (nenhum número da luta mudou). As faíscas ciano dos acertos saíram. Na qualidade Baixa os acertos desenhados não aparecem (como as faíscas antes) e as explosões voltam ao anel.
  - **Fase 2 no jogo (05/10/2026):** os 17 itens têm ícone (`core/shop/icons/<id>.png`, recortados por `tools/cut_item_icons.gd`, lidos por `Catalog.icon`): pequeno ao lado do nome na prateleira da loja e nas listas do Camarim, e grande ao lado do nome no cartão de detalhes da loja.
  - **Fase 3 no jogo (05/10/2026):** o monociclo dos Malabaristas é desenhado em duas peças (`tools/cut_unicycle_parts.gd`): a roda, que gira conforme anda, e a armação (garfo, haste, pedais e selim) na frente dela. Mesmo tamanho de antes (roda de raio 110, selim a 330 px do chão), sem mudança na luta. Os pedais são desenho parado (antes giravam por código) e ficam uns 30 px abaixo dos sapatos de quem pedala. Com isso, os Malabaristas não têm mais boneco de código.
  - **Fase 4 no jogo (05/10/2026):** a fase do Trem é desenhada (`tools/cut_train_art.gd`). **4a cenário:** os vagões (vermelho, azul, mostarda e verde, um esticado para o tamanho de cada vagão) com rodas girando por cima das pintadas e o letreiro na faixa (o maior tamanho que cabe); a locomotiva com escala única (sai um pouco da tela à direita, como se a frente continuasse) e fumaça saindo da chaminé; o céu com morros e os postes com a cerca correndo para trás; a ponte baixa; e a placa do aviso com "ABAIXE!" embaixo. **4b inimigos:** o fantasma pula com 4 desenhos (agachado, subindo, no alto e pousando) e murcha num lençol ao ser derrotado; o pombo bate as asas (o rosa tem desenho próprio); o canhão fica entediado, enche as bochechas antes do tiro, atira e fica tonto; a bola rola girando (a rosa também). **4c:** o ingresso escondido gira como uma moeda. Caixas de colisão, tempos e posições iguais aos de antes. Ficam por código só os caixotes e os trilhos.
  - **Fase 5 no jogo (05/10/2026):** os efeitos do Domador são desenhados (`tools/cut_tamer_effects.gd`, folhas em `docs/referencias/pecas/domador/efeitos/`): as ondas de som do Rugido (a faixa creme com os ecos atrás, dobrada pela curva do arco; o trecho do meio se repete e as pontas fecham cada lado do buraco, com 3 quadros de vibração), a onda da Chicotada e da Patada (4 quadros, normal e rosa), as brasas (2 quadros, normal e rosa; também na tocha e no aviso da Chuva de Argolas) e as argolas (apagada, acesa em 2 quadros e rosa). Colisões, tempos e tamanhos iguais aos de antes. Com isso, todos os pedidos de arte ao ChatGPT de 05/10 estão no jogo.

5. **Primeira área**: mapa de seleção + 2–3 chefões + uma fase de plataforma. Dividida em partes (decidido pelo Claude em 02/10/2026, revisar):
   - **5a — Mapa do parque** (02/10/2026): "O Grande Picadeiro", uma tela lateral com o parque à noite e uma tenda para cada número: Domador, Malabaristas, Trem do Circo, Grande Mágico (fechado até vencer os outros três) e a Barraca de Curiosidades (loja). Os dois andam sem atirar; **Atirar na frente da tenda entra** (a dica mostra a tecla). Tendas de fases que ainda não existem mostram "Em breve". A tenda mostra a melhor nota da dupla. O menu ("Hospedar" e "Testar sozinho") abre o mapa; o cartaz de fim de luta ganhou "Voltar ao mapa"; ao chegar no mapa o host salva. Online, qualquer um dos dois escolhe a tenda e o host leva os dois; quem entra na partida cai direto na fase em que o host está; o host manda uma cópia do save para o cliente ver notas e ingressos. Arte provisória por código; pedido de arte em `docs/prompts/codex_mapa.md`. ✔ concluída (testes automáticos)
   - **5b — Os Irmãos Malabaristas** (02/10/2026): luta completa com as 3 fases (Troca-Troca, Totem, Monociclo Gigante), 9 ataques e as duas animações de troca de fase; mecânica "Um Não Vive Sem o Outro" (cada irmão com sua vida, tontura no limite da fase, bola de cura rosa depois de 3 s, os dois precisam cair juntos para trocar de fase); placar com uma barra para cada irmão; tenda do mapa liberada. Regras e números em docs/bosses.md. Desenho provisório por código; pedido de arte em `docs/prompts/codex_malabaristas.md`. O cérebro genérico de chefão foi separado em `components/boss/boss_brain.gd` (o Domador também usa). ✔ concluída (testes automáticos e fotos da luta; falta o teste do usuário)
   - **5c — Corrida no Trem do Circo** (02/10/2026): fase de plataforma de correr e atirar em cima de 7 vagões até a locomotiva. Os vagões ficam parados e o cenário corre para trás (morros, postes, trilhos e rodas girando). Câmera que segue a dupla e não deixa ninguém sair da tela. Cair num vão tira 1 vida e volta no vagão visível mais próximo. Inimigos: palhacinho-fantasma (vai e volta pulando), pombo de mágico (voa em oito; um é rosa) e canhão de confete (bolas rente ao chão; 1 em 4 rosa). **Pontes baixas** passam por cima do trem: placa "ABAIXE!" piscando antes; em pé machuca, abaixado passa. **3 ingressos escondidos** (cada um vale +1 para cada jogador na 1ª vez). Chegar na locomotiva termina ("Fim da linha!") e libera um dos cadeados do Mágico. Os inimigos andam pelo relógio da fase (iguais nos dois PCs sem mandar posição); o host decide vida, morte, ingressos e o fim. Arte provisória por código; pedido de arte em `docs/prompts/codex_trem.md`. ✔ concluída (testes automáticos sozinho e online e fotos da fase)
   - **5d — O Grande Mágico Zaratan** (02/10/2026): luta completa que fecha a Área 1, com as 3 fases (Abracadabra, A Mulher Serrada... sem Mulher, O Grande Final), 9 ataques e as duas trocas de fase. Momento de dupla do **Blackout** (escuro com um holofote em cada jogador; juntos, os holofotes crescem) e o **jogo das três caixas** (atirar na caixa certa machuca 50% a mais; a errada solta pombas). Na fase 3 vira um **mágico gigante** (cabeça, cartola e mãos que agarram). Ao vencer, cai dentro da própria cartola e deixa o **ingresso dourado** (gancho para a Área 2). A tenda do mapa abre depois do Domador, dos Malabaristas e do Trem. Regras e números em docs/bosses.md. Desenho provisório por código; pedido de arte em `docs/prompts/codex_magico.md`. ✔ concluída (testes automáticos sozinho e online e fotos da luta)
   - **5e — Loja e Camarim** (docs/shop.md), em duas partes:
     - **5e1 — Barraca e Camarim** (02/10/2026): a tenda "Curiosidades" do mapa abre a loja só na tela de quem entrou (prateleira por espaço, detalhes, comprar com confirmação, dar ingressos ao parceiro); o lojista, um boneco de ventríloquo, ganhou o nome provisório **Seu Bonifácio** (decidido pelo Claude, revisar) e falas em `dialogues/lojista.json`; os itens ficam em `dialogues/items.json`. O **Camarim** abre pelo menu de pausa só no mapa (4 espaços para cada personagem deste PC). Compras, doações e equipamento ficam no save do host; online o cliente pede e o host confere (o cliente só mexe na própria carteira). Enquanto a loja está aberta, o personagem não se mexe. ✔ concluída (testes automáticos sozinho e online)
     - **5e2 — Efeito dos itens** (02/10/2026): as 4 pistolas (com o Tiro EX de cada uma), os 3 truques novos, os 5 adereços e os 4 números de dupla funcionam, sozinho e online (números em docs/shop.md). ✔ concluída (testes automáticos)
   - **Com a 5e, a Área 1 está completa** (mapa, 3 chefões, fase do trem, loja). Arte toda provisória (por código) com pedidos para o Codex em `docs/prompts/`; a Área 2 ainda não tem design.
6. Áreas seguintes, um chefão de cada vez.


### Aventura: mundo 3D da área (pedido do usuário em 03/10/2026; decisões por delegação, revisar)

O usuário não gostou do mapa de tendas em fila nem de escolher os chefões assim. Ele quer uma aventura
em que os dois andam pelo mundo até os chefões, com lojas no caminho, num mapa 3D visto de cima.

**O que fica:**
- As lutas e a fase do trem continuam 2D, como estão.
- O mundo é só o lugar por onde se anda entre elas.
- Nada de menu de cartões: escolhe-se andando até a tenda.

**Câmera** (escolhida para o piloto): alta e oblíqua, sempre do mesmo ângulo (48° para baixo no piloto; 42° desde a segunda rodada), seguindo
o meio da dupla com suavidade.
- Lê bem os dois juntos, as tendas e o caminho.
- Não precisa de controle de câmera, que no coop online desorienta.
- Terceira pessoa fica para comparar num teste curto se esta não convencer jogando.

**Cenário:** diorama 3D de circo assombrado (formas simples por enquanto) com luz de lua, postes e
névoa. Os personagens eram desenhos 2D virados para a câmera (billboards) no piloto. Isso foi
superado: hoje são miniaturas 3D (ver a revisão abaixo).

**Entrar numa tenda:**
- Anda-se até a frente dela e aperta-se Atirar.
- Online, os dois precisam estar na frente: quem chega sozinho vê "Esperando o parceiro". Ninguém é
  levado para a luta sem ter ido até lá.
- Sozinho, o personagem que você não controla segue você (Tab troca).
- Voltando da luta, a dupla aparece na frente da tenda de onde saiu.

**Roteiro da Área 1** (finito; só o conteúdo que já existe, nada de chefão novo), um caminho do
portão até a tenda do Mágico, nesta ordem:

| Ponto | O que é |
|---|---|
| Portão | onde a dupla começa; ao lado, o carroção do **Camarim** (trocar equipamento) |
| O Domador | o primeiro chefão, o mais fácil, logo na entrada |
| Barraca de **Curiosidades** | a loja, logo depois do primeiro chefão, quando chegam os primeiros ingressos |
| Os Malabaristas e o Trem do Circo | lado a lado, em qualquer ordem |
| O Grande Mágico | no fim do caminho, maior; fechado até vencer os outros três (como antes) |

**Segunda barraca:** em vez de uma loja nova, uma segunda entrada da mesma loja perto do Mágico ("Última
parada"), para comprar antes da luta final. Fica para depois do piloto aprovado, se a loja da entrada não
bastar.

**Desbloqueio legível:**
- A tenda fechada fica apagada e mostra "Fechado".
- Vencida, mostra a melhor nota.
- Perto dela, mostra "Tecla: entrar".

**O mapa 2D antigo** (`levels/circus_map/`) fica guardado, sem uso. A arte decorativa dele foi suspensa,
e os pedidos de arte do mapa antigo (`codex_mapa.md`) não seguem.

**Revisão de 03/10, à noite (o usuário viu o piloto):** ele REJEITOU a aparência. Os personagens
desenhados no mapa ficaram "horríveis" e o mapa feio. Ele quer miniaturas 3D deles e um acabamento que
surpreenda. Decidido (por delegação):
- **Personagens do mapa = miniaturas 3D** modeladas no Godot (`core/world/miniature.gd`).
  - Bonequinhos pintados: formas arredondadas, cor chapada com sombra em degraus e contorno de tinta.
  - O palhaço baixo e redondo; a acrobata mais alta e esbelta.
  - Andam de verdade: o passo sai da distância andada, sem deslizar; pernas alternadas com joelho;
    braços opostos.
  - Giram suave para onde vão, respiram e piscam parados, e o chapéu ou o coque balança.
- **Cenário = maquete artesanal** (`core/world/world_terrain.gd`, `core/world/world_props.gd`):
  - terreno com relevo e borda que sobe;
  - trilhas curvas de tábuas que se ramificam;
  - arco iluminado na entrada, cercas de corda, postes com lanterna âmbar e varais de bandeirolas;
  - árvores secas, palha, barris e caixotes;
  - cada atração com um marco próprio: jaula do leão no Domador, pinos e bolas gigantes nos
    Malabaristas, estação com trilhos e locomotiva no Trem, tenda grande e cartola gigante no Mágico;
  - a loja é uma barraca de vendedor, com balcão, toldo e prateleiras; o Camarim é um carroção.
- **Luz:** a lua fria contra as lanternas âmbar, névoa leve e sombras macias.
  - O renderizador de compatibilidade não tem oclusão de ambiente. Ela foi trocada por sombras de
    contato embaixo das peças e cantos mais escuros no chão.
  - Mais luzes por objeto (`max_lights_per_object` 16).
- **Placas:** cada atração tem uma placa de madeira pintada num poste, na frente, em vez do nome
  flutuando no alto. O título do parque some depois de 3 s, e os ingressos ficam no canto.
- **O resto é o mesmo de antes:** lutas 2D, entrada andando, espera pelo parceiro online, volta na frente
  da atração, save, loja e Camarim.

**Revisão de 05/10/2026 (reformulação visual, docs/REMAP_VISUAL.md):** o usuário pediu o mapa o mais
perto possível de `docs/referencias/remap/mapa_referencia.png`. Decidido pelo Claude:
- **Cenário pré-renderizado no Blender** (`tools/blender/park_render.py`): o parque inteiro numa imagem
  só, vista de cima por uma câmera ortográfica com a mesma inclinação do mapa, com luz de lampiões,
  varais e luar assada. Junto vai a profundidade de cada pixel; na Godot, `PrerenderedBackdrop` desenha
  a imagem e grava essa profundidade, então os bonecos 3D passam atrás das tendas de verdade.
- A **câmera do mapa é ortográfica** (15,5 m de altura de vista): os bonecos ficam pequenos, como na
  referência. Atrás de uma peça do cenário, o boneco aparece como silhueta dourada (antes a peça ficava
  transparente).
- Chão, colisões, portas, trilhas, entradas das lutas e lugares de volta são os mesmos de antes; o
  terreno e as portas só deixaram de desenhar (`WorldTerrain.draw` e `WorldDoor.draw_landmark`).
- As placas de nome saíram. O aviso da porta é uma plaquinha escura de borda dourada na tela, perto da
  entrada ("J · Entrar", "Fechado", a nota). No canto, "ÁREA 1 — O GRANDE PICADEIRO" e uma plaquinha
  por personagem com o rosto, a vida da luta (3, ou 4 com o Coração de Pano) e os ingressos.
- Nova praça com estátua de elefante no meio do parque, só enfeite.
- Para mudar o parque: `Godot --headless --path . res://tools/world_layout_export.tscn` (leiaute) e
  depois o Blender com `park_render.py -- final` (uns 16 minutos).

**Referência visual** (03/10): `docs/referencias/mundo3d_direcao_visual.png`, conceito do Codex usado como
alvo de linguagem (não captura). Segunda rodada guiada por ela:
- trilhas de terra com grama, cercas de madeira e árvores de copa;
- portão de cabeça de leão no Domador, carroção-loja com toldo e balcão, carroção do Camarim com
  espelho;
- palhaço de quadrados com olhos grandes e sorriso, acrobata com o rosto visível;
- pés plantados por cinemática inversa, medidos no mundo;
- câmera a 42°.

**Terceira rodada** (03/10, à noite):
- **Caminhada medida em movimento real** (`--fixed-fps 60 res://tests/screenshots.tscn -- caminhada`):
  trechos separados de largada, reta, freio, giro e Tab. Na reta, o palhaço dá 2,9 ciclos por segundo e
  a acrobata 2,2 (antes 4 e 3). O pé de apoio se afasta no máximo 0,6 cm do ponto onde pousou. Os piores
  casos são no freio (5,1 cm, palhaço) e no giro (3,1 cm). A velocidade continua 2,4 m/s.
- **Oclusão:** postes, árvores, o arco da entrada, as tendas, a cobertura da estação e o trem ficam meio
  transparentes enquanto a dupla passa atrás deles. A colisão não muda. O poste que tapava a placa do
  Domador saiu de trás dela.
- **Chão:** as facetas em quadrados sumiram (normais suaves). As manchas têm três escalas, e há pedrisco
  na terra. Tufos e pedras ficam em moitas irregulares, com trechos cheios e vazios, mais moitas soltas
  no gramado.
- **Entradas:**
  - A estação do Trem ganhou cobertura de duas águas listrada, relógio, banco, malas, lampiões, faixa na
    beira da plataforma, locomotiva com faixas douradas, limpa-trilhos e fumaça, e um vagão.
  - O teto da loja tem friso e carga.
  - A placa do Mágico aparece inteira, porque a câmera vai mais para o leste.
- **Bordas:** cerca de madeira velha nas quatro beiras, com falhas, o portão no sul e a passagem dos
  trilhos no leste. Tem moitas do lado de fora e, no fundo, fardos, barris e uma roda de carroça. Na beira
  da frente, perto da câmera, só vegetação baixa. As paredes invisíveis vieram para a linha da cerca, e a
  câmera acompanha a dupla até as beiras.
- **Textura do chão:** a primeira encomenda de imagem do mundo é a terra batida (Pedido T1 na fila),
  seguida da grama (T2).

A aprovação é humana: testes passando não aprovam o visual.

### Versão 1.0: escopo fechado (decidido por delegação em 03/10/2026, revisar)

O usuário delegou as decisões de rotina ("tome as melhores decisões ... até quando o jogo
finalizar"). Para "melhorias" não virar crescimento sem fim, a versão 1.0 tem escopo fechado e marcos
verificáveis, nesta ordem. Um marco só começa quando o anterior está conferido.

**Fica de fora em qualquer marco:** git, compras, uso pago e mudanças em segurança ou autenticação.
Nada de promessa de venda ou de publicação.

**M0: mundo 3D navegável da Área 1** (pedido do usuário em 03/10/2026). Um marco só, finito: **trabalho
feito, aguardando a avaliação humana**. A espera não trava o M1.

Situação em 03/10, à noite:
- **Funciona e passa nos testes:** caminho, atrações, loja, Camarim, câmera, entrada e volta das lutas, coop
  sozinho e online, save e teclas.
- **Feito:**
  - miniaturas 3D da dupla com passo plantado, medido em movimento real;
  - diorama em três rodadas: referência do Codex, oclusão, chão, entradas e bordas.
- **Suspenso:** as folhas W1–W8 de andar em direções; as miniaturas ocupam o lugar delas.
- **Falta:**
  - a aprovação visual do usuário (os testes não aprovam);
  - nada mais do trabalho finito: as texturas T1 (terra) e T2 (grama) já estão no jogo (03/10, noite).
- **Fecha o M0:** o usuário aprovar o visual andando no jogo. Até lá, ajustes só pelo que ele apontar.

**M1: movimento e arte da Área 1**
- Fila de arte em `docs/prompts/fila_animacoes_codex.md`.
  - **Já no jogo:** bloco D inteiro (D1, D2, D3, D4b com o eco dourado) e o B6 (rugido em fogo).
  - **Pausada:** MV1, a corrida intermediária da acrobata, depois de 5 tentativas recusadas.
  - **Bloco E em andamento** (03/10, à noite):
    - a E1, folha base dos Malabaristas, está aprovada tecnicamente e normalizada em
      `malabaristas_folha.png`;
    - a E2 (Tico parado malabarizando) veio com a mesma mão no alto nas duas metades. Foi recusada como
      pedida e aproveitada como "chuveiro": a mão da frente sempre joga alto e a de trás passa baixo.
      Está no jogo no parado dos dois irmãos, conferida em piloto a 60 quadros por segundo;
    - acabamento E2b: 4 desenhos intermediários do braço da frente, montados com partes da própria
      E2 (12 desenhos com tempos desiguais), e a clave presa pelo cabo, com um ângulo para cada mão.
      Na fronteira de estado, o maior salto do objeto caiu de 74 para 13,6 px; o da luva desenhada,
      de 77 para 48 px (a mão vazia, depois de soltar). Medido em 3 s;
    - E3: o arremesso (em pé) está no jogo como arremesso por baixo, com os desenhos 4 → 3 → 2. O
      objeto aparece com o desenho de soltura na tela, a 14,3 px da palma, nos dois irmãos. Conferido
      em piloto a 60 quadros por segundo no Troca-Troca e nas Bolas Quicando;
    - E4: o tonto (em pé) está no jogo, um pêndulo de 4 desenhos. A bola de cura pousa no meio da cabeça
      desenhada (`head_position` segue o desenho enquanto ele está tonto; a mecânica não muda). O
      curador volta ao parado depois de soltar. Conferido com a cura de verdade nos dois irmãos;
    - E4b: o pêndulo do tonto ganhou um assentamento (a troca de desenho começa um pouco inclinada em volta
      dos pés). O pulo do nariz caiu de 36 para 29 px, e a ponta do sapato sobe no máximo 8 px;
    - E5: o salto mortal está no jogo. O agachado e as 8 orientações da bolinha são escolhidos pelo giro
      real, e depois vem a aterrissagem. Conferido na Troca de Lugar (orientação nunca para trás, 8
      desenhos por volta);
    - as entradas do totem e do monociclo foram pilotadas com o salto. Quem carrega o irmão (a base do totem
      e do monociclo) fica no boneco de código, porque o desenho do parado punha o de cima na cara dele;
    - E6: a derrota está no jogo. Os dois deitados, com batida, quique, assentando e nocaute a 10 por
      segundo, e o Teco 0,1 s depois, por cima, com os dois rostos à mostra. Conferida na derrota real
      (a tela de fim continua aos 2,3 s);
    - o totem sentado e o monociclo continuam por código (sem pedido);
    - o tonto continua travado (a E4b só divide o pulo, de 20 a 29 px a 8 por segundo). A E4c (4 desenhos do meio)
      foi recusada: o A e o B passavam do ponto, e o pior pulo seria de 35 px. A E4d, desenhada sobre um
      guia visual de "papel de cebola" (`tools/onion_guide.gd`), também foi recusada: só 1 dos 4 desenhos caiu
      no alvo. A E4e (um desenho só, o A, sobre um guia)
      também foi recusada: saiu agachado, com a cabeça 31 px abaixo. O caminho de imagem para o meio do
      pêndulo está encerrado neste ciclo, e o tonto segue com a E4b, um defeito conhecido. Depois do resto do
      Mágico pode haver um piloto híbrido por peças (pés fixos, a parte de cima com curvas), chamado assim,
      sem fingir desenho novo;
    - Mágico: a M1 (folha base) foi aprovada tecnicamente e normalizada em `magico/magico_folha.png`, com as
      peças soltas em `magico/pecas/` (escala 1,0, sem encolher nada). A M2 (parado) está no jogo, conferida
      na luta: só a pose `idle`; as outras continuam o boneco. A M3 e a M3b (varinha: `cast` e `throw`)
      estão no jogo. A mão de lançamento fica a 7 px do alvo; as cartas saem a 4,8 px da palma
      desenhada, sem mudar `hand_position`. A M4 (cartola, pose `tap`) também está no jogo,
      conferida nos Coelhos. A M5 (sumir pela capa, pelo `vanish`) também. A M6 (reverência e medo,
      `bow` e `scared`, em células de 640) também, conferida nas entradas das fases 2 e 3, nas Três Caixas
      e na derrota ainda pequeno; o boneco por código sobra só para os olhos no Blackout. O deslize de
      ~900 px da reverência nas Três Caixas foi corrigido na revisão do marco (ele some no lugar e só muda
      de lugar invisível). O marco de gameplay do Mágico e a revisão dele (abaixo) estão feitos.
      A M7 (mãos gigantes, pelo `closed`, células de 640, pivô no meio do punho) também está no jogo; no
      piloto apareceu e foi corrigida a sobreposição das agarradas (a mão pulava do chão, aberta, com o golpe
      ligado). A M8 (rosto gigante de frente, cartola da M1 como peça girada pelo `hat_tilt`) também está
      no jogo; o Mágico está todo desenhado. Próximo: o piloto híbrido por peças do tonto dos Malabaristas;
    - a avaliação humana fica para a aprovação final do visual e não trava as decisões de rotina do M1.
  - **Malabaristas, decidido por delegação:**
    - no jogo, com uns 230 px;
    - o Teco sai da folha do Tico pelo `tools/recolor_twin.gd` (só as listras mudam de cor);
    - as bolas e as claves são desenhadas pelo jogo.
    - **Totem desenhado (E7, 04/10/2026):** os dois num desenho só, menores que nas outras folhas (decisão do
      usuário: o Totem Andante continua passando por baixo das tábuas, com 214 px no máximo contra 216 do fundo
      da tábua). A base desenha; o de cima fica com as áreas, as estrelas e as bolinhas. Com o Teco embaixo, as
      cores trocam (`recolor_twin.gd` com `troca`). Pilotado com as duas bases (`-- malabaristas_totem`).
      Pedido aberto: a E8 (o monociclo da fase 3, o último boneco de código da luta).
    - **Tonto, piloto por peças (04/10): não viável, a E4b continua.** Nos desenhos 1 e 3 (os extremos do
      pêndulo) a cabeça fica na frente da gola: bigode, língua e bochecha tapam o babado, que não existe por
      baixo. Com a cabeça por cima, deslocá-la abre buraco; com a gola por cima, a gola cortaria o bigode e a
      língua. Toda troca envolve um extremo, então o osso só serviria às cabeças do meio, tirando no máximo
      ~6 px dos 29,1. Preencher a gola seria inventar desenho. Também não dá para cortar o tronco, porque os
      braços ligam os ombros às mãos apoiadas nos joelhos. A E4b (29,1 px no nariz, 8,4 px no sapato)
      continua no jogo como defeito conhecido; para comparar: `tools/ver_malabaristas.bat` com `-- tonto`.
      Evidência: `malabaristas/tonto_osso_cabeca_gola.png`. Próximo defeito do plano: a falha rara do Leque
      no cliente com rede ruim.
    - **Falha rara do Leque no cliente (rede ruim):** causa provável no próprio teste online. A 10c esperava
      qualquer Leque rodando e pegava o fim do anterior. Corrigido: cada seção espera o seu (pela semente).
      O teste ganhou limite de 260 s e nova tentativa de conexão (uma reconexão falhou uma vez). Não
      declarada resolvida; logs em `docs/medidas/magico/logs_falha_rara/`.
  - **O M0 e o M1 são independentes:** o M0 espera só a avaliação humana do mapa, e o trabalho de arte de
    luta do M1 segue sem esperar por ela.
- Toda animação nova é conferida em movimento, com captura a 60 quadros por segundo e com o
  controle. Uma foto da folha não basta.

**Marco de gameplay do Mágico (pedido do usuário em 04/10; mudança de mecânica autorizada; antes da M7):**
- **Leque de Cartas:**
  - **Perseguidora:** cada leque (salva) troca uma carta reta por UMA perseguidora; a densidade não aumenta
    (continuam 4 cartas por leque, com o buraco).
  - **Rosas:** duas por ataque, em leques diferentes. Nunca no buraco nem na perseguidora (sem cor ambígua).
  - **Alvos:** as salvas miram P1, P2, P1... estritamente alternado.
    - O contador fica no chefão durante a luta toda, e não recomeça a cada ataque.
    - P1 é o jogador do slot 0 (o host) e P2 o do slot 1, pela identidade do slot, não pela posição nem pelo
      nome.
    - Sozinho ou com um só de pé: mira só quem está de pé.
    - Ninguém de pé: a carta sai reta.
  - **Aviso:** 0,5 s antes de cada leque, sobre a cabeça do alvo, aparece uma placa "P1" ou "P2" com uma
    carta preta. A perseguidora é uma carta preta com "P1" ou "P2" escrito, distinta da branca e da rosa. O
    preparo (varinha erguida 0,55 s) e os buracos ficam.
  - **Rastreio curto:**
    - sai reta com o leque e começa a virar depois de um atraso;
    - vira com velocidade de giro limitada só por uma janela curta, e depois segue reta;
    - se o alvo cair (balão), sair da luta ou ficar para trás (mais de 120° fora da frente), para de virar e
      segue reta, sem giro de 180° nem órbita;
    - nunca troca de alvo em voo;
    - velocidade, atraso, janela e giro escolhidos por piloto comparativo e registrados.
- **Rede:**
  - O host decide o alvo de cada salva, o sorteio das rosas e da perseguidora (pela semente do ataque) e o
    giro: a cada 0,1 s ele calcula a velocidade de giro do trecho seguinte, com a posição do alvo que ele vê,
    e manda para o cliente.
  - Os dois PCs calculam a trajetória pela mesma conta fechada (arco de giro constante por trecho), a partir
    dos mesmos números.
  - O cliente prevê o trecho que ainda não chegou e corrige quando chega.
  - Dano: cada PC confere o próprio jogador, como hoje. O parry das rosas é o mesmo contrato (`parry_id`).
- **Jogo das Três Caixas:**
  - **O que fica:** a caixa em que ele entra e as trocas já saem da semente do host, nova a cada execução e
    igual nos dois PCs; a caixa certa segue o nó.
  - **Ajuste:** cada troca usa um par diferente do da troca anterior, então nenhuma desfaz a anterior. Com 3
    caixas, isso faz a caixa dele se mexer pelo menos 2 vezes em 5.
  - **Sem mudança:** as trocas continuam em arco, contínuas, com os mesmos tempos e a mesma janela para ver
    ele entrar.
- **Linhas de base (antes de alterar):**
  - **Leque:** 3 leques de 4 cartas retas a 720 px/s, 1 rosa por ataque, nenhuma perseguidora e nenhum alvo.
  - **Três Caixas, em 1000 sementes:**
    - 982 planos distintos;
    - 1341 de 4000 trocas seguidas desfaziam a anterior;
    - a caixa dele se mexia 0 vezes em 4 sementes e 1 vez em 44.
- **Resultado (04/10, tecnicamente pronto; falta o teste humano de "dá para passar"):**
  - **Código:**
    - `card_fan.gd`; `magician_attack.gd` (`launch_homing`, trajetória por conta fechada, giro do host);
    - `card_target_marker.gd` (a placa); `magic_prop.gd` (a carta preta com "P1"/"P2");
    - `MagicianBoss.card_turn` e `next_card_target()`;
    - `Player.slot`;
    - o canal de eventos no meio do ataque (`BossSync.send_attack_event`, `BossAttack.receive_event`, que
      guarda os eventos que chegam antes da ordem do ataque);
    - `shell_game.gd` (trocas);
    - `PlayerInput.scripted` (só para os bots dos testes e pilotos).
  - **Parâmetros escolhidos pelo piloto comparativo:** o conjunto B, com 560 px/s, giro de até 120°/s,
    atraso de 0,2 s e 8 trechos de 0,1 s (0,8 s de rastreio).
    - **Parado:** leva a preta 100% das vezes nos três conjuntos.
    - **Andando sem olhar:** 78% (A), 89% (B) e 100% (C).
    - **Pulo ou dash na hora:** 0% nos três.
    - **Escolha:** o B é o meio: andar não basta, mas o pulo ou o dash na hora escapam.
    - Arquivos: `docs/medidas/magico/gameplay_perseguidoras_*`.
  - **Rosas:** só nas direções que passam na altura do pulo (-10° e 2°; as vizinhas só se o buraco e a preta
    ocuparem as duas).
    - Medido sobre os jogadores: 149–156 px do chão (altura da cabeça) ou 363 px (no alto do pulo).
    - O bot de parry fez 9 parries em 6 ataques, todos com P1 (o P2 fez 0; corrigido na revisão abaixo).
    - A primeira versão sorteava a rosa em qualquer direção, e muitas passavam alto demais ou abaixo do chão
      onde os jogadores ficam.
  - **Testes (`test_magician`):**
    - 9 salvas seguidas P1, P2, P1... atravessando 3 ataques;
    - P2 caído: todas em P1;
    - ninguém de pé: a preta sai reta;
    - o alvo cai em voo: o giro vira 0 dali em diante;
    - o parceiro sai da luta: a carta dele segue reta e a salva seguinte mira quem ficou;
    - dano real da preta no alvo parado;
    - parry na rosa: estoura, some e para de machucar;
    - 12 cartas por ataque (densidade igual), 3 pretas nunca rosa, 2 rosas.
  - **Embaralhar:** 195 planos distintos em 200 sementes, nenhuma troca desfaz a anterior, e a caixa dele se
    mexe 2 ou mais vezes em todas.
  - **Online (normal e ruim):** a mesma caixa e as mesmas trocas, os mesmos alvos (P1 P2 P1), os mesmos giros
    e a mesma trajetória nos dois PCs (diferença de 0,000 px depois de chegarem todos os giros). Quando um giro
    chega atrasado, a preta anda no cliente no máximo 14,6 px a mais num quadro (rede ruim; 0 no host).
  - **Bateria:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.
  - **Limitações:**
    - neste piloto, as pretas acertaram o alvo em 12 de 18 vezes com o bot de parry, e houve contatos no
      parceiro e em retas;
    - os bots não fizeram uma rodada inteira sem nenhum contato (o bot que pula ou dá dash acerta retas);
    - "difícil mas possível" é a leitura dos números, não aprovação: precisa do teste humano;
    - a preta também machuca o parceiro que estiver no caminho;
    - se o aviso do alvo chegar atrasado ao cliente, a placa aparece atrasada nele;
    - a reverência continuava deslizando ~900 px até a caixa (corrigido na revisão abaixo).
- **Revisão do marco (pedido do usuário em 04/10, depois do resultado das 09:27; plano registrado antes de
  mexer):**
  - **Correção dos resumos:**
    - O bot de parry fez 9 parries com P1 e ZERO com P2. Isso prova a oportunidade para P1, não para os dois.
    - As pretas acertaram o alvo em 12 de 18 vezes nesse piloto, e houve contatos no parceiro e em retas.
    - "Difícil mas possível" continua pendente do teste humano.
    - Os 14,6 px de correção (limite de 40 no teste) são informação técnica, não prova de que é justo.
  - **1. Parry e dano de verdade nos dois jogadores:**
    - Descobrir por que o bot do P2 (acrobata) não dá parry e pilotar os dois com o input real de pulo e
      parry (`PlayerInput`, não `register_parry` direto).
    - **Online, rede normal e ruim:** o cliente (acrobata) dá parry numa rosa do Leque com o input real.
      Conferir:
      - a rosa some e para de machucar nos dois PCs;
      - a recompensa conta uma vez;
      - sem parry, a rosa machuca normalmente;
      - como contraste, a preta machucando o cliente sem invencibilidade, contando alvo, parceiro e retas.
    - Medir a correção e o atraso do aviso no cliente nesses casos.
    - O teste 10b (invencível, compara a fórmula) fica como está.
  - **2. Saída de verdade durante o rastreio:**
    - Pelo `Network.leave()` do cliente (P2) enquanto a preta o segue.
    - **No host:** ela termina o rastreio sem virar para P1; a salva seguinte mira P1; o slot e o contador
      continuam.
    - **No cliente que saiu:** registrar o que acontece com as cartas e a partida, e depois voltar à luta.
  - **3. Três Caixas sem deslize (coreografia escolhida antes de mexer):**
    - **0 a 0,25 s:** só a caixa em que ele vai entrar abre a tampa; ele faz a reverência no lugar, sem
      andar. A tampa aberta é a pista.
    - **0,25 a 0,5 s:** ele some no lugar pela capa (M5, `vanish` de 0 a 1), com a fumaça do jogo.
    - **0,5 a 0,75 s:** totalmente invisível, vai para a caixa.
    - **0,75 a 0,9 s:** a fumaça sai da caixa aberta e a tampa fecha com um tranco.
    - **Tempos mantidos:** STEP_IN 0,9, SHUFFLE 1,2, trocas de 0,45, GUESS 3,6 e REVEAL 0,9.
    - **Na revelação:**
      - a caixa certa (pela identidade) abre;
      - ele desenrola da capa ali (M5 de trás para a frente, `vanish` de 1 a 0 em 0,25 s) e então faz a
        reverência;
      - o `set_present` volta no mesmo instante de antes (a janela de dano não muda).
    - **Comparar com as linhas de base:**
      - 885 a 912 px de deslize em reverência e mais ~93 px sumindo (piloto da M6);
      - o salto de 242,5 px no alto do desenho ao reaparecer (sumir4 → rev1).
  - **Resultado da revisão (04/10):**
    - **Três Caixas sem deslize** (`shell_game.gd`):
      - **Primeira versão (falha):** ele sumia no lugar, sem aparecer na caixa. Quando começava parado na
        frente de outra caixa (onde a rodada anterior terminou), sumir ali enganava.
      - **Versão final:** reverência no lugar com só a tampa da caixa dele abrindo (0 a 0,2 s); some pela
        capa no lugar (0,2 a 0,4 s); invisível, vai até a caixa, aparece enrolado na capa na frente da tampa
        aberta (0,4 a 0,75 s); afunda, e a tampa fecha com um tranco (até 0,9 s).
      - **Revelação:** ele desenrola da capa na caixa certa (M5 ao contrário, 0,25 s) e então faz a
        reverência.
      - **Tempos:** STEP_IN, SHUFFLE, trocas, GUESS e REVEAL mantidos; o `set_present` no mesmo tempo.
      - **Defeito antigo achado e corrigido:** no embaralhar o `vanish` ficava em ~0,96, uma cartola quase
        transparente no lugar de entrada. Agora fica em 1.
      - **Piloto, 4 rodadas, os dois lados:**
        - andou à vista: 0,0 px (antes, 885–912 px em reverência mais ~93 px sumindo);
        - antes do embaralhar, só a tampa da caixa dele abriu;
        - na revelação, sumir1 → rev1 salta 5,4 px (antes, 242,5 px de sumir4 → rev1);
        - o maior salto (180,7 px) é a própria troca da cartola para a coluna do sumir da M5, igual à do
          Teleporte.
      - **Testes:** o `test_magician` cobre "sem deslize, só a tampa dele, aparece na frente da caixa,
        escondido de vez, desenrola na certa". O `test_online` 10e cobre o mesmo nos dois PCs, com rede
        normal e ruim.
    - **Parry e dano reais:**
      - **Bot do P2:** pulava cedo para a rosa baixa e, depois do 1º pulo, ficava em cima do trapézio (x 480,
        240 px acima do chão), de onde as rosas passam por baixo.
      - **Bot corrigido:** altura medida a partir dos pés, pulo curto e tarde para a rosa baixa, parry a
        menos de 110 px e descida do trapézio.
      - **Piloto, 6 ataques:**
        - só o P1 tentando: 11 parries;
        - só o P2 tentando: 11 parries;
        - os dois: a rosa estoura no primeiro da fila (P2 11, P1 0).
      - **Online 10c (normal e ruim):**
        - **Parry:** o cliente (P2) deu 2 parries com o input real; as duas rosas estouraram e ficaram
          inativas também no host. A recompensa conta uma vez: +2 estrelas no cliente, e o host conta os
          mesmos 2 parries do parceiro.
        - **Dano sem invencibilidade:** a preta encostou 2 vezes em cada jogador (vida 10 → 9, por causa da
          invencibilidade depois do golpe).
        - **Aviso do alvo no cliente:** até 0,021 s de atraso na rede normal e até 0,103 s na ruim (a placa
          aparece ~0,4 s antes do leque, não 0,5).
        - **Correção da preta no cliente:** 0,2 px na normal e 15,5 px na ruim.
      - **Teste local:** a rosa machuca sem parry (3 → 2).
    - **Saída de verdade (10d, normal e ruim):** o cliente sai pelo "Sair" do menu de pausa enquanto a preta
      o segue.
      - **No host:** ela para de virar (os giros depois da saída são 0, sem virar para o P1); as salvas
        seguintes miram P1 ([1, 0, 0]); o contador segue até 4.
      - **No cliente:** volta ao menu principal e as cartas somem (0 objetos); depois ele volta à luta.
      - A primeira tentativa usava só `Network.leave()`, e a cena do cliente ficava aberta. O jogo de
        verdade sai pelo menu.
    - **Evidências:** `docs/medidas/magico/revisao_*` e `logs_revisao/`, com o log da falha 99 da porta
      ocupada.
    - **Bateria depois da revisão:** 9 testes locais com 0 falhas, e o online normal e com rede ruim ok.
    - **Continua pendente:** "difícil mas possível" precisa do teste humano. Os bots não provam justiça; os
      14,6–15,5 px de correção e o limite de 40 do teste são informação técnica.

**M2: estabilidade e acabamento**
- Online com internet ruim sem falhas intermitentes. A primeira causa real foi corrigida em 03/10.
- Menus e telas revisados, tutorial curto do controle e opções de acessibilidade básicas.

**M3: som**
- Hoje o jogo não tem nenhum som.
- Efeitos de tiro, pulo, parry, acerto e chefões, e música de circo dos anos 30.
- Tudo gratuito, gerado ou de domínio público, com a licença registrada.

**M4: design da Área 2, só no papel**
- Tema, 3 chefões e uma fase de plataforma, no mesmo nível de detalhe de `docs/bosses.md`.
- Nenhum código antes do design fechado.

**M5: Área 2**, implementada etapa por etapa, como a Área 1.

**M6: final**
- Chefão final, encerramento da história e créditos.
- Revisão geral de dificuldade com as notas de quem jogou.

## Banco de ideias

- Reviver o parceiro pegando o "fantasma" dele antes que suba para fora da tela.
- Chefão com escudo que um jogador precisa distrair enquanto o outro atinge o ponto fraco.
- Ataques que pedem dois parries ao mesmo tempo (com janela de tolerância).
- Arena que muda entre as fases do chefão.
- Nota/rank no final de cada luta (tempo, dano recebido, parries).
- Loja de armas e amuletos entre as lutas.
