Olá! Este é o começo de um projeto de jogo. Antes de qualquer coisa, leia `CLAUDE.md` e `docs/DESIGN.md` nesta pasta. Eles resumem tudo o que já conversei e decidi com outra sessão do Claude.

Resumo rápido:
- Jogo 2D de plataforma com chefões (boss fights), no estilo Cuphead, cooperativo online para 2 jogadores (eu e um amigo).
- Lutas intensas contra chefões com várias fases, controle preciso, visual com estilo forte (shaders e animações bonitas que não atrapalham a jogabilidade).
- Antes a ideia era um jogo 3D em primeira pessoa estilo It Takes Two, mas troquei por este, que é mais simples de produzir. A ideia de um jogador depender do outro pode aparecer em alguns chefões.
- Engine Godot 4 + GDScript. Multiplayer host/cliente pela internet usando Tailscale (eu estou em Suape-PE e meu amigo em Olinda-PE). Save local no PC do host. Custo zero: sem Steam por enquanto, só assets gratuitos.
- Vamos construir por partes, um chefão de cada vez, seguindo o roadmap do DESIGN.md.

Estamos na etapa 1 (Conceito). Ainda falta decidir: estilo visual, tema e história, quanto um jogador depende do outro, mecânicas do jogador, placa de vídeo dos PCs e nome do jogo.

O que eu quero agora:
1. Confirme em poucas linhas que você entendeu o projeto.
2. Me ajude a fechar as decisões em aberto: me faça as perguntas uma de cada vez e dê sua recomendação em cada uma.
3. Registre cada decisão no `docs/DESIGN.md`.
4. Quando o conceito estiver fechado, me guie na instalação da Godot 4 e do Git, inicialize o repositório e comece a etapa 2 (base jogável: dois jogadores pulando e atirando no mesmo cenário, conectados online).

Explique tudo em português, passo a passo. Sou iniciante em Godot.
