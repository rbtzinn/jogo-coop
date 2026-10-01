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
| **Coração de Pano** | 3 | **+1 PV** | Tiro causa 5% menos dano |
| **Nariz de Buzina** | 3 | O **primeiro golpe** de cada luta é absorvido (toca uma buzina) | — |
| **Luvas de Mímico** | 3 | **Janela de parry 50% maior** | — |
| **Sapatos de Mola** | 3 | Pulo **15% mais alto** | Pouso faz poeira que revela onde você está (só estético) |
| **Trevo da Cartomante** | 4 | Barra de Aplausos enche **25% mais rápido** | — |

### Números de dupla (só funcionam com o parceiro)

| Item | Preço | Efeito |
|---|---|---|
| **Catapulta** | 4 | Dar dash **encostando no parceiro** arremessa você bem alto, invencível durante a subida |
| **Rolha Turbinada** | 4 | Seus tiros que **atravessam o parceiro** saem 50% mais fortes |
| **Pirâmide Humana** | 4 | Pular **na cabeça do parceiro** conta como parry (quica e ganha estrela), no máximo 1 vez a cada 5 s |
| **Rede de Segurança** | 3 | Quando o **parceiro** cai, o balão dele sobe 50% mais devagar e você revive só encostando (sem precisar de parry) |

Total da loja da Área 1: **52 ingressos** (fora os iniciais). Com até 18 por jogador e a possibilidade de doar, a dupla compra uns 6 a 8 itens nessa área.

## Itens de áreas futuras (ideias)

- Pistola **Canhãozinho** (lento, dano alto, recuo), Truque **Mola** (dash no chão vira salto alto), Adereço **Monóculo** (mostra a vida do chefão), Número **Trapézio** (os dois de mãos dadas no ar trocam de lugar).
