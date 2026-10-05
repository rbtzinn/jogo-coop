# Reformulação visual — 05/10/2026

Pedido: renovar toda a apresentação usando Blender, manter identidades, regras e desempenho, e publicar cada etapa na main.

Direção: teatro de circo assombrado, veludo vinho (#792f40), noite azul (#101d28), azul-petróleo (#255762), latão envelhecido (#bb8b46), marfim (#e8dac0), luz âmbar (#ffc87a). Limelight nos letreiros, Oswald nos controles e informações. A assinatura é o palco de miniaturas, com ribalta e bilheteria.

## Etapas

- Abertura/carregamento e menu principal.
- Configurações, pausa, loja, Camarim e resultados.
- Parque 3D e atrações modeladas no Blender.
- Cenários próprios dos chefes e percurso do Trem.
- Acabamento dos personagens, chefes e HUD.
- Conferência visual, regressão de gameplay/rede e comparação de desempenho.

## Limites de implementação

Não alterar movimento, dano, hitboxes, plataformas, ataques, fases, progressão, preços, recompensas, saves ou RPCs. Alterações de cena devem se limitar a recursos e nós visuais. Loading é apresentação inicial, sem atraso artificial; os retornos ao menu mantêm seu caminho existente.

Sombras e luzes dos cenários 2D são renderizadas no Blender, depois usadas como texturas. Atrações 3D exportadas em GLB têm detalhes reunidos em uma malha com materiais compartilhados. Não adicionar luzes dinâmicas ao parque. Os projetos Blender podem ser reproduzidos pelos scripts em tools/blender; intermediários .blend ficam em build, fora do Git.

Medições com tools/visual_audit.tscn: janela oculta, 1280×720, qualidade alta, FPS ilimitado, mesmo computador. Save de auditoria separado do save real. Imagens e métricas intermediárias ficam em build/remap. Resultados finais e commits serão registrados aqui.

## Etapa 1 concluída
Abertura com progresso real, menu assimétrico, cenário Blender e filtro de filme mais discreto. Godot import e abertura sem erros; imagem conferida. Menu: 140,2 -> 342,3 FPS; 206,6 -> 50 chamadas de desenho. Amostras curtas locais, não garantia de FPS em outros computadores.


## Etapa 2 concluída
Configurações, pausa/Intervalo, loja, Camarim e resultados reorganizados com cabeçalhos e retratos. Conteúdo e callbacks de compras, equipamento, recompensas e rede preservados. Teste test_shop: zero falhas. Capturas de configurações/loja/Camarim/resultado/pausa conferidas. Animação decorativa dos painéis atualiza só quando visível e a 12,5 Hz.


## Tela de carregamento (referência ilustrada)
Pedido do usuário em 05/10/2026: a abertura igual em espírito a docs/referencias/remap/carregamento_referencia.png. Decisão: usar a própria pintura como arte, separada em camadas por tools/blender/loading_screen.py (só numpy do Blender): palco sem os personagens e com a barra vazia, palhaço e acrobata recortados pelo contorno de tinta, preenchimento dourado da barra e um mapa das lâmpadas. Os polígonos dos recortes são aproximados à mão e o script os encaixa no traço preto.

Vida sem quadros novos (shaders/loading_puppet.gdshader): respiração esticando a partir dos pés, balanço do tronco, os dois braços mexendo em volta do ombro e piscadas com pálpebra desenhada (olho fechado em curva). Lâmpadas da moldura e do letreiro correm em sequência de três; as dos varais oscilam soltas; névoa passa devagar na rua (shaders/loading_stage.gdshader). A barra revela o dourado pelo progresso real do carregamento do menu, sem atraso.

Medição (tools/visual_audit, 1280×720, qualidade alta, mesmo PC): antes 481 FPS, 8 chamadas de desenho; depois 305 FPS (3,3 ms por quadro), 5 chamadas de desenho. O custo extra é o shader em tela cheia; folgado para a UHD 630.

## Etapa 3 concluída: parque pré-renderizado (referência ilustrada)
Pedido de 05/10/2026: o mapa da Área 1 o mais perto possível de docs/referencias/remap/mapa_referencia.png. Os modelos GLB por atração (trabalho anterior, sem commit) foram trocados por uma imagem do parque inteiro renderizada no Cycles, com luz e sombras assadas (lampiões, varais, entradas das tendas, janelas, luar), e um mapa de profundidade de 16 bits. Na Godot, a câmera do mapa é ortográfica com o mesmo ângulo do Blender; um quadrado preso à câmera desenha a imagem e grava a profundidade (shaders/prerendered_backdrop.gdshader), e quem passa atrás de algo vira silhueta dourada (shaders/prerendered_silhouette.gdshader). Sem luzes dinâmicas no parque: uma luz direcional sem sombra só para os bonecos.

Modelado por script (tools/blender/park_kit.py, park_props.py, park_scene.py): tendas listradas do Domador e dos Malabaristas, tenda azul-noite do Mágico com estrelas, carroções do Camarim e da Cartomante, estação com toldo, trilhos e locomotiva, portão em arco com lâmpadas, praça do elefante, cercas, lampiões, varais e bandeirinhas, árvores, pinheiros, arbustos e flores. Os emblemas (leão, malabares, lua), a placa da cartomante e os cartazes são recortes da própria referência. Portas, colisões, chão, trilhas, entradas e voltas das lutas ficaram iguais.

Medição (tools/visual_audit, mapa na entrada, 1280×720, qualidade alta, mesmo PC): linha de base 54,4 FPS e 2366 chamadas de desenho (895 mil primitivas); depois 196 FPS (5,1 ms), 287 chamadas, 111 mil primitivas (quase tudo são os bonecos). Imagem 3840×2112 comprimida na VRAM; profundidade 1920×1056 sem perda.

Testes: run_all (lutas, loja, mapa, trem, itens, nota/save, online normal e com rede ruim) sem falhas.

## Etapa 3b: a pintura de referência como mapa, com os desenhos da luta
Pedido de 05/10/2026: em vez da imagem renderizada no Blender, usar a própria referência (versão limpa, sem personagens nem placas, feita pelo usuário: docs/referencias/remap/mapa_referencia_limpo.jpg, copiada para levels/world/art/park_painted.jpg) e só fazer os personagens andarem por cima, como na imagem. A câmera do mapa ficou parada mostrando o parque inteiro; o chão do mundo casa com o chão pintado (cada pixel da pintura vira um ponto no chão). Onde se anda é desenhado em levels/world/world_area1.gd em pixels da pintura (elipses e trilhas sobre a terra pintada); quem sai dela escorrega pela beira. As portas foram para as entradas pintadas (tapetes do Domador, dos Malabaristas e do Mágico, carroções do Camarim e da Cartomante, escada da estação); o que cada porta faz não mudou. Os corpos de colisão das atrações não bloqueiam mais (quem segura os bonecos é a beira das trilhas).

Personagens: a miniatura 3D foi trocada pelos quadros PNG da luta (parado e corrida), menores (core/world/map_sprite.gd), de frente para a câmera e virando para o lado em que andam. Os quadros parado e corrida ganharam mipmaps para não serrilhar pequenos.

Sem profundidade na pintura: os bonecos ficam sempre na frente do cenário (o arco do portão e os lampiões não os escondem). O Blender do parque (tools/blender/park_*.py) continua no repositório, sem uso.

Medição (tools/visual_audit, 1280×720, qualidade alta): 346 FPS (2,9 ms), 24 chamadas de desenho, 2 mil primitivas (antes 196 FPS e 287 chamadas).

Testes: run_all sem falhas; o teste do mapa anda pelas trilhas pintadas até o Domador.

## Etapa 3c: mapa ampliado em quatro partes, com câmera que acompanha
Pedido de 05/10/2026 (docs/prompts/claude_integrar_mapa_4partes.md): o parque cresceu para um conjunto 2 × 2 de 1672 × 941 pixels (docs/referencias/remap_conceitos/mapa_amplo_4partes/, copiados para levels/world/art/park_0*.png). A tela mostra uma região por vez (620 pixels do conjunto na altura da vista, cerca de 1100 na largura) e a câmera ortográfica segue o meio da dupla, presa para nunca mostrar fora do conjunto. Os dois ficam sempre na tela: cada personagem deste PC guarda uma margem da beira da vista.

As quatro partes são uma malha só com quatro materiais, num plano de frente para a câmera atrás do chão; os cantos saem da mesma conta (pixel_to_world), então as partes vizinhas dividem os mesmos vértices (sem vão nem sobreposição), com filtro linear, sem repetição e sem compressão de VRAM.

Onde se anda: máscara da terra pintada (levels/world/art/park_walk.png, feita por tools/blender/park_walk_mask.py: cor da terra, só o pedaço principal, furos pequenos tapados, entradas acrescentadas à mão e o pilar do portão tirado). Bater na beira leva ao ponto andável mais perto de onde se queria ir: o personagem escorrega pela beira em vez de travar (reclamação do usuário: o andar ficava travado nas paredes). Velocidade no mapa de 2,4 para 4,6 m/s (pedido do usuário: estava lento).

Portas nas entradas pintadas: tapetes do Domador, dos Malabaristas e do Mágico, escada do Camarim, escada da loja e plataforma da estação. Os personagens nascem no pátio logo depois do portão. Como antes, os personagens ficam sempre na frente do cenário (a pintura não tem profundidade).

Medição (tools/visual_audit, 1280×720, qualidade alta): 315 a 368 FPS e 24 a 32 chamadas de desenho nas seis entradas (antes, com a pintura única, 346 FPS e 24 chamadas).

Testes: run_all sem falhas (o teste do mapa anda pela estrada até o Domador e confere que cada ponto da rota está na terra).
