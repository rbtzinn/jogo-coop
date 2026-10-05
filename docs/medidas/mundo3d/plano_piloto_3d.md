# Piloto 3D: miniatura do palhaço e trecho Camarim → Barraca (plano, 04/10/2026)

Pedido do usuário: acabamento visual 3D com modelagem, animação, câmera, luz e ambiente trabalhados juntos. É
um piloto só: UMA miniatura (o palhaço) e UM trecho (do Camarim à Barraca de Curiosidades), antes de mexer na
acrobata ou no resto. O vídeo citado (jogo de cristais) é referência de beleza e fluidez. Não temos a receita
do autor e não vou inventá-la. Nada pago: sem Higgsfield, sem modelos comprados. As lutas continuam 2D.

## Baseline (antes), preservada como irmã

- **Miniatura atual:** `core/world/miniature.gd`, montada por código (esferas, cápsulas, cilindros, contorno de
  tinta). Os pés são plantados por IK de duas partes; o passo nasce da velocidade. Na revisão anterior de
  04/10 ela ganhou: virar para a câmera parada, cabeça erguida e escala 1,55.
- **Trecho:** a trilha 0 do mapa (`levels/world/world_area1.gd`), do Camarim (−12,6; 1,6) à Barraca
  (−1,4; −0,5), uns 12 m com duas curvas, passando pelo Domador.
- **Câmera:** fixa, alta e oblíqua (inclinação −42°, distância 9,4, campo de visão 34°).
- **Captura reproduzível:** `-- mundo_piloto <pasta>` (tests/screenshots.gd). O controle é de verdade (teclas),
  com os trechos largada, curva, reta, freio, as 8 direções, Tab e o palhaço como seguidor. Mede por trecho e
  por personagem:
  - o deslize do pé de apoio (mediana, P95 e pior);
  - os contatos por segundo;
  - a altura da cabeça na tela (px) e quanto do tempo o rosto fica virado para a câmera;
  - a velocidade.
- **Vídeo:** pelo Movie Maker da Godot (`--write-movie`, 60 quadros por segundo).
- **Desempenho:** outra rodada sem `--fixed-fps`, com o tempo de quadro real neste PC.
- **Arquivos:** `docs/medidas/mundo3d/baseline/`.

## Plano (finito)

1. **Folha de modelagem.** As referências aprovadas mostram o palhaço só de lado e de 3/4: não há frente nem
   costas, nem a parte de trás da cabeça, do chapéu e da gola. Fica UM pedido de imagem na fila (o P3D1: frente,
   3/4, perfil e costas em pose A). Enquanto ele não chega, a modelagem segue pelas referências atuais.
2. **Modelo no Blender 4.5.14 LTS** (portátil, fora do projeto), por script `tools/blender/palhaco_miniatura.py`,
   reproduzível e sem trabalho manual escondido. Exporta GLB para `core/world/models/clown.glb`.
   - **Formas:** cabeça grande e alta (testa larga, queixo estreito), nariz de bola, olhos ovais com o corte de
     torta, sorriso com língua, tufos vermelhos em nuvem (metaball), cartolinha inclinada com faixa dourada e
     margarida, gola de babado ondulada, corpo de pera em xadrez bordô/creme com dois botões dourados, calça
     bufante com babado no tornozelo, sapatão marrom com faixa creme e sola clara, luvas de 4 dedos.
   - **Materiais:** pintura de miniatura (cor chapada com variação leve, verniz baixo); texturas geradas no
     script (xadrez).
   - **Esqueleto:** quadril, tronco, cabeça, chapéu (balanço), braços e pernas de duas partes; pele com pesos
     nas pernas e nos braços, peças rígidas no resto.
3. **No Godot:** a miniatura nova usa o GLB e continua com o andar procedural de hoje (pés plantados por IK, um
   passo de cada vez, ritmo pela velocidade de 2,4 m/s, giro suave, começo e freio). Isso foi escolhido de
   propósito: um ciclo de animação pronto deslizaria o pé fora da velocidade exata. Os ossos copiam um
   esqueleto de controle invisível. A cabeça e o rosto mantêm o tamanho. Nada de inclinar o corpo inteiro para
   fingir passo.
4. **Trecho Camarim → Barraca:**
   - curvas de trilha com bordas;
   - marcos distintos;
   - vegetação variada (sem carimbo);
   - luz âmbar dos postes e azul da lua;
   - sombra de contato legível;
   - câmera que deixa ver o rosto.
   - Qualquer mudança de câmera ou escala é comparada com a baseline e tem o motivo registrado.
5. **Comparação antes/depois** no mesmo roteiro: vídeo, métricas e desempenho, com as duas miniaturas e a
   oclusão. Depois, uma decisão motivada: integrar se ganhar, ou preservar a baseline e registrar as falhas.
6. **Avaliação humana:** pedir a do piloto visual pronto, sem bloquear as rotinas delegadas. Nada de declarar
   "incrível" aprovado por mediana.

## Fora do escopo

- a acrobata (só depois do piloto);
- lutas em 3D, ataques novos, áreas e chefões;
- reabrir a E7;
- gerar a E8 agora;
- pagar qualquer coisa;
- git;
- mexer no Windows, em autenticação ou em configurações.

## Limites que continuam

- a falha intermitente do "Número Perfeito" no teste online (causa desconhecida);
- a E4b do tonto (29,1 px no nariz, 8,4 px no sapato).

## Resultado (04/10/2026)

