# Tiro EX desenhado do palhaço e da acrobata

O Tiro EX (o especial simples: Rolhão, Canhão de Confete, Bolhona, clave grande) hoje usa as poses normais com um coice
feito por código. Queremos o **corpo reagindo ao tiro forte**: preparar, disparar com um coice exagerado e se recompor.
O tiro dura pouco no jogo (o coice leva uns 0,25 s), então as poses precisam ser fortes e fáceis de ler. A animação
não muda nenhum tempo do jogo: o tiro sai no aperto do botão, como hoje.

## Regras (as mesmas das outras folhas, ver `docs/prompts/fila_animacoes_codex.md`)
- Identidade igual às referências: palhaço `docs/referencias/pecas/palhaco_corrida.png` e `core/player/characters/clown/idle/idle_1.png`; acrobata `docs/referencias/pecas/acrobata_corrida.png` e `core/player/characters/acrobat/idle/idle_1.png`. Mesmas cores, proporções e detalhes; só mudam a pose e a cara.
- Folha 2048 × 1024, grade 4 × 2 de células 512 × 512, lidas da esquerda para a direita e de cima para baixo. Um quadro por célula, nada cruza a célula. Células que sobram ficam transparentes.
- Fundo totalmente transparente (alpha real), borda limpa, sem halo. Sem linhas de grade, texto, sombra no chão, borrão ou linhas de velocidade.
- Vista de lado olhando para a DIREITA.
- **Sem o braço da frente (o braço da arma) e sem pistola:** o jogo desenha esse braço e a arma por cima, presos ao ombro. O ombro da frente precisa ficar visível e claro em todos os quadros. Só aparece o braço de trás, sempre ATRÁS do corpo.
- Escala: palhaço uns 406 px da sola ao topo da cartola; acrobata uns 465 px. Sola dos sapatos em y = 486 da célula, corpo centrado por volta de x = 290 (palhaço) ou x = 313 (acrobata).
- Expressão diferente e exagerada em cada quadro.

## Quadros (8 por personagem: linha de cima no chão, linha de baixo no ar)
**Sem preparação:** o tiro sai no mesmo instante em que o jogador aperta o botão. A folha começa JÁ no disparo e
mostra só a reação do corpo ao coice. No chão o personagem desliza um pouco para trás; no ar ele fica **parado
pairando** um instante (como no parry), sem cair, e depois volta a cair.

**Linha de cima, no chão** (sola em y = 486):
1. **Disparo:** o coice joga o corpo para TRÁS: tronco inclinado para trás, um pé saindo do chão, o braço de trás jogado para trás. Olhos fechados com força, boca aberta de esforço. Palhaço: a cartola levanta da cabeça. Acrobata: o coque balança para trás.
2. **Arrastado:** no ponto mais para trás, os dois pés arrastando no chão (sapatos de lado). Cara de susto com a força do tiro.
3. **Recompor:** volta para a frente passando um pouco do ponto, braço de trás balançando. Palhaço: a cartola caindo de volta. Cara aliviada.
4. **Firme de novo:** em pé, peito estufado. Sorriso orgulhoso, piscando um olho.

**Linha de baixo, no ar** (barriga no mesmo ponto em todas: x = 256, y = 280):
5. **Disparo no ar:** o tranco empurra o corpo para trás: tronco inclinado para trás, pernas encolhidas jogadas para a frente, braço de trás aberto. Olhos fechados com força, boca de esforço. Cartola/coque jogados para trás.
6. **Pairando:** parado no ar, corpo espremido pelo coice, pernas balançando soltas. Cara de surpresa, olhos arregalados.
7. **Equilibrando:** ainda pairando, o corpo volta para a frente, braço de trás girando para se equilibrar. Cara aliviada.
8. **Pronto para cair:** corpo reto, pernas esticando para baixo. Sorriso orgulhoso.

## Arquivos (salvar em `docs/referencias/pecas/`)
- `palhaco_tiro_ex.png`
- `acrobata_tiro_ex.png`
