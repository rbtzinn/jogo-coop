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
| Paleta | Contorno `#1b1410`. Fundo escuro e dessaturado (vermelho `#4f1f1f`, creme `#6f5d47`, noite `#2a1f2e`) para os personagens saturados se destacarem. Tiros do jogador: **branco + ciano `#5fe3ff` com contorno escuro**, legíveis sobre qualquer fundo. Reservado para o futuro: ataques do chefão em laranja/magenta, objetos de parry em rosa `#ff5fa2` |
| Arte | **Arte atual é provisória (mas caprichada):** o usuário pretende fazer a arte final com outra IA e só mantém a do Claude se gostar. Por isso a arte precisa ser **fácil de trocar**: cada personagem é uma cena com peças separadas (cabeça, piscar, tronco, sapatos, mãos) e pontos de encaixe (ombros, quadris, pescoço, cano da arma); a arte nova só precisa respeitar essas peças e pivôs. Desde 02/10/2026: peças ilustradas em **PNG com transparência** recortadas das folhas geradas por IA (escala uniforme, resolução 2x), detalhes em [personagens-visuais.md](personagens-visuais.md). Os SVGs anteriores continuam na pasta, sem uso. As cenas continuam animadas pelo mesmo código (`CharacterRig`): corrida, pulo, dash, mira, recuo do tiro, aterrissagem, piscar. Braços e pernas "de mangueira" (rubber hose) desenhados por código |
| Configurações | Menu de pausa (Esc / Start) com **Configurações** salvas em `user://settings.cfg`. **Controles:** toda ação pode ser trocada (2 teclas + 2 botões de controle por ação). **Vídeo:** qualidade gráfica (Baixa/Média/Alta), modo de tela, tamanho da janela, limite de FPS, VSync, mostrar FPS. Qualidade Baixa desliga o filtro de filme e as partículas |
| Dependência entre jogadores | **Base Cuphead + momentos de dupla.** Cada jogador luta de forma independente, com vida própria, e pode reviver o parceiro; se os dois caírem, a luta acaba. Alguns chefões têm fases ou ataques que exigem coordenação (distrair/atacar, parry duplo com janela de tolerância), mas nem todos |
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
   - **4c — Parry, reviver e Aplausos**. Feito: parry (pular de novo no ar encostando no rosa: quica, gira, 0,35 s protegido, +1 estrela, o objeto estoura nos dois PCs); balão de reviver (caído vira balão rosa com a própria cara, sobe ~6 s; parry do parceiro revive com 1 PV e 2 s invencível; se sair pela tela, fica fora); estrelas de Aplauso no ingresso (enchem com dano: 45 de dano = 1 estrela, e com parry). **Parte 2 (03/10/2026):** botão **Especial** (rebindável: I / V / Y), **Tiro EX** "Rolhão" (1 estrela), **Grande Número** (5 estrelas: "Torta na Cara" e "Salto Mortal"), **Número Perfeito** e **Grande Número em Dupla** (Torta de Ouro), tudo também online; mais ataques rosa no Domador (onda rosa na Chicotada, onda rosa na Patada, brasas rosa nos Pulos). Detalhes e números em docs/combat.md. Testes automáticos em `tests/`. ✔ concluída (testada pelos testes automáticos; falta o teste do usuário)
   - **4d — Nota e save** (03/10/2026): nota C/B/A/S no cartaz de vitória (regras em docs/combat.md) e save automático ao vencer, em `user://save.json` no PC do host (no "Testar sozinho", no próprio PC): chefões vencidos com melhor nota e melhor tempo, área atual e, para cada jogador, ingressos, itens e equipamento (começa com Rolha e Cambalhota). Ingressos como em docs/shop.md: 3 na 1ª vitória, +1 na 1ª nota A ou melhor, +1 na 1ª S. O save ainda não é usado por nenhuma tela (o mapa e a loja vêm na etapa 5). ✔ concluída (testes automáticos; falta o teste do usuário)
   - **4e — Acabamento online** (03/10/2026): quem sai da partida avisa o outro PC na hora (antes o host só percebia depois de vários segundos); o parceiro que cai e volta no meio da luta recebe do host a fase e a vida atuais do chefão (antes voltava na fase 1 com vida cheia); no fim da luta online o cliente espera o host mandar o resultado (com a nota). Teste online automático com dois processos sem janela (`sh tests/run_online.sh`, também com internet ruim simulada): Especial, Número Perfeito, Grande Número em Dupla, vitória com nota, "Tentar de novo", queda e volta do parceiro, balão e reviver. ✔ concluída (testes automáticos; falta o teste do usuário com o parceiro)

