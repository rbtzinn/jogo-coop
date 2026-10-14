# Maestro Ferrugem — produção por partes

P01: desenho-base original do regente mecânico das Oficinas. PNG nativo1254×1254,
RGBA com alfa real, mais de100px de respiro no contorno visível. Identidade própria:
rosto esmaltado, bigode/cabelo de cobre, casaca azul-petróleo, duas mãos, batuta,
duas pernas articuladas e três tubos de órgão.

Gerado e revisado com a habilidade Imagegen e ferramenta integrada. Primeira versão
e base revisada preservadas em `docs/referencias/pecas/oficinas/maestro/`.
O arquivo usado pela Godot é `art/p01_base.png`, copiado sem alterar os pixels.
Prompt completo e continuidade em `docs/prompts/maestro_ferrugem_arte_partes.md`.

Abra `res://tools/maestro_art_preview.tscn` e F6. L troca fundo, H oculta textos,
setas comparam a direção e R restaura. A prévia não altera saves da campanha.
Sprite reutilizável: `rust_maestro_visual.tscn`, pivô y0 na sola inferior.

Esta entrega é SOMENTE a primeira peça de arte. A porta DoorMaestro no mapa
continua reservada, sem target_scene de combate. Ainda não há luta/animações.

Próximas peças: espera/regência, avisos e ataques, transição de órgão e derrota;
efeitos próprios de notas/parry turquesa, ondas graves e batuta; cenário clean;
por último luta comum a desktop/mobile/rede, combos avisados, brilho curto ao levar
tiro, parede anti-costas e testes contra ficar parado atirando. Produzir e conferir
cada conjunto separadamente, mantendo a identidade da base.

Teste: `tests/test_maestro_art.tscn`. Captura: `build/qa/maestro/p01_preview.png`.
Nenhum código da Madame, jogadores ou outras lutas alterado nesta etapa.
