# Documento de Design — Respeitável Público

> Documento vivo. Atualizar sempre que uma decisão for tomada.

## Documentos detalhados

- [combat.md](combat.md) — vida, balão (reviver), parry, especial (Aplausos), nota
- [shop.md](shop.md) — loja, ingressos, Camarim e todos os itens
- [bosses.md](bosses.md) — chefões da Área 1 e ideias futuras

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
| Conexão (desenvolvimento) | **Tailscale** ou IP direto (sem custo) |
| Steam | **Não agora.** Código preparado para adicionar Steam no futuro sem refazer |
| Save | Arquivo local no PC do host: chefões vencidos, área atual, upgrades/equipamentos de cada jogador |
| Assets | Gratuitos (Kenney, itch.io, OpenGameArt) como base/placeholder. Higgsfield (conta free, ~10 créditos) só para artes pontuais, ex. capa ou retrato de chefão |
| Custo | **Zero.** Distribuição entre os dois via executável ou itch.io (privado). Venda: decisão para depois da primeira área pronta |
| Produção | Por partes: um chefão de cada vez |
| Estilo visual | **Cartoon dos anos 30, recortado (cutout)**. Personagens e chefões montados em peças separadas (cabeça, tronco, membros) e animados por esqueleto (`Skeleton2D`/`Bone2D`) e tweens/`AnimationPlayer` na Godot, sem animação quadro a quadro. Shader de filme antigo por cima (grão, vinheta, leve tremido, cor desbotada). Os ataques precisam continuar bem legíveis sob o filtro |
| Tema | **Circo assombrado**, estilo anos 30. Os dois jogadores são artistas de circo que enfrentam as atrações de um circo amaldiçoado; cada atração é um chefão (ex.: domador, palhaço, mágico) |
| Personagens | **Jogador 1: palhaço** baixinho e redondo (roupa arlequim vermelho/creme, nariz vermelho, cartolinha com margarida). **Jogador 2: acrobata** alta e magra (collant azul-petróleo com estrelas douradas, coque). Silhuetas opostas para distinguir na hora no co-op. Os dois atiram com **pistolas de rolha**. Mesma caixa de colisão para os dois (jogabilidade idêntica) |
| Paleta | Contorno `#1b1410`. Fundo escuro e dessaturado (vermelho `#4f1f1f`, creme `#6f5d47`, noite `#2a1f2e`) para os personagens saturados se destacarem. Tiros do jogador: **branco + ciano `#5fe3ff` com contorno escuro**, legíveis sobre qualquer fundo. Reservado para o futuro: ataques do chefão em laranja/magenta, objetos de parry em rosa `#ff5fa2` |
| Arte | **Arte atual é provisória (mas caprichada):** o usuário pretende fazer a arte final com outra IA e só mantém a do Claude se gostar. Por isso a arte precisa ser **fácil de trocar**: cada personagem é uma cena com peças separadas (cabeça, piscar, tronco, sapatos, mãos) e pontos de encaixe (ombros, quadris, pescoço, cano da arma); a arte nova só precisa respeitar essas peças e pivôs. Hoje: peças em **SVG** escritas à mão pelo Claude (nítidas em qualquer resolução), montadas em cena e animadas por código (`CharacterRig`): corrida, pulo, dash, mira, recuo do tiro, aterrissagem, piscar. Braços e pernas "de mangueira" (rubber hose) desenhados por código |
| Configurações | Menu de pausa (Esc / Start) com **Configurações** salvas em `user://settings.cfg`. **Controles:** toda ação pode ser trocada (2 teclas + 2 botões de controle por ação). **Vídeo:** qualidade gráfica (Baixa/Média/Alta), modo de tela, tamanho da janela, limite de FPS, VSync, mostrar FPS. Qualidade Baixa desliga o filtro de filme e as partículas |
| Dependência entre jogadores | **Base Cuphead + momentos de dupla.** Cada jogador luta de forma independente, com vida própria, e pode reviver o parceiro; se os dois caírem, a luta acaba. Alguns chefões têm fases ou ataques que exigem coordenação (distrair/atacar, parry duplo com janela de tolerância), mas nem todos |
| Mecânicas do jogador | Ver seção "Mecânicas do jogador" abaixo |
| Hardware | Jogador 1 (desenvolve e joga no mesmo PC): **Intel UHD Graphics 630 integrada**, i5-8500T, 16 GB RAM. Jogador 2: placa de vídeo dedicada (modelo a confirmar). O PC mais fraco é a referência |
| Renderizador | **Compatibility (OpenGL)** da Godot 4: roda bem em vídeo integrado e cobre tudo que o 2D precisa (shaders, pós-processamento). Meta: **60 FPS estáveis no PC do jogador 1**. Efeitos pesados (muitas partículas, blur grande) devem ter opção de desligar |

### Mecânicas do jogador

| Mecânica | Detalhes | Entra em |
|---|---|---|
| Andar | Aceleração rápida, sem "patinar" | Etapa 2 |
| Pulo | Altura variável (segurar = mais alto), coyote time, buffer de pulo | Etapa 2 |
| Tiro | 8 direções; botão para travar posição e só mirar | Etapa 2 |
| Dash | Avanço rápido no chão e no ar, para desviar | Etapa 2 |
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

No chão, sem travar a mira, apertar para baixo não mira para baixo (reservado para agachar no futuro).

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

1. ~~**Estilo visual**~~ — decidido (ver tabela acima).
2. ~~**Tema**~~ — decidido: circo assombrado. **Ainda a detalhar** (pode ser depois da etapa 2): nome dos dois artistas, por que o circo foi amaldiçoado, como as áreas se dividem (ex.: tendas, picadeiros, trem do circo).
3. ~~**Quanto um depende do outro**~~ — decidido (ver tabela acima).
4. ~~**Mecânicas do jogador**~~ — decidido (ver seção acima).
5. ~~**Hardware**~~ — decidido (ver tabela acima).
6. ~~**Nome do jogo**~~ — decidido: **Respeitável Público**.

## Roadmap

1. **Conceito** — fechar as decisões em aberto acima. ✔ concluída
2. **Base jogável** — dois jogadores pulando e atirando no mesmo cenário, conectados online (host/cliente), com predição e interpolação. Controle precisa ficar gostoso aqui.
   - **2a — Controle local**: um jogador anda, pula, dá dash e atira em 8 direções numa arena de teste. Inclui (a pedido, adiantando parte da etapa 3): personagens desenhados e animados, arena de circo, filtro de filme antigo, efeitos e menu de Configurações. ← *estamos aqui*
   - **2b — Conexão**: tela de "Hospedar" / "Entrar por IP"; dois jogadores na mesma arena.
   - **2c — Rede de verdade**: predição do jogador local, interpolação do remoto, teste via Tailscale.
3. **Visual base** — shaders, pós-processamento, "cara" do jogo. (Parte já adiantada na 2a; aqui entra o refinamento.)
4. **Primeiro chefão** completo (com todas as fases da luta), tela de vitória/derrota e save.
5. **Primeira área**: mapa de seleção + 2–3 chefões + uma fase de plataforma.
6. Áreas seguintes, um chefão de cada vez.

## Banco de ideias

- Reviver o parceiro pegando o "fantasma" dele antes que suba para fora da tela.
- Chefão com escudo que um jogador precisa distrair enquanto o outro atinge o ponto fraco.
- Ataques que pedem dois parries ao mesmo tempo (com janela de tolerância).
- Arena que muda entre as fases do chefão.
- Nota/rank no final de cada luta (tempo, dano recebido, parries).
- Loja de armas e amuletos entre as lutas.
