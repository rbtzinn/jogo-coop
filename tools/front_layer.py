# Camada da frente de um mapa pintado (levels/world/art/<nome>_front.png): o que é alto no desenho (pedras,
# cristais, postes) e a linha do pé de cada pedaço. No jogo (shaders/painted_front.gdshader), cada pixel dessa
# camada fica na profundidade do chão no pé dele: quem anda atrás (mais para cima na tela que o pé) some atrás
# da pedra; quem está na frente passa por cima. Não muda onde se anda (pedido do usuário em 06/10/2026: a pedra
# tem que ficar por cima do personagem, sem travar a passagem).
# Saída RGBA, do tamanho do mapa: R + G * 256 = linha do pé (y em pixels do mapa), A = 255 onde é alto.
# Alto = escuro, roxo-acinzentado (basalto) ou vermelho de cristal, e não é estrada. Chão chato (cinza marrom,
# lava) fica de fora: a linha do pé é onde a coluna de pixels altos acaba, descendo.
# Uso: python tools/front_layer.py docs/referencias/mapas/area2_vulcao_aviao/mapa_completo.png \
#   levels/world/art/volcano_front.png [pasta para a conferência]
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

src, final = sys.argv[1:3]
a = np.asarray(Image.open(src).convert("RGB"), dtype=np.float32) / 255.0
h, w = a.shape[:2]
r, g, b = a[..., 0], a[..., 1], a[..., 2]
mx = a.max(-1); mn = a.min(-1)
sat = (mx - mn) / np.maximum(mx, 1e-4)
road = ndimage.uniform_filter(((mx > 0.55) & (sat < 0.2)).astype(np.float32), 11) > 0.35
dark = mx < 0.27
basalt = (b >= g * 0.95) & (mx < 0.5)
crystal = (r > 0.45) & (g < 0.35 * r) & (b < 0.5 * r)
tall = (dark | basalt | crystal) & ~road
tall = ndimage.binary_opening(tall, iterations=2)
tall = ndimage.binary_closing(tall, iterations=3) & ~road
# Linha do pé: descendo cada coluna, onde a sequência de pixels altos acaba.
foot = np.zeros((h, w), np.int32)
below = np.zeros(w, np.int32)
for y in range(h - 1, -1, -1):
    goes_on = tall[y] & (tall[y + 1] if y + 1 < h else False)
    below = np.where(goes_on, below, y + 1)
    foot[y] = np.where(tall[y], below, 0)
out = np.zeros((h, w, 4), np.uint8)
out[..., 0] = foot & 255
out[..., 1] = foot >> 8
out[..., 3] = np.where(tall, 255, 0)
Image.fromarray(out, "RGBA").save(final)
if len(sys.argv) > 3:
    vis = a * 0.5
    vis[tall] = vis[tall] * 0.4 + np.array([1.0, 0.1, 0.6]) * 0.6
    Image.fromarray((vis * 255).astype(np.uint8)).resize((w // 2, h // 2)).save(sys.argv[3] + "/front_vis.png")
print("alto:", round(float(tall.mean()) * 100, 1), "% do mapa")