**Feito:**
- **Modelo:** `tools/blender/palhaco_miniatura.py` (Blender 4.5.14 LTS portátil, `--background
  --factory-startup`) gera `core/world/models/clown.glb`.
  - 1 MB; duas malhas com pele (o corpo e o rosto, este com a shape key do piscar); 18 ossos; xadrez em textura
    gerada.
  - Prévias do Blender: `docs/referencias/pecas/palhaco_3d/` (frente, 3/4, perfil, costas e o rosto ampliado).
- **No Godot** (`core/world/miniature.gd`): o palhaço usa o modelo. O andar continua o procedural (pés
  plantados por IK), através de um esqueleto de controle invisível com as mesmas juntas. A cada quadro os
  ossos copiam o esqueleto de controle (`set_bone_global_pose`). O contorno de tinta entra por cima dos
  materiais.
  - Com `use_model` falso (ou `Miniature.use_models` falso) volta o boneco de código: a baseline fica
    preservada.
  - A acrobata não mudou.
- **Trecho Camarim → Barraca** (`levels/world/world_area1.gd`, `_dress_trail`):
  - pedrinhas de borda;
  - tufos de capim;
  - grupos de margaridas;
  - varal de lâmpadas âmbar em zigue-zague sobre a trilha, com duas luzes de verdade;
  - placa de bifurcação.
  - Tudo em MultiMesh, com sorteio fixo. Desliga só para comparar (`sem_trecho`).
- **Câmera e escala:** não mudaram. Motivo: as duas rodadas comparadas mostram o rosto aceso e de frente
  sempre que a dupla para (o virar para a câmera já existia). Mudar o ângulo trocaria o enquadramento do parque
  inteiro, e isso fica fora de um piloto de um trecho.

**Comparação reproduzível** (o mesmo roteiro, as mesmas teclas, a 60 quadros por segundo fixos; as posições
batem quadro a quadro):
- **Antes:** `-- mundo_piloto <pasta> boneco sem_trecho` (`antes_reproduzivel/`; reproduz exatamente os números
  da baseline original).
- **Depois:** `-- mundo_piloto <pasta>` (`depois/`).
- **Folha lado a lado:** `antes_depois.png` (`comparar.gd`).
- **Vídeos** (Movie Maker, 1280 × 720 a 60): `baseline/baseline_trecho.avi` e `depois/depois_trecho.avi`.

**Palhaço, antes → depois:**

| Trecho | Deslize do pé de apoio (mediana / pior) | Contatos/s |
|---|---|---|
| largada | 13,4 / 21,9 mm → 9,1 / 17,8 mm | 10,0 → 10,0 |
| curva 1 | 18,0 / 37,6 mm → 9,4 / 14,2 mm | 7,0 → 8,4 |
| reta | 7,5 / 8,6 mm → 5,0 / 8,4 mm | 7,0 → 8,4 |
| curva 2 | 7,4 / 20,9 mm → 4,2 / 15,5 mm | 7,2 → 8,0 |
| 8 direções | 7,4 / 36,5 mm → 4,6 / 12,9 mm | 5,9 → 7,1 |
| Tab (seguindo) | 8,9 / 27,3 mm → 5,8 / 26,3 mm | 4,3 → 5,7 |

- **Cabeça na tela:** 117–121 px → 138–143 px (mediana; a cabeça do modelo é mais alta, como na folha).
- **Rosto virado para a câmera** (produto escalar > 0,3): igual, porque quem decide é o virar parado. Largada
  97%, freio 54%, 8 direções 39%; andando de costas para a câmera, 0%.
- **Desempenho neste PC** (Intel UHD 630, janela 1280 × 720, sem vsync, jogo aquecido, 2 rodadas):
  - antes 39,9 / 39,9 quadros por segundo; depois 42,5 / 42,9;
  - as chamadas de desenho caíram de 3322 para ~2745 (o boneco tinha ~100 peças, cada uma com contorno).
  - A primeira medida da baseline (24,5) era o jogo frio, ainda compilando shaders. Ela não vale para comparar.

**Decisão:** integrar. Ganhos:
- o palhaço lê como o desenho aprovado (rosto, cabelo, chapéu, xadrez, babados, sapatões);
- o pé desliza menos em todos os trechos;
- o trecho fica mais quente e mais legível;
- o desempenho ficou um pouco melhor.

A baseline continua disponível pelas chaves (`boneco`, `sem_trecho`) e pela captura guardada.

**Falhas e limites:**
- **O mapa inteiro continua abaixo da meta de 60 quadros por segundo** neste PC (~40 a 43). Quem pesa é o
  cenário (~2700 chamadas de desenho). Este é o próximo defeito real.
- **Cadência alta:** a 2,4 m/s o palhaço dá ~8,4 contatos por segundo (pernas curtas; o boneco dava 7,0). Lê
  como passinhos rápidos de boneco; não foi pedido de mudança.
- **Detalhes de perto:** a gola ainda fica serrilhada de perto; o corte de torta da pupila é um entalhe
  simples. Na distância da câmera do mapa, nenhum dos dois aparece.
- **Rosto:** é de decalques e não muda de expressão (só pisca).
- **Folha de modelagem:** a frente e as costas foram modeladas sem ela (o pedido P3D1 está aberto). Se ela
  chegar, a nuca, as costas da gola e os sapatos de frente são conferidos contra ela.
- **Avaliação humana:** pedida. Nada aqui é "incrível" aprovado: as métricas medem contato e desempenho, não
  beleza.
- **Observação de processo:** as rodadas de desempenho gravavam por cima das fotos e do CSV da rodada a 60
  fixos. As pastas `baseline/` e `depois_modelo/` têm fotos e CSV dessas rodadas (os resumos `.txt` valem).
  Corrigido: o desempenho agora grava em `desempenho/`.
