# Pedido ao Claude — integrar o mapa ampliado em quatro partes

Implemente no projeto `C:\jogo-coop` o novo mapa de circo formado por quatro imagens em um arranjo contínuo 2 × 2. O objetivo é ter um mundo maior, com espaço para explorar e distâncias maiores entre as atrações.

## Enquadramento aprovado pelo usuário

**O mapa inteiro NÃO precisa ficar visível na tela.** A tela deve mostrar uma região do mundo por vez. Conforme os jogadores caminham, a câmera revela as outras regiões, respeitando o funcionamento atual do cooperativo.

As quatro imagens são partes de um único cenário contínuo. Cruzar de uma parte para outra deve acontecer durante a caminhada, com continuidade visual e de movimentação. Não transforme cada imagem em uma tela independente nem comprima todo o mapa para caber no viewport.

Ajuste o enquadramento e a escala do mundo para que o jogador perceba o aumento do mapa. Preserve uma escala legível para os personagens e para as entradas das atrações.

## Arquivos e montagem exata

Pasta dos arquivos:

`C:\jogo-coop\docs\referencias\remap_conceitos\mapa_amplo_4partes\`

| Arquivo | Tamanho em pixels | Posição do canto superior esquerdo no conjunto |
| --- | --- | --- |
| `01_noroeste.png` | 836 × 470 | x = 0, y = 0 |
| `02_nordeste.png` | 836 × 470 | x = 836, y = 0 |
| `03_sudoeste.png` | 836 × 471 | x = 0, y = 470 |
| `04_sudeste.png` | 836 × 471 | x = 836, y = 470 |

Disposição:

```text
01_noroeste | 02_nordeste
------------+------------
03_sudoeste | 04_sudeste
```

O conjunto mede **1672 × 941 pixels**. A linha inferior tem um pixel a mais de altura: respeite as medidas reais, sem arredondar cada imagem para um tamanho comum.

Essas posições estão no espaço local da imagem. Converta-as para as unidades usadas pelo mapa atual aplicando uma transformação comum às quatro partes. Não misture coordenadas de tela, imagem e mundo.

`mapa_completo.png`, na mesma pasta, é a referência visual da montagem inteira. Os quatro PNGs foram comparados pixel a pixel com essa referência e apresentaram zero divergências. A continuidade entre as partes já existe na arte; preserve-a na implementação.

## Implementação

1. Primeiro, leia a cena e os scripts do mapa atual. Entenda como o cenário é desenhado, como funcionam câmera, movimentação, entradas, colisões e multiplayer. Use os sistemas existentes.
2. Integre as quatro texturas sob uma transformação comum, com a mesma escala, orientação e filtragem. Posicione-as pelos cantos ou considere corretamente os pivôs utilizados pelo sistema atual.
3. Garanta emendas sem vãos, sobreposições, linhas, mudanças de escala ou saltos de posição. Evite arredondamentos independentes dos quatro elementos durante o movimento da câmera. Se houver artefatos de amostragem, corrija a configuração de renderização preservando o encaixe original.
4. Faça a câmera mostrar apenas uma região do mapa por vez e acompanhar a exploração. Mantenha o comportamento compatível com as regras atuais do cooperativo, tanto localmente quanto no multiplayer.
5. Defina limites de câmera que considerem a extensão do mundo e o tamanho do enquadramento, para não mostrar áreas fora do cenário.
6. Renderize personagens, HUD e indicadores de interação separadamente sobre o cenário. As novas imagens já estão limpas para isso.
7. Alinhe as entradas e interações existentes com as portas desenhadas: Domador, Malabaristas, Mágico, loja, camarim e estação. Reposicione os elementos de mapa necessários, mantendo seus destinos e comportamentos.
8. Ajuste os limites de caminhada e as colisões ao novo terreno. Os caminhos e clareiras devem ser utilizáveis; construções, cercas e demais obstáculos relevantes devem corresponder à arte. A imagem, por si só, não cria colisões.
9. Preserve o ordenamento visual entre personagens e elementos do cenário conforme a arquitetura atual. Verifique especialmente entradas, cercas e fachadas.
10. Mantenha o custo de renderização baixo. Use os recursos existentes e evite recriar iluminação, geometria ou efeitos já representados na imagem sem necessidade.

Preserve a identidade dos personagens e toda a lógica de combate, chefes, progressão, loja, salvamento e rede. Alterações espaciais para alinhar o mapa estão dentro deste pedido; não altere preços, desbloqueios, ataques, atributos, recompensas ou regras do cooperativo.

Preserve também as mudanças locais existentes de outras tarefas. Não sobrescreva trabalho não relacionado.

## Resolução e escala

A resolução nativa do cenário completo é **1672 × 941**, não 4K. Aumentar a escala no mundo não adiciona definição. Configure o enquadramento considerando essa resolução e confira a nitidez no tamanho real da janela do jogo.

## Verificação dentro do jogo

- Percorra as emendas horizontal e vertical e o encontro central das quatro partes. Confira que cenário, personagem e câmera continuam sem saltos ou linhas.
- Caminhe do portão até todas as atrações. Teste as entradas, loja, camarim e estação.
- Confira colisões, áreas transitáveis e posicionamento dos indicadores de interação em relação à arte.
- Teste o enquadramento no centro, nas bordas e nos quatro cantos, incluindo as resoluções de janela já suportadas.
- Teste com os dois personagens e no multiplayer. Verifique o comportamento da câmera quando os jogadores se afastam, conforme as regras atuais.
- Compare o desempenho antes e depois em condições equivalentes.
- Rode as verificações relevantes do projeto e corrija regressões causadas por esta integração.

Conclua a implementação e entregue capturas de diferentes regiões do mapa funcionando, os resultados das verificações e qualquer limitação restante. Não considere o trabalho concluído apenas porque os quatro arquivos aparecem na cena: o mapa deve estar navegável, com câmera, entradas e colisões funcionando.
