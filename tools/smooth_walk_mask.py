# Alisa a beira de uma máscara de onde se anda no mapa (branco = estrada): tira os "dentes" e as pontinhas de
# poucos pixels que a leitura pela cor deixa na beira. Num dente o boneco entrava e não saía mais (curva da
# frente da mina na Área 2, 07/10/2026). É um borrão quadrado seguido de corte no meio (como uma mediana):
# a beira continua no mesmo lugar, só fica lisa.
# Uso: python -I tools/smooth_walk_mask.py <máscara.png> [passadas]
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

SIZE = 9


def smooth(mask, passes=2):
    """`mask`: matriz booleana. Devolve a máscara alisada."""
    for _ in range(passes):
        mask = ndimage.uniform_filter(mask.astype(np.float32), SIZE) > 0.5
    return mask


if __name__ == "__main__":
    path = sys.argv[1]
    passes = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    image = np.array(Image.open(path).convert("L")) > 127
    result = smooth(image, passes)
    Image.fromarray((result * 255).astype(np.uint8)).save(path)
    print("%s: %d pixels mudaram" % (path, int((result != image).sum())))
