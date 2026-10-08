# Bigorna de armadura: refazer sem o martelo extra nas costas

Nos 8 quadros da fase 3 (`bosses/anvil_master/art/armor_1.png` a `armor_8.png`) o Mestre Bigorna tem SEMPRE um
martelo grande nas costas, mesmo quando o martelo dele está na mão, girando ou cravado no chão. Fica com dois ou três
martelos na tela. Refazer os mesmos 8 quadros com **um martelo só**, onde a pose pede.

## Regras
- Mesma identidade, cores, armadura e tamanho dos quadros atuais (usar os `armor_*.png` como referência de tudo,
  menos do martelo das costas).
- **Nenhum martelo nas costas, em nenhum quadro.** O martelo existe uma vez por quadro, na mão ou no chão, como
  descrito abaixo.
- Olhando para a ESQUERDA, como os atuais. Pés na mesma linha do chão em todos os quadros.
- Folha 2048 × 1024, grade 4 × 2 de células 512 × 512, um quadro por célula. **Margem vazia de pelo menos 24 px
  entre o desenho e a borda da célula**, inclusive poeira, pedras, fogo e o martelo: na tentativa anterior a poeira
  do quadro 6 invadia o quadro 7 e o martelo do quadro 5 encostava na linha de cima. Se não couber, diminuir o
  personagem por igual em todos os quadros.
- Fundo totalmente transparente (alpha real), sem sombra no chão, sem texto, sem linhas de grade.
- Fazer **só esta folha** neste pedido (não junto com outras).

## Quadros (mesmas poses dos atuais)
1. Vestindo a armadura (mãos no capacete), martelo no chão encostado na perna.
2. Andando com o martelo na mão, cabeça do martelo apoiada no ombro.
3. Andando, o outro passo, martelo no ombro.
4. Girando o martelo com as duas mãos na altura da cintura, com o rastro de fogo em volta (o único martelo é o que gira).
5. Agachado, martelo erguido atrás para o golpe.
6. Pousando do pisão: martelo cravado no chão na frente, poeira e pedras.
7. Peito aberto brilhando, martelo erguido acima da cabeça.
8. Peito aberto levando o golpe (faíscas), martelo na mão caída.

## Arquivo
Salvar em `docs/referencias/pecas/bigorna_armadura_v2.png`.
