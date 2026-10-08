# Respeitável Público — proposta de identidade (versão do Claude)

07/10/2026. Proposta para discussão, ainda não é decisão. Nada no jogo foi alterado por este documento.

**Situação atual — descartada pelo usuário em 07/10/2026.** O usuário decidiu continuar com a base atual do jogo e concentrar as mudanças nos chefões para dar a eles identidade própria. Esta reformulação de Truque, teatro de papel, arenas, kit básico e história fica somente como registro de uma ideia anterior; não iniciar sua implementação. Preservar as melhorias já integradas e a direção aprovada do Gabinete Sem Fundo para o Mágico, com dificuldade e controles atuais como referência.

## A ideia em uma frase

**Dois artistas presos num espetáculo amaldiçoado que se repete toda noite, e que só termina quando eles improvisam o que o roteiro não previa.**

O jogo continua sendo luta contra chefões em câmera lateral, com tiro, pulo, dash, controle responsivo e cooperação online. O que muda é o que faz o jogo parecer Cuphead: o parry, o visual de desenho animado antigo e a arena parada onde só se atira até o chefão cair.

## Por que manter a câmera lateral

- Todo o código atual (jogador, rede, chefões, loja, save, mapa, trem) continua servindo.
- Gênero e mecânicas não têm dono: o risco legal de parecer Cuphead é baixo. O problema é a primeira impressão de "clone".
- A primeira impressão vem de três sinais: parry, visual e estrutura da luta. Mudando esses três com força, o jogo passa a ser "inspirado em", e não "cópia de".

O que já foi feito nessa direção continua valendo: parry turquesa, resgate encostando no balão, crítica da plateia no lugar da nota, bilhetes no lugar de cartas e "Picadeiro conquistado!".

## 1. Visual: teatro de papel

Trocar o desenho animado dos anos 30 por **teatro de papel**: o teatrinho de brinquedo antigo, em que tudo é recortado em papelão pintado, preso em varetas e movido por cordas.

- **Combina com a tecnologia que o jogo já usa.** Os personagens já são montados em peças separadas e animados por esqueleto (cutout). Num desenho animado isso parece "barato"; num teatro de papel, a peça articulada é exatamente o estilo.
- **Cenário em camadas:** fundos pintados que sobem e descem por cordas, coxias dos lados, ribalta (fileira de luzes) embaixo, cortina no alto da tela.
- **Personagens:** contorno de papel recortado, sombra projetada leve atrás de cada peça e textura de papel/papelão. Sem braços de borracha (rubber hose); as articulações aparecem como colchetes de papel (os "pinos" que prendem as peças).
- **Filme antigo:** grão, sépia e tremido deixam de ser o padrão. O filtro pode ficar como opção nas Configurações.
- **Prioridade da arte:** silhuetas fortes e ataques legíveis. Os ataques do chefão continuam em laranja/magenta e os adereços em turquesa.

## 2. Combate: Truque no lugar do parry

O parry sai do papel central. Entra o **Truque**: pegar um adereço turquesa, ficar com ele na mão e usá-lo ou passá-lo ao parceiro.

**Como funciona:**

1. Alguns ataques soltam um adereço turquesa (poucos de cada vez, nunca uma chuva deles).
2. O botão Truque perto de um adereço, no chão ou no ar, faz o personagem **pegar**. A janela de contato é generosa.
3. Com o adereço na mão, o personagem continua andando, pulando, atirando e dando dash. O adereço aparece **na mão dele**, com pose própria. É isso que separa o Truque do parry: no parry você encosta e acabou; aqui você carrega o objeto.
4. Apertar Truque de novo **lança** o adereço na direção para onde o personagem mira. Se o parceiro estiver perto da linha de lançamento, o adereço vai para ele (com tolerância grande, sem precisar acertar o pixel).
5. **Posse curta:** depois de uns 4 segundos o adereço começa a piscar e cai da mão. Isso impede guardar o objeto esperando o momento perfeito.

**O que o adereço faz:** cada chefão tem um ou dois alvos de palco onde o adereço lançado tem um efeito visível e físico: atordoar, abrir uma proteção, travar um mecanismo, devolver um ataque. Não é um multiplicador de dano invisível.

**Passar ao parceiro vale mais:** o mesmo adereço, finalizado por quem recebeu o passe, tem um efeito maior ou diferente (dura mais, pega uma área maior ou abre uma janela extra). Usar sozinho funciona e é bom; passar é melhor.

**A estrela continua:** pegar um adereço dá estrela de Aplauso, como o parry dá hoje. O quique do parry só sai depois de conferir que nenhuma fase depende dele para alcançar plataformas.

**Rede:** o host decide quem pegou o adereço. Quem aperta Truque vê o objeto na mão na hora (predição); se o host disser que o outro pegou primeiro, o objeto passa para ele com uma animação curta de "escapuliu". Em caso de empate dentro da janela, vence quem está mais perto. O lançamento é determinístico (posição, direção e tempo), então cada PC simula o voo sem sincronizar quadro a quadro.

