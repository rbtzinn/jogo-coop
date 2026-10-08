# Mapa do Vulcão em alta resolução

O mapa da Ilha do Vulcão aparece embaçado no jogo: as 4 partes têm 1600 × 900 e a câmera mostra só 720 pixels de
altura do mapa numa tela de 1080, então cada pixel é esticado 1,5x. Precisamos das **mesmas 4 imagens com o dobro
da resolução**, mais nítidas.

## Arquivos de origem
- `levels/world/art/volcano_01_noroeste.png`
- `levels/world/art/volcano_02_nordeste.png`
- `levels/world/art/volcano_03_sudoeste.png`
- `levels/world/art/volcano_04_sudeste.png`

## Regras (importantes: o jogo usa a posição de cada coisa)
- Cada parte nova com **3200 × 1800** (exatamente o dobro de 1600 × 900).
- **Nada muda de lugar, de forma ou de tamanho:** estradas, pedras, tendas, portas, avião, lava, rio, árvores e
  bordas ficam exatamente onde estão, só com o dobro de pixels. Se sobrepor a imagem nova reduzida à metade sobre a
  antiga, as duas precisam coincidir.
- Só ganhar nitidez e detalhe de pintura (textura das pedras, brilho da lava, contornos limpos), no mesmo estilo e
  com as mesmas cores.
- As 4 partes continuam se encaixando sem emenda entre si (as bordas que se tocam batem pixel a pixel).
- Sem texto, sem personagens, sem moldura.
- Fazer uma parte por vez, na ordem 01, 02, 03, 04.

## Salvar
Em `docs/referencias/remap_conceitos/vulcao_hd/`, com os mesmos nomes (`volcano_01_noroeste.png` etc.).
Não substituir os arquivos de `levels/world/art/`.
