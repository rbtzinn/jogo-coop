# Zaratan — proposta: O Gabinete Sem Fundo

Data: 07/10/2026. Proposta preparada após o usuário pedir uma forma mais diferente para o Mágico, mantendo a dificuldade. **Conceito aprovado visualmente pelo usuário em 07/10/2026; produção e integração ainda pendentes.** O conceito anterior de lanterna e rosto gigante permanece preservado como alternativa anterior.

Imagem: [zaratan_gabinete_conceito.png](../referencias/pecas/magico/gabinete_sem_fundo/zaratan_gabinete_conceito.png). PNG nativo de **1448 x 1086 px**, com fundo transparente real. Gerado pelo Imagegen integrado com referências do Zaratan e do cenário pintado do projeto, seguido de uma revisão de enquadramento. Cópia no projeto idêntica à fonte por SHA-256; nenhuma reamostragem ou integração no jogo foi feita. As peças, margens de produção e pivôs ainda precisam ser preparados separadamente.

## Ideia e apresentação

Na passagem à fase final, Zaratan entra num malão de ilusionista e fecha a tampa. O malão se desdobra num gabinete suspenso de madeira pintada, lona vinho e latão gasto. Dentro dele aparece um corredor de pequenos palcos que parece não ter fim: cortinas dentro de cortinas, gavetas que abrem para lugares impossíveis e rolos de ingressos que se desenrolam sozinhos.

Zaratan continua sendo um artista de tamanho normal. Sua silhueta aparece no fundo do gabinete, apresentando o truque. O alvo principal é o painel aberto e iluminado no centro; não exigir acertar só o pequeno corpo do mágico. Não há rosto gigante, braços ou luvas enormes nem fachada com cara de personagem.

A composição é vertical e irregular, com compartimentos e tecidos, sem transformar o gabinete numa figura humanoide. A lanterna de latão pode iluminar o interior como adereço pequeno. O fundo infinito é uma ilusão pintada em camadas, não uma nova área percorrível.

## Ataques e respostas do jogador

| Ataque atual | Nova apresentação | O que o jogador faz |
|---|---|---|
| Mãos que Agarram | **Carimbos encantados:** carimbos de madeira e latão se deslocam para cima do ponto marcado e descem batendo no chão. A tinta do impacto é somente efeito. | Sair do ponto avisado ou usar dash. |
| Cartola Despejando | **Gaveta sem fundo:** compartimentos no alto se abrem e despejam os adereços atuais numa faixa que percorre o palco. | Acompanhar a faixa segura ou atravessar com dash. |
| Cartas Gigantes | **Ingressos desenrolados:** pequenos mecanismos/rolos aparecem nas posições de lançamento e soltam os bilhetes encantados em salvas alternadas. | Ler a abertura entre os projéteis e usar os bilhetes turquesa para parry. |

Carimbos e rolos são objetos de truque, não membros permanentes pendurados nos lados do gabinete. Na futura integração, os avisos e a preparação de cada golpe precisam permanecer visíveis durante as mesmas janelas atuais. Esconder objetos não deve esconder os sinais que o jogador usa para reagir.

## Dificuldade: referência conferida no código

| Parâmetro | Referência a manter na primeira implementação |
|---|---|
| Vida e divisão das fases | 1280; 35% / 30% / 35%. Preservar as duas primeiras fases nesta mudança. |
| Alvo atingível da fase final | Retângulo de 280 x 360, centro atual (960, 420). O painel central precisa corresponder visualmente à área; não fechar a vulnerabilidade durante ataques. |
| Área de dano dos golpes descendentes | 220 x 220, deslocamento local (0, 60), com a mesma ativação por estado. Ajustar a arte ao perigo real, sem inventar dano nos cabos ou na tinta. |
| Sequência dos golpes | Inícios em 0,3 / 0,9 / 1,5 / 2,1 s, posições dos jogadores amostradas no começo; ordem P1, P2, P2, P1 quando os dois estão de pé. |
| Preparação e golpe | Movimento 0,6 s, espera 0,15 s, descida 0,15 s, permanência 0,35 s e retorno 0,5 s. Preservar a resolução atual quando a mesma peça recebe um golpe novo antes de terminar o anterior. |
| Chuva de adereços | Preparação 0,6 s, faixa atravessando em 3 s, emissão a cada 0,11 s, gravidade 1800, origem y = -60 e extremos x = 260 / 1660. Mesmos objetos, avisos e parry. |
| Salvas de bilhetes | Quatro salvas em 0,6 / 1,4 / 2,2 / 3 s; cinco direções de 8° a 56°, uma abertura por salva, velocidade 680. Preservar posições de emissão, variantes e alternância atuais. |
| Jogo e rede | Mesmas plataformas, movimento, dano, recompensa, regras de parry, escolha de ataques e autoridade do host. Não introduzir nova aleatoriedade no cliente. |

Fontes: `bosses/magician/magician_boss.gd`, `magician_boss.tscn`, `attacks/grab_hands.gd`, `hat_pour.gd` e `giant_cards.gd`.

Preservar números fornece uma base para conservar a dificuldade; a arte também muda a percepção dos avisos. Depois da integração, conferir a luta com os mesmos controles e comparar legibilidade, janelas de reação e oportunidades de tiro. Testes automáticos não substituem essa avaliação jogando.

## Encerramento

Quando perde, Zaratan tenta fechar o gabinete, mas as gavetas recolhem uma dentro da outra e o malão volta ao tamanho inicial. Ele fica preso dentro, dá uma última batida na tampa e o ingresso dourado sai pelo picote de um rolo. Preservar a recompensa e o tempo de conclusão da luta na integração inicial.

## Direção para o futuro conceito de arte

- Madeira de circo pintada e remendada, ferragens de latão, lona vinho, papéis creme e luz âmbar. Turquesa luminoso reservado ao parry.
- Gabinete irregular suspenso, com abertura vertical central. Mostrar o mágico pequeno no interior para explicar a escala; não acrescentar uma cabeça no topo nem transformar as laterais em braços.
- Carimbo isolado e rolo de ingressos mostrados como peças de truque; evitar a disposição de dois objetos enormes flanqueando uma cabeça.
- Pintura e contorno do próprio projeto. Detalhes de costura, etiquetas sem texto e mecanismos simples; sem estética de cassino, máquina caça-níquel ou tecnologia futurista.
- Na implementação, o cenário dentro do gabinete é decorativo. Não desenhar saídas ou plataformas utilizáveis que não existam na luta.
- Gerar primeiro um conceito completo para avaliar a composição. As peças de produção devem ser pedidas depois que a forma estiver escolhida.
