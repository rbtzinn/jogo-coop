# CLAUDE.md

Contexto do projeto para o Claude Code. Ler antes de qualquer tarefa.

## O projeto

**Respeitável Público**: jogo 2D de plataforma com chefões (boss fights) num circo assombrado, estilo Cuphead, cooperativo online para 2 jogadores, feito na **Godot 4** com **GDScript**. Design completo, decisões e roadmap em [docs/DESIGN.md](docs/DESIGN.md) — ler sempre e manter atualizado.

O usuário é o diretor e testador; o Claude escreve código, shaders, roteiro e documentação. O Claude não vê o jogo rodando: depende do feedback do usuário depois de cada teste.

## Idioma

- Conversa, documentação, diálogos do jogo e mensagens de commit: **português do Brasil**.
- Nomes no código (variáveis, funções, classes, arquivos): inglês, seguindo o padrão da Godot (snake_case para arquivos/funções/variáveis, PascalCase para classes/nós).

## Arquitetura (regras)

- **Separar motor de conteúdo.** Sistemas genéricos em `core/`, peças reutilizáveis em `components/`, cada chefão em `bosses/<nome>/` e cada fase de plataforma em `levels/<nome>/`. Um chefão ou fase nunca depende de outro.
- Antes de escrever código novo para um chefão ou fase, verificar se já existe componente que resolve. Se o comportamento puder ser reusado, criar componente.
- Scripts pequenos, com uma responsabilidade cada.
- Diálogos e textos da história em arquivos de dados (`dialogues/`), não hardcoded.
- Shaders em `shaders/`.

Estrutura planejada:

```
core/          # player, network, save, camera, dialogue
components/    # hitbox, hurtbox, health, projectile, attack_pattern, parry...
shaders/
dialogues/
bosses/        # um chefão por pasta (cena, fases da luta, ataques)
levels/        # fases de plataforma e mapa de seleção
docs/          # DESIGN.md
```

## Multiplayer (regras)

- Modelo **host/cliente**, high-level multiplayer da Godot (ENet). O host é autoridade sobre o chefão, as fases da luta e o estado da partida.
- Conexão por IP (os jogadores usam Tailscale). Manter a camada de rede isolada em `core/network/` para permitir adicionar Steam (GodotSteam) no futuro sem refazer o resto.
- Movimento, pulo e tiro do jogador local com predição no cliente (resposta instantânea); jogador remoto e projéteis com interpolação.
- Ataques do chefão preferencialmente determinísticos: o host envia "ataque X começou no tempo T" e cada PC simula, em vez de sincronizar cada projétil.
- Detecção de dano favorável a quem joga (evitar dano por algo já desviado na tela do cliente).
- Ações que exigem simultaneidade usam janela de tolerância.

## Save

Arquivo local no PC do host: chefões vencidos, área atual, upgrades/equipamentos de cada jogador. Salvar automaticamente ao vencer um chefão e ao voltar para o mapa.

## Fluxo de trabalho

- Trabalhar por etapas do roadmap em docs/DESIGN.md; não pular etapas.
- Controle do jogador é prioridade: precisa ser responsivo (coyote time, buffer de pulo etc.).
- Ao final de cada tarefa: dizer exatamente o que o usuário deve testar na Godot e o que esperar.
- Usar git; commits pequenos e descritivos.
- Ao tomar uma decisão de design com o usuário, registrar em docs/DESIGN.md.
- Custo zero: só ferramentas e assets gratuitos.