### Arte em andamento (02/10/2026)

- O usuário gera a arte com ChatGPT/Codex em paralelo; o Claude escreve os prompts (em `docs/prompts/`) e encaixa as folhas no jogo com `tools/cut_animation_sheet.gd` (e `tools/normalize_sheet.gd` quando a folha não respeita a grade). Detalhes em [personagens-visuais.md](personagens-visuais.md).
- **No jogo:** corrida desenhada do palhaço e da acrobata (o resto dos personagens ainda é de peças animadas por código); Leopoldo inteiro desenhado (parado, rugido, galope, pulo).
- **Pedidos pendentes** (o usuário avisa quando chegarem): Pedido 3 do leão (`docs/prompts/codex_leao.md`: salto completo de 8 quadros e versões com juba de fogo, que substituem as chamas provisórias) e parry, balão e especiais dos personagens (`docs/prompts/codex_parry_balao_especiais.md`: cambalhota desenhada no lugar do desenho girando, balão com transformação/flutuar/vento/resgate, Torta na Cara, torta, Salto Mortal e chute da torta em dupla). Depois: pulo, dash, abaixado, parado e dano dos personagens, e a arte do Domador (ainda SVG provisório).
- **Regras de arte (pedido do usuário):** nada de desenho parado deslizando pela tela (cada movimento com quadros próprios + "suco" no código) e **expressões faciais diferentes em cada quadro** em todos os pedidos novos (sem refazer os antigos).
- Ideia aprovada para depois: juba/cauda em camada separada com um shader de vento.

5. **Primeira área**: mapa de seleção + 2–3 chefões + uma fase de plataforma. Dividida em partes (decidido pelo Claude em 03/10/2026, revisar):
   - **5a — Mapa do parque** (03/10/2026): "O Grande Picadeiro", uma tela lateral com o parque à noite e uma tenda para cada número: Domador, Malabaristas, Trem do Circo, Grande Mágico (fechado até vencer os outros três) e a Barraca de Curiosidades (loja). Os dois andam sem atirar; **Atirar na frente da tenda entra** (a dica mostra a tecla). Tendas de fases que ainda não existem mostram "Em breve". A tenda mostra a melhor nota da dupla. O menu ("Hospedar" e "Testar sozinho") abre o mapa; o cartaz de fim de luta ganhou "Voltar ao mapa"; ao chegar no mapa o host salva. Online, qualquer um dos dois escolhe a tenda e o host leva os dois; quem entra na partida cai direto na fase em que o host está; o host manda uma cópia do save para o cliente ver notas e ingressos. Arte provisória por código; pedido de arte em `docs/prompts/codex_mapa.md`. ✔ concluída (testes automáticos)
   - **5b — Os Irmãos Malabaristas** (docs/bosses.md).
   - **5c — Corrida no Trem do Circo** (fase de plataforma).
   - **5d — O Grande Mágico** (fecha a área).
   - **5e — Loja e Camarim** (docs/shop.md).
6. Áreas seguintes, um chefão de cada vez.

## Banco de ideias

- Reviver o parceiro pegando o "fantasma" dele antes que suba para fora da tela.
- Chefão com escudo que um jogador precisa distrair enquanto o outro atinge o ponto fraco.
- Ataques que pedem dois parries ao mesmo tempo (com janela de tolerância).
- Arena que muda entre as fases do chefão.
- Nota/rank no final de cada luta (tempo, dano recebido, parries).
- Loja de armas e amuletos entre as lutas.
