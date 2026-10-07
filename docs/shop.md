# Loja — A Barraca de Curiosidades

> Parte do [DESIGN.md](DESIGN.md). Aprovado pelo usuário em 01/10/2026; números (dano, tempos, preços) serão calibrados nos testes.

## O lugar e o lojista

Uma barraca de curiosidades no parque do circo (mapa de seleção). Quem atende é um **boneco de ventríloquo assombrado** que fala sozinho, sem nenhum ventríloquo por perto, e às vezes discute com o "dono" que não está lá. Falas em `dialogues/`.

## Ingressos (moeda)

Quantidade **limitada**, por jogador (os dois ganham o mesmo):

| Como | Ingressos |
|---|---|
| 1ª vitória contra um chefão | 3 |
| 1ª vez com nota A ou melhor naquele chefão | +1 |
| 1ª vez com nota S naquele chefão | +1 |
| Escondidos em cada fase de plataforma | 3 |

Na **Área 1** (3 chefões + 1 fase de plataforma) cada jogador pode juntar até **18 ingressos**. A loja da Área 1 custa mais que isso no total, então é preciso **escolher**. A loja ganha itens novos a cada área.

## Como comprar

1. No mapa, o jogador anda até a barraca e aperta **pular/confirmar**.
2. Abre o painel da loja **só na tela de quem entrou**: os itens ficam numa prateleira, com nome, preço, descrição e uma prévia animada.
3. Comprar pede confirmação ("Levar por 4 ingressos?"). O item vai para a mala do jogador.
4. Botão **"Dar ingressos ao parceiro"**: escolhe a quantidade e confirma.
5. No online, o **host valida** cada compra e salva (o save fica no PC do host).

## Equipar: o Camarim

Itens comprados são equipados no **Camarim**, que abre pelo menu de pausa **apenas no mapa** (não no meio da luta). Cada jogador tem **4 espaços**:

**Pistola · Truque · Adereço · Número de dupla**

Começa com: **Rolha** (pistola) e **Cambalhota** (truque). Adereço e Número de dupla começam vazios.

## Itens da Área 1 (aprovados; preços e efeitos serão calibrados nos testes)

### Pistolas (tiro normal + Tiro EX)

| Item | Preço | Tiro normal | Tiro EX (1 estrela) |
|---|---|---|---|
| **Rolha** | inicial | Reto e rápido, dano médio, alcance total | **Rolhão:** rolha gigante que atravessa o chefão acertando várias vezes |
| **Leque de Confete** | 4 | 3 confetes em leque, **alcance curto**, muito dano de perto | **Canhão de Confete:** explosão em volta do personagem |
| **Clave de Malabares** | 4 | Clave lenta que **vai e volta** (pode acertar duas vezes) | **Chuva de Claves:** 5 claves caem em arco à frente |
| **Bolha de Sabão** | 4 | Bolhas **teleguiadas**, dano baixo; boa para quem quer focar em desviar | **Bolhona:** bolha grande que estoura em área ao tocar o chefão |

### Truques (mudam o dash)

| Item | Preço | Efeito | Troca |
|---|---|---|---|
| **Cambalhota** | inicial | Dash normal | — |
| **Fumaça do Mágico** | 3 | Some numa nuvem de fumaça e reaparece à frente, **invencível**. Deixa um **boneco de fumaça** no lugar que atrai os ataques teleguiados do chefão por 1 s | Distância 25% menor |
| **Bala de Canhão** | 3 | O dash **causa dano** no que atravessar | Sem invencibilidade |
| **Pirueta** | 3 | Dash em **8 direções** (inclusive para cima) | Só 1 por pulo, mesmo no chão espera recarregar |

### Adereços (passivos)

| Item | Preço | Efeito | Troca |
|---|---|---|---|
| **Coração de Pano** | 6 | **+1 PV** | As estrelas de Aplauso enchem 15% mais devagar (até 06/10/2026: tiro 5% mais fraco, igual a um item do Cuphead) |
| **Nariz de Buzina** | 6 | O **primeiro golpe** de cada luta é absorvido (toca uma buzina) | — |
| **Luvas de Mímico** | 3 | **Janela de parry 50% maior** | — |
| **Sapatos de Mola** | 3 | Pulo **15% mais alto** | Pouso faz poeira que revela onde você está (só estético) |
| **Trevo da Cartomante** | 4 | Barra de Aplausos enche **25% mais rápido** | — |

