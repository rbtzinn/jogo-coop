# Mapa do circo — projeto Blender 3D

Abra `mapa_circo_3d.blend` no Blender 4.5 ou superior. É um cenário 3D editável, feito a partir da direção visual do mapa em quatro imagens, com geometria própria para as atrações e os elementos do ambiente.

O projeto inclui três tendas com lona curva, costuras, cortinas e emblemas modelados; caravanas de camarim e loja com rodas, telhados curvos e interiores de fachada; portão com arco, grades abertas e ornamentação; locomotiva com rodas raiadas, bielas, tubulações, rebites e tender; estação com plataforma, cobertura, relógio, bancos e bagagens; monumento, jardins, vegetação, lampiões e terreno contínuo.

## Organização

As coleções separam terreno, atrações, jardins, decoração, iluminação e câmeras. Os modelos têm componentes editáveis e nomes descritivos. As unidades são metros.

O piso possui uma máscara de caminhos gerada a partir da geometria e empacotada no arquivo. As superfícies usadas para desenhar essa máscara ficam na coleção `09_Guias_Caminhos_ocultos`, para edição futura. Os materiais e a fonte utilizada também ficam empacotados. As quatro imagens originais não são usadas como um plano de fundo dentro do cenário.

## Câmeras salvas

| Câmera | Uso |
| --- | --- |
| `01_Mapa_completo` | Visão geral do cenário |
| `02_Estacao_detalhe` | Locomotiva, trilhos e plataforma |
| `03_Praca_e_caravanas` | Fachadas do camarim e da loja |
| `04_Tendas_detalhe` | Tendas e seus detalhes |
| `05_Portao_detalhe` | Arco, grades e ornamentação |
| `06_Monumento_detalhe` | Escultura e jardim |
| `07_Vista_alternativa_3D` | Visão de outro ângulo |

A câmera ativa no arquivo é a visão geral. Para renderizar outra, selecione a câmera no Outliner e use **Ctrl + Num 0** com o cursor sobre a viewport. **Num 0** mostra o enquadramento da câmera; **F12** renderiza.

## Escopo desta entrega

Este projeto está separado da implementação do jogo. Não foram alteradas cenas, scripts, regras ou configurações de execução da Godot. A pasta contém `.gdignore` para impedir que o editor importe o projeto Blender automaticamente.

Não há corpos físicos ou colisores no arquivo. Os lampiões são decoração e ficam nas bordas das rotas; a linha férrea está separada do acesso dos pedestres à estação. A integração futura precisará definir colisões, câmera, entradas e o comportamento dos personagens na Godot. Os problemas existentes de colisão e sobreposição no jogo não são corrigidos apenas por criar este cenário.

Os renders demonstram o cenário offline. O desempenho dentro do jogo dependerá da exportação e integração; não foi medido nesta tarefa.

O arquivo foi reaberto no Blender e verificado: imagens e fonte empacotadas, sete câmeras presentes, ausência de bibliotecas externas e de objetos físicos. O resultado dessa verificação está em `validacao_blender.json`; `inventario.json` registra as contagens do projeto.

## Renders entregues

Os PNGs de `01_mapa_completo.png` a `07_vista_alternativa_3d.png` têm resolução de 1800 × 1125 e foram renderizados no Blender com Cycles. Eles correspondem às sete câmeras da tabela. A vista alternativa mostra o mesmo cenário por outro ângulo.

Para futura integração, não crie colisores automaticamente para todas as peças decorativas. Separe o piso transitável e os obstáculos estruturais dos lampiões, flores, adornos e iluminação. Os modelos desta entrega não incluem colisores.

Os scripts usados para construir a arte ficam fora do projeto do jogo, em `C:\Users\roberto.gabriel\.codex\artifacts\circo_3d_20261005`. O arquivo `.blend` pode ser editado sem executar esses scripts.