## 3. Luta: o palco muda durante o número

No Cuphead, a arena é um cenário parado. Aqui cada luta é **um número em atos**:

- **Troca de ato à vista:** entre as fases da luta, a cortina desce até a metade, fundos de papel trocam por cordas, peças do cenário entram e saem. Dura uns 2 a 3 segundos, sem tirar o controle dos jogadores.
- **Mecanismos de palco** que o chefão e os jogadores usam: alçapões, contrapesos, holofotes, cortinas, cordas. Os adereços lançados ativam esses mecanismos.
- **Plateia visível:** uma fileira de fantasmas da plateia em silhueta, embaixo da tela, que reage ao que acontece (vaia quando alguém cai, ovação num número em dupla). É a crítica da plateia acontecendo ao vivo, não só no fim.

## 4. Cooperação desde a primeira luta

- **Passe de adereço** e **impulso no parceiro** (pular no parceiro para ganhar altura, uma versão básica da Catapulta) fazem parte do kit desde o início, sem comprar.
- O Camarim passa a vender **variações** desses números (como o passe viaja, o que o impulso faz), não a possibilidade de cooperar.
- Itens já comprados que virarem básicos devolvem os ingressos no save. Nada some sem compensação.
- Sozinho, tudo continua jogável: o adereço pode ser usado direto e o impulso simplesmente não existe.

## 5. Chefões: um uso de palco memorável por luta

Cada chefão ganha **um** jeito principal de usar adereços, fácil de entender, que aparece várias vezes na luta. As fases e os ataques atuais continuam; muda a origem de alguns objetos turquesa e o que eles fazem.

| Atração | Adereço | Uso direto | Com passe |
|---|---|---|---|
| Domador e Leopoldo | **Banquinho de domador**: o domador derruba quando foge para o pedestal | Lançado em Leopoldo, o leão recua e fica parado por 1 s | Quem está de isca recebe o banquinho e segura Leopoldo encurralado contra a parede; o parceiro bate pelas costas (dano dobrado, que já existe) |
| Irmãos Malabaristas | **Bola de cura**, pega no ar em vez de estourada | A cura não chega e o irmão continua tonto | Devolvida ao irmão que ia receber, ele se atrapalha e deixa cair todos os malabares por uns segundos: os arremessos dele param |
| Zaratan (Gabinete Sem Fundo) | **Bilhete carimbado** que sai do carimbo | Encaixado na fresta de um compartimento, a gaveta fica aberta e expõe o ponto fraco | Finalizado pelo parceiro, a gaveta também para de soltar ataques por uma janela curta |
| Trem do Circo | **Lanterna** no vagão das Sombras | Lançada adiante, ilumina um trecho e os tiros param de atravessar os fantasmas | Passada ao parceiro, ele leva a luz enquanto o outro atira livre |

Cuidado ao calibrar: nenhum desses usos pode deixar o chefão invulnerável esperando o mecanismo, nem trivial. O tiro comum sempre causa dano; o Truque é a rota mais expressiva.

## 6. História

O Mestre de Cerimônias prometeu um espetáculo que ninguém jamais esqueceria, e a promessa virou maldição: o espetáculo se repete toda noite, igualzinho, e nunca chega ao fim. Artistas e plateia viraram fantasmas presos aos próprios papéis.

O Palhaço e a Acrobata são os únicos que conseguem **sair do roteiro**. Cada atração vencida é um número que finalmente termina diferente: o artista é libertado, volta ao acampamento da trupe e passa a ajudar (conversa, loja, dicas). O circo no mapa muda a cada vitória.

Isso amarra história e mecânica: improvisar, com o Truque e os números em dupla, é literalmente o que quebra a maldição. Substitui a ideia do pacto, que ainda não estava detalhada. O Mestre de Cerimônias continua sendo o chefão final.

## 7. O que não mudar agora

- Armas: Rolha, Clave, Confete e Bolha ficam como estão até o Truque estar provado.
- Economia de ingressos, save e dificuldade: sem mexer no piloto, para dar para comparar com a versão atual.
- Não adicionar parceiro de IA, inventário ou menus durante a luta.

## Ordem sugerida

1. **Piloto do Truque** num ataque do Zaratan: pegar, segurar, lançar, passar e finalizar, com arte provisória, testado **online** desde o primeiro dia.
2. **Avaliar jogando:** ficou divertido? Dá para entender? Os controles cabem? Ajustar antes de produzir arte.
3. **Luta completa do Zaratan** com o Gabinete Sem Fundo, o Truque e a troca de ato.
4. **Teste de visual:** uma arena e um personagem no estilo teatro de papel, para comparar com o atual.
5. **Kit básico de dupla** (passe e impulso) e migração das compras no save.
6. **Domador, Malabaristas e Trem** recebem o seu uso de palco, um por vez.
7. **Plateia ao vivo, história e mapa que muda com as vitórias.**
