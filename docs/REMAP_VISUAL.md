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
