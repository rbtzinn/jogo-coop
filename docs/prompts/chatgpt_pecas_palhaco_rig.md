# Peças do palhaço para o rig (piloto da nova animação)

Gere **peças separadas** do palhaço para montar num esqueleto 2D (cutout). **Não** gere poses, quadros de corrida, pulo ou queda.

## Referências no projeto
- Identidade: `core/player/characters/clown/idle/idle_1.png`
- Cabeça: `core/player/characters/clown/clown_head.png`
- Luva: `core/player/characters/shared/glove_fist.png`

## Regras para todas as peças
- Estilo cartoon anos 1930, tinta preta grossa, pintura levemente texturizada, igual ao `idle_1.png`.
- Paleta exata: tinta `#0d0806`, creme `#f9eedd`, creme amarelado `#f8dcaf`, vermelho `#e91717`, vermelho escuro `#a1110e`, marrom `#63240b`, dourado `#f5a708`.
- PNG com fundo transparente, 1024x1024, peça centralizada com margem vazia.
- Vista de perfil 3/4 olhando para a DIREITA, como no `idle_1.png`.
- Sem sombra projetada, sem chão, sem cenário, sem texto.
- Contorno preto com a mesma espessura do `idle_1.png`.
- Peça reta e neutra (sem inclinação, sem movimento).
- Uma imagem por peça.

## Peças (salvar em `docs/referencias/pecas/palhaco_rig/`)

1. `head_happy.png`: a cabeça da `clown_head.png` **sem cartola e sem flor**. O topo da cabeça completo (careca creme no alto, tufos de cabelo vermelho dos lados como no original). Sorriso alegre, olhos abertos. Pescoço prolongado uns 20% para baixo, terminando reto (vai ficar escondido na gola). Sem gola, sem corpo.

2. Expressões: **editar** a `head_happy.png`, mudando só olhos, sobrancelhas e boca. Contorno, tamanho, posição, cabelo, nariz e pescoço idênticos, pixel a pixel.
   - `head_blink.png`: olhos fechados, sorriso suave.
   - `head_surprise.png`: olhos arregalados, sobrancelhas altas, boca pequena em "o".
   - `head_effort.png`: sobrancelhas franzidas para baixo, sorriso de dentes cerrados.

3. `torso.png`: só o tronco do macacão (do pescoço ao quadril), xadrez vermelho `#e91717` e creme `#f9eedd`, com os 2 botões dourados na frente, barriga redonda como no `idle_1.png`. Sem gola, braços, pernas ou cabeça. O topo é estreito e termina reto (fica sob a gola). A base é arredondada e com sobra, um pouco mais longa que o normal (as pernas encaixam por baixo). Laterais limpas onde saem os braços.

4. `collar.png`: só a gola de babado creme, como no `idle_1.png`, em perfil 3/4. O meio (onde passa o pescoço) fica transparente.

5. `leg_strip.png`: faixa reta vertical, tubo de tecido xadrez vermelho e creme, contorno preto só nas laterais, pontas de cima e de baixo abertas e retas. Proporção 1:5. Sem dobras, sem pé.

6. `arm_strip.png`: faixa reta vertical, tubo creme `#f9eedd` liso com leve textura, contorno preto só nas laterais, pontas abertas e retas. Mais fina que a perna. Proporção 1:6. Sem mão.

7. `glove_open.png`: a mesma luva da `glove_fist.png` (estilo e tamanho), mas aberta: 4 dedos bem abertos, palma para a frente, mesmo babado no punho, apontando para cima.

## Não gerar
Chapéu, flor, sapato e luvas com arma (já existem ou serão recortados do projeto).