### Números de dupla (só funcionam com o parceiro)

| Item | Preço | Efeito |
|---|---|---|
| **Catapulta** | 4 | Dar dash **encostando no parceiro** arremessa você bem alto, invencível durante a subida |
| **Rolha Turbinada** | 4 | Seus tiros que **atravessam o parceiro** saem 50% mais fortes |
| **Pirâmide Humana** | 4 | Pular **na cabeça do parceiro** conta como parry (quica e ganha estrela), no máximo 1 vez a cada 5 s |
| **Rede de Segurança** | 3 | Quando o **parceiro** cai, o balão dele sobe 50% mais devagar e o resgate é na hora, só encostando (sem esperar 1 s) |

Total da loja da Área 1: **58 ingressos** (fora os iniciais). Em 04/10/2026 o Coração de Pano e o Nariz de Buzina subiram de 3 para 6 (o usuário achou os dois fortes demais pelo preço, jogando em dupla). Com até 18 por jogador e a possibilidade de doar, a dupla compra uns 6 a 8 itens nessa área.

## Como ficou no jogo (02/10/2026, decidido pelo Claude, revisar; números a calibrar)

- **Barraca:** a tenda "Curiosidades" do mapa. Abre só na tela de quem entrou; enquanto ela está aberta, os personagens daquele PC não se mexem. Comprar pede um segundo aperto ("Levar por N ingressos?"). "Dar" passa ingressos ao parceiro. O lojista se chama, por enquanto, **Seu Bonifácio**; as falas estão em `dialogues/lojista.json` e os itens em `dialogues/items.json`.
- **Camarim:** Esc > Camarim, só no mapa. Sozinho mostra os dois personagens; online, só o seu.
- **Online:** o save (com carteiras, itens e equipamento) fica no host; o cliente pede e o host confere. O cliente só mexe na carteira e no equipamento da acrobata. O host manda a cópia do save assim que o parceiro conecta, então cada um nasce com o equipamento certo.
- **Pistolas:** Rolha (0,12 s entre tiros, 1 de dano). Leque de Confete (0,2 s; 3 confetes de 1 de dano em leque de ±8,6°, somem em 0,55 s ≈ 830 px (até 05/10/2026 eram ±12° e 0,3 s ≈ 450 px: o usuário achou que só acertava de perto); EX: explosão de raio 230 em volta, até 5 × 6). Clave de Malabares (0,4 s; 2 de dano, vai uns 450 px e volta para a mão, acertando na ida e na volta; EX: 5 claves caem à frente, 6 cada). Bolha de Sabão (0,18 s; 1 de dano, teleguiada até 1000 px; EX: Bolhona lenta e teleguiada que estoura em área com 35).
- **Truques:** Fumaça do Mágico (dash 25% mais curto, some durante o dash e deixa um boneco de fumaça por 1 s; a Patada, a Isca do leão e os alvos do Mágico miram no boneco). Bala de Canhão (o dash dá 8 de dano em quem atravessar, mas não protege). Pirueta (dash na direção que estiver apertando, inclusive para cima; no chão recarrega no dobro do tempo).
- **Adereços:** Coração de Pano (4 corações; as estrelas enchem 15% mais devagar). Nariz de Buzina (o primeiro golpe de cada fase não tira vida: "Fom-fom!"). Luvas de Mímico (janela do parry 0,33 s em vez de 0,22). Sapatos de Mola (pulo 15% mais alto). Trevo da Cartomante (tudo que enche a barra vale 25% mais).
- **Números de dupla:** Catapulta (dash encostando no parceiro: arremesso de 1500 px/s para cima, invencível subindo). Rolha Turbinada (tiro que passa pelo corpo do parceiro fica 50% mais forte, uma vez). Pirâmide Humana (cair na cabeça do parceiro quica como um parry e dá estrela; 1 vez a cada 5 s). Rede de Segurança (o balão do parceiro sobe na metade da velocidade e o resgate é na hora, só encostando nele).

## Itens de áreas futuras (ideias)

- Pistola **Canhãozinho** (lento, dano alto, recuo), Truque **Mola** (dash no chão vira salto alto), Adereço **Monóculo** (mostra a vida do chefão), Número **Trapézio** (os dois de mãos dadas no ar trocam de lugar).
