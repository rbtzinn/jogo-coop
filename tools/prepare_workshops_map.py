"""Prepara a pintura, quatro quadrantes, chão navegável, profundidade e cartão do voo.

As superfícies são traçadas sobre a arte nativa (1672 x 941). A máscara usa a mesma
folga, fechamento de pequenos furos e suavização do mapa do Vulcão, para o andador
deslizar pela beira sem prender em vértices. A conferência registra conectividade.
"""
from pathlib import Path
import json
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from smooth_walk_mask import smooth

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/referencias/mapas/area3_oficinas/mapa_completo.png'
ART = ROOT / 'levels/world/art'
QA = ROOT / 'build/qa/workshops'
# Pedido do usuário: sempre mais de20px para fora do pavimento.
# 32px na geração deixam pelo menos24px mesmo após arredondar a beira.
WALK_MARGIN_PIXELS = 32
MIN_CLEARANCE_PIXELS = 24
QA.mkdir(parents=True, exist_ok=True)
SOURCE.parent.mkdir(parents=True, exist_ok=True)
if len(sys.argv) > 1:
    shutil.copy2(sys.argv[1], SOURCE)
im = Image.open(SOURCE).convert('RGB')
assert im.size == (1672, 941), im.size
w, h = im.size
for name, box in zip(['01_noroeste', '02_nordeste', '03_sudoeste', '04_sudeste'],
                     [(0, 0, w//2, h//2), (w//2, 0, w, h//2),
                      (0, h//2, w//2, h), (w//2, h//2, w, h)]):
    im.crop(box).save(ART / f'workshops_{name}.png')
im.resize((600, 338), Image.Resampling.LANCZOS).save(ROOT / 'levels/travel/art/area3.png')

# Pátios e fitas contínuas das estradas, delineados no pavimento pintado.
ground = Image.new('L', im.size)
d = ImageDraw.Draw(ground)
surfaces = [
    # Cais e pista na frente do avião (a água fica inteiramente de fora).
    [(132,605),(220,584),(280,586),(390,613),(489,651),(531,688),(484,747),
     (398,760),(320,733),(216,700),(160,664)],
    # Pátio da Costuraria.
    [(194,305),(285,285),(356,292),(452,257),(492,251),(475,291),(411,326),
     (378,355),(320,354),(253,340)],
    # Caminho curvo leste da Costuraria até o pátio superior.
    [(457,136),(523,152),(581,191),(594,231),(567,262),(523,275),(475,292),
     (491,251),(548,237),(557,215),(538,190),(475,160)],
    # Costuraria até praça central.
    [(351,337),(390,323),(411,357),(433,389),(477,412),(501,447),(522,481),
     (565,518),(613,535),(590,573),(543,555),(506,522),(479,480),(459,447),
     (410,424),(382,389)],
    # Praça superior na frente da torre.
    [(562,252),(638,249),(721,260),(816,252),(849,236),(897,251),(973,254),
     (1046,284),(1080,308),(1038,332),(990,303),(922,292),(829,293),(737,286),
     (654,276),(581,283)],
    # Acesso da torre/coreto até lateral direita do depósito.
    [(1063,295),(1115,310),(1155,304),(1168,280),(1194,285),(1209,313),
     (1179,344),(1143,369),(1111,400),(1092,430),(1119,443),(1163,458),
     (1173,490),(1153,529),(1116,562),(1074,591),(1038,567),(1085,529),
     (1121,490),(1116,470),(1080,455),(1060,430),(1074,396),(1106,353),(1119,331)],
    # Pátio do coreto e ponte de acesso.
    [(1195,244),(1237,256),(1218,282),(1196,305),(1158,293),(1171,271)],
    [(1113,168),(1173,190),(1212,205),(1252,228),(1322,239),(1409,239),
     (1497,252),(1498,279),(1448,298),(1392,305),(1318,290),(1254,270),
     (1204,255),(1179,228),(1120,198)],
    # Praça frontal do depósito (somente chão, abaixo dos cenários).
    [(601,510),(670,526),(739,519),(777,491),(807,473),(838,489),(868,507),
     (928,528),(1014,533),(1087,522),(1098,550),(1048,585),(1004,597),
     (935,583),(855,584),(786,575),(707,566),(642,568),(588,558)],
    # Escadaria entre cais e praça.
    [(475,627),(499,606),(539,585),(560,557),(591,564),(592,584),(563,612),
     (535,635),(517,658)],
    # Caminho inferior e entradas da loja/Camarim.
    [(480,727),(529,712),(568,711),(626,713),(654,702),(718,721),(769,723),
     (817,716),(867,728),(925,730),(971,724),(1003,719),(1018,744),(958,758),
     (887,767),(815,768),(749,764),(675,749),(621,738),(567,738),(525,751)],
    # Ligação direita até teatro e laço inferior.
    [(1025,564),(1058,554),(1088,586),(1143,612),(1196,646),(1233,660),
     (1288,668),(1269,707),(1219,697),(1173,679),(1125,651),(1070,626),
     (1029,600)],
    [(996,723),(1046,704),(1092,706),(1140,696),(1154,666),(1180,675),
     (1178,708),(1147,731),(1105,745),(1050,757),(1009,753)],
    # Teatro: escada e pátio, com margem antes das cercas.
    [(1324,632),(1463,651),(1433,685),(1460,702),(1502,712),(1516,737),
     (1481,765),(1443,781),(1375,788),(1287,766),(1230,743),(1194,713),
     (1220,688),(1286,678)],
]
for polygon in surfaces:
    d.polygon(polygon, fill=255)
mask = np.asarray(ground) > 0
mask = ndimage.binary_closing(mask, iterations=4)
mask = ndimage.binary_opening(mask, iterations=1)
# Mesmo processamento de area2_walk_mask.py, na metade da resolução do mapa.
# Os pixels de origem são o pavimento traçado; controles, aceleração, câmera e
# deslizamento são os mesmos WorldWalker/PaintedWorld já usados nas outras áreas.
keep = mask[::2, ::2].copy()
base_walk = keep.copy()

def fill_small_holes(surface, limit):
    holes, count = ndimage.label(~surface)
    sizes = np.bincount(holes.ravel())
    border = np.unique(np.concatenate([holes[0], holes[-1], holes[:,0], holes[:,-1]]))
    for label in range(1, count+1):
        if label not in border and sizes[label] < limit:
            surface[holes == label] = True

fill_small_holes(keep, 600)
# Distância circular: a margem vale também na diagonal, em curvas e escadas.
keep = ndimage.distance_transform_edt(~keep) <= WALK_MARGIN_PIXELS / 2
keep = ndimage.uniform_filter(keep.astype(np.float32), 7) > 0.5
fill_small_holes(keep, 1500)
keep = smooth(keep)
required_clearance = ndimage.distance_transform_edt(~base_walk) <= MIN_CLEARANCE_PIXELS / 2
assert np.all(keep[required_clearance]), 'Suavização removeu a folga mínima de24px'
# O avião é um obstáculo sólido. A folga dos caminhos não autoriza atravessá-lo.
# A cena contém a mesma caixa como PaintedObstacle, para o corpo deslizar ao redor.
keep[617//2:(691+1)//2, 240//2:398//2] = False
labels, count = ndimage.label(keep)
assert count == 1, f'Chão dividido em {count} partes'
Image.fromarray((keep * 255).astype('uint8')).save(ART / 'workshops_walk.png')
mask = np.repeat(np.repeat(keep, 2, 0), 2, 1)[:h,:w]

# Profundidade por objeto: o shader usa a linha do pé, como no mapa do Vulcão.
front = np.zeros((h, w, 4), dtype='uint8')
objects = [
    ([(151,192),(225,99),(269,47),(386,93),(445,156),(481,225),(448,270),
      (371,279),(298,291),(209,303),(161,282)], 296),
    ([(747,16),(816,16),(863,79),(933,16),(968,132),(991,221),(950,253),
      (895,252),(852,236),(812,253),(767,245)], 253),
    ([(1230,121),(1297,64),(1372,14),(1427,42),(1502,104),(1549,190),
      (1497,243),(1412,237),(1332,234),(1255,216)], 241),
    ([(563,372),(641,311),(782,290),(882,316),(973,335),(1043,387),
      (1070,484),(1015,526),(937,527),(862,509),(808,469),(757,516),(665,520),(596,498)], 524),
    ([(647,630),(710,584),(775,606),(810,636),(808,713),(743,717),(679,699),(643,687)], 716),
    ([(875,647),(931,608),(1014,605),(1058,637),(1051,687),(1009,718),
      (966,715),(912,718),(876,699)], 721),
    ([(1192,561),(1248,439),(1315,355),(1386,368),(1473,348),(1554,399),
      (1630,439),(1671,524),(1668,649),(1550,683),(1465,650),(1326,627),(1270,653),(1215,634)], 655),
    ([(228,619),(272,605),(365,609),(404,645),(387,693),(317,696),(255,668)], 690),
]
for polygon, foot in objects:
    stencil = Image.new('L', im.size)
    ImageDraw.Draw(stencil).polygon(polygon, fill=255)
    selected = np.asarray(stencil) > 0
    front[selected] = [foot & 255, foot >> 8, 0, 255]
Image.fromarray(front).save(ART / 'workshops_front.png')

doors = {'plane':(420,689), 'shop':(742,732), 'dressing':(961,742),
         'carretel':(365,309), 'maestro':(1340,269), 'counterweight':(858,270),
         'scenery':(819,546), 'theater':(1376,710)}
for name, (x,y) in doors.items():
    assert mask[y,x], f'Entrada {name} fora do chão'
vis = np.asarray(im).astype('float32') * 0.55
vis[mask] = vis[mask] * 0.5 + np.array([40,230,120]) * 0.5
preview = Image.fromarray(vis.astype('uint8'))
draw = ImageDraw.Draw(preview)
for name, (x,y) in doors.items():
    draw.ellipse((x-6,y-6,x+6,y+6),fill='yellow')
    draw.text((x+8,y),name,fill='white')
preview.save(QA / 'walk_preview.png')
(QA / 'geometry.json').write_text(json.dumps({'size':im.size,'connected_components':count,
    'walkable_pixels':int(mask.sum()),'margin_pixels':WALK_MARGIN_PIXELS,
    'minimum_clearance_pixels':MIN_CLEARANCE_PIXELS,
    'smoothing':'smooth_walk_mask.smooth (same as area2)', 'doors':doors},indent=2),encoding='utf-8')
print(f'Oficinas: {im.size}, {count} rede conectada, {len(doors)} entradas no chão.')
