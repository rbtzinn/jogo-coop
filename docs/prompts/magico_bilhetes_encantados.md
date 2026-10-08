# Pedido de arte — bilhetes encantados do Zaratan

Preparado em 07/10/2026 após conferir `bosses/magician/attacks/magic_prop.gd`.

**O que já existe:** as antigas cartas são desenhadas por código como ingressos com recortes laterais, picote e selo. O bilhete normal é creme/vermelho, o de parry é turquesa e o perseguidor é escuro, com P1/P2 desenhado separadamente. Ainda não existem sprites próprios desses bilhetes.

**Objetivo:** substituir o desenho provisório por papel pintado, com identidade do circo. Os nomes internos `card` e `pink` são mantidos por compatibilidade. Esta entrega prepara os pedidos; nenhuma imagem foi gerada ou integrada.

## Instrução comum

Gerar uma imagem por vez. Usar o primeiro bilhete aprovado como referência para os outros dois. Não reaproveitar os pedidos antigos de cartas de baralho. Os três devem ter a mesma proporção e centro.

```text
Crie UMA peça de arte ORIGINAL para um jogo 2D de uma trupe de circo assombrada: um pequeno BILHETE ENCANTADO de ingresso, que voa durante os truques de um mágico.

Papel de circo brasileiro mambembe, bordas cortadas à mão, duas reentrâncias semicirculares nas laterais, faixa de picote perto do topo, selo de estrela de cinco pontas na metade inferior e uma pontinha levemente curvada. O selo é uma impressão gráfica no papel, não um brilho mágico. Sem números, palavras ou moldura simétrica de carta de baralho. Sem naipes, figuras de baralho, rostos, casino ou ilustrações nos cantos.

Vista de frente, bilhete em pé, sem perspectiva forte. Deve ler como papel impresso e perfurado mesmo no tamanho pequeno do combate. Contorno marrom #1B1410, sombra pintada simples, textura de papel gasto e impressão com pequenas falhas. Mesma linguagem 2D entintada e pintada à mão das referências do próprio projeto; não imite personagens ou arte de jogos existentes.

PNG RGBA com transparência real, canvas desejado 512 x 512. Centro do bilhete em (256, 256). Silhueta principal desejada dentro de uma área central de aproximadamente 288 x 416 px, para reduzir depois de forma uniforme à proporção de 36 x 52 do desenho atual. Manter pelo menos 24 px vazios em todas as bordas, incluindo efeitos. Sem chão, sombra externa, fundo, grade, letras, símbolos de interface ou borrão.

Aplique somente a variante pedida abaixo e gere somente a imagem. Preserve código, cenas, recursos e arte existente.
```

## Variante 1 — bilhete comum

Acrescentar ao bloco comum:

```text
VARIANTE COMUM: papel creme #F2E6CC, tinta vermelho queimado #A3282A no picote e no selo, sombra de papel ocre suave. Sem luz turquesa, aro luminoso ou brilho de estrela. Não parecer o ingresso dourado de recompensa.

Destino: docs/referencias/pecas/magico/bilhetes_encantados/bilhete_comum.png.
```

## Variante 2 — bilhete de parry

Acrescentar ao bloco comum e anexar a variante comum escolhida:

```text
VARIANTE DE PARRY: preserve exatamente o formato, proporção, centro, picote e selo do bilhete comum anexado. Papel turquesa #2EE6D6, sombra #138F86, detalhes claros #B8FFF7 e aro claro #F7FFFD dentro da borda. O selo impresso de cinco pontas permanece, com tinta clara. A estrela animada de quatro pontas será desenhada separadamente pelo jogo: não a desenhe nesta textura, para evitar duplicação. Não adicione partículas ou aumente a silhueta com um halo externo.

Destino: docs/referencias/pecas/magico/bilhetes_encantados/bilhete_parry.png.
```

## Variante 3 — bilhete perseguidor

Acrescentar ao bloco comum e anexar a variante comum escolhida:

```text
VARIANTE PERSEGUIDORA: preserve o formato, centro, escala, picote e selo do bilhete comum anexado. Papel escuro #1B1410, selo e picote vinho #6E1C1B, contorno creme claro #FFF3C4 para contrastar com a arena. Deixe uma área central limpa para o jogo desenhar P1 ou P2; não escreva esses rótulos nem qualquer texto na imagem. Sem turquesa, aro mágico ou brilhos de parry.

Destino: docs/referencias/pecas/magico/bilhetes_encantados/bilhete_perseguidor.png.
```

## Conferência e futura integração

- Conferir alfa, margens, proporção e leitura em 36 x 52 px. A resolução real do gerador deve ser registrada; as dimensões acima são metas de produção.
- O desenho atual ocupa 36 x 52 px, mas a colisão destes objetos é um círculo de raio **20**. Não confundir tamanho da arte com tamanho da colisão nem alterar esse raio por causa da textura.
- Preservar giro do bilhete comum/parry, orientação do perseguidor, rótulo P1/P2 legível e a estrela animada desenhada por `ParryStyle`. Manter sinal de parry pela cor e pelo aro, mesmo antes da estrela animada aparecer.
- Trocar somente a apresentação. Trajetórias, velocidades, alvos, quantidades, sincronização e regras de parry precisam permanecer iguais nessa integração.
- Bilhetes distintos de cartas resolvem o motivo visual do baralho. Avaliar separadamente os gestos e a organização dos ataques; a troca de textura não demonstra originalidade da luta inteira.
