# Combate — Respeitável Público

> Proposta detalhada (parte do [DESIGN.md](DESIGN.md)). Itens marcados com **[a decidir]** ainda esperam aprovação do usuário.

## Vida e dano

- Cada jogador tem **3 pontos de vida (PV)**. Adereços podem aumentar.
- Ao levar dano: perde 1 PV, fica **1,5 s invencível** (piscando) e é empurrado levemente para trás.
- Encostar no corpo do chefão também causa dano (exceto durante dash invencível).
- Detecção de dano favorável a quem joga: a caixa de dano do jogador é **menor que o desenho** (já é assim) e a decisão de "fui atingido" é tomada no PC de quem joga (ver regras de rede no CLAUDE.md).

## Cair e reviver: o Balão

Diferente do Cuphead (fantasma), aqui quem cai **vira um balão de circo com a própria cara**, que sobe devagar.

- O balão leva **6 segundos** para sair pelo topo da tela.
- O parceiro revive dando **parry no balão** (ver Parry). O revivido volta com **1 PV**.
- Se o balão sair da tela, aquele jogador está fora até o fim da luta.
- **Os dois caírem = derrota.**
- O balão balança com o vento dos ataques do chefão, o que deixa o resgate mais emocionante.

## Parry

Objetos **rosa** (`#ff5fa2`) podem receber parry. Todo chefão tem alguns ataques rosa.

- **Como fazer [a decidir]:** apertar **pular de novo no ar** encostando no objeto rosa (como no Cuphead).
- Efeito: o personagem **quica para cima** (pulo extra), o objeto é destruído ou anulado e ele ganha **1 estrela de Aplauso** (ver Especial).
- Janela generosa: a área de parry do personagem é maior que o desenho.
- **Parry em dupla (diferencial):** se os dois jogadores derem parry no **mesmo objeto** com até **0,3 s** de diferença, sai um **"Número Perfeito"**: cada um ganha 2 estrelas, a tela dá um flash e a plateia aplaude. Alguns chefões têm objetos rosa grandes feitos para isso.
- Dar parry no balão do parceiro revive (e também conta como parry).

## Especial: a barra de Aplausos

Cada jogador tem uma barra de **5 estrelas de Aplauso**. Ela enche causando dano ao chefão e com parries (+1 estrela cada).

- **Tiro EX (gasta 1 estrela):** versão forte do tiro da pistola equipada, na direção da mira. Cada pistola tem o seu (ver [shop.md](shop.md)).
- **Grande Número (gasta as 5 estrelas):** golpe máximo, **diferente para cada personagem** (no Cuphead é igual para os dois):
  - **Palhaço — "Torta na Cara":** arremessa uma torta gigante que atravessa a tela causando muito dano, e o palhaço fica invencível durante a animação.
  - **Acrobata — "Salto Mortal":** salta girando por cima do chefão, invencível, causando dano em tudo que atravessa.
- **Grande Número em Dupla (diferencial):** se os dois soltarem o Grande Número com até **1 s** de diferença, os golpes se combinam num ataque único maior (ex.: a acrobata salta em cima da torta e a chuta no chefão), com dano maior que a soma dos dois.
- Novo botão **Especial**. Padrão sugerido: teclado **I** (layout 1) e **V** (layout 2, como no Cuphead); controle **Y**. Toque = Tiro EX; com 5 estrelas, toque = Grande Número.

## Nota no fim da luta

Ao vencer, aparece um cartaz de circo com a nota de cada luta (da dupla):

| Critério | Peso |
|---|---|
| Tempo | quanto mais rápido, melhor |
| Vida restante (somando os dois) | quanto mais, melhor |
| Parries (incluindo Números Perfeitos) | até 3 contam |
| Estrelas usadas | até 6 contam |

Notas: **C, B, A, S**. Melhorar a melhor nota de um chefão dá ingressos de bônus (ver [shop.md](shop.md)).

## Dificuldade

- Os chefões são balanceados **sempre para 2 jogadores** (não existe modo solo por enquanto).
- Duração alvo de uma luta: **2 a 3 minutos** quando bem jogada.
- Vida do chefão dividida por fase (ex.: 40% / 35% / 25%); a troca de fase é sempre clara (animação + som).
