# Respeitável Público

Jogo 2D de ação e plataforma com chefões, ambientado num circo assombrado, para um jogador ou dois em cooperativo online.

Site do jogo: https://respeitavelpublico.vercel.app/

## Como jogar

Cada jogador controla um artista do circo (Palhaço ou Acrobata). A dupla atravessa o parque do circo e a ilha do Vulcão, enfrenta fases de plataforma e luta contra chefões de três fases. Ingressos coletados compram armas e itens na loja, e o progresso fica salvo no PC de quem hospeda.

Controles padrão no teclado (podem ser alterados em **Configurações**):

| Ação | Teclas |
|---|---|
| Mover | WASD ou setas |
| Pular | Espaço ou Z |
| Atirar | J ou X |
| Dash | K ou Shift |
| Travar a mira | L ou C |
| Especial | I ou V |

Para jogar em dupla, os dois precisam da mesma versão. Um escolhe **Hospedar partida** e recebe um código de sala; o outro escolhe **Entrar na partida** e digita o código. No PC também é possível conectar direto por IP.

## Como baixar

As versões ficam nos [Releases do GitHub](https://github.com/rbtzinn/jogo-coop/releases/latest).

- **Windows:** baixe `RespeitavelPublico-Windows.zip`, extraia e abra `RespeitavelPublico.exe`. Não precisa instalar nada. O Windows pode mostrar o aviso "O Windows protegeu o computador" porque o executável não tem assinatura paga; clique em **Mais informações** e depois em **Executar assim mesmo**.
- **Android:** baixe `RespeitavelPublico-Android.apk` pelo navegador do celular e permita instalar apps dessa origem quando o Android pedir. As próximas versões instalam por cima, sem perder o save.

O jogo verifica sozinho se há versão nova nos Releases e oferece o download.

## Arquitetura

```
  Jogador 1 (host)              Relay de salas              Jogador 2 (cliente)
  Godot 4 / GDScript   <--->   Node.js + ws        <--->   Godot 4 / GDScript
  autoridade sobre o    WSS    Docker no Render     WSS    predição local,
  chefão e a partida                                       chefão simulado

  Alternativa no PC: conexão direta por IP (ENet), sem passar pelo relay.
```

- **Jogo (Godot 4.7, GDScript).** Modelo host/cliente com o multiplayer de alto nível da Godot. O host é a autoridade sobre o chefão, as fases da luta e o estado da partida; o cliente envia o próprio movimento e o dano que seus tiros causaram. Sistemas genéricos ficam em `core/` (rede, jogador, save, câmera), peças reutilizáveis em `components/` (hitbox, vida, projéteis, cérebro do chefão) e cada chefão ou fase em sua própria pasta (`bosses/`, `levels/`), sem depender um do outro.
- **Servidor de salas (`server/`).** Node.js 22 com a biblioteca `ws`. Cria salas com código de 6 caracteres, liga host e cliente e repassa os pacotes entre eles, marcando quem enviou. Tem limite de salas, de conexões, de tamanho de pacote e de tráfego por segundo, `/health` para verificação e testes com `node --test`.
- **Hospedagem.** O relay roda em Docker no plano gratuito do Render, configurado em `render.yaml` com deploy automático quando `server/` muda. `server/compose.yaml` sobe o mesmo serviço com Caddy (HTTPS) para quem quiser hospedar em VPS própria.
- **CI (GitHub Actions, `.github/workflows/android-online.yml`).** Em cada push e pull request: testa o servidor, importa o projeto na Godot sem janela, roda os testes de controles de toque, atualização e códigos de sala, e joga uma partida completa com dois processos da Godot conectados pelo relay. Numa tag `v*`, exporta a versão de Windows (ZIP) e a de Android (APK assinado, quando a chave está configurada nos segredos), gera o manifesto `version.json` usado pelo atualizador do jogo e o arquivo `SHA256SUMS.txt`, e publica tudo nos Releases. Quando os dados da Microsoft Store estão configurados, um job numa máquina Windows monta também o pacote MSIX para enviar à Store.
- **Site (`site/`).** Página estática em HTML, CSS e JavaScript, publicada na Vercel.

## Decisões técnicas

**1. Relay próprio por WebSocket em vez de conexão direta.**
Um dos computadores usados nos testes não tinha permissão de administrador, então não dava para abrir porta no firewall nem instalar VPN. Com o relay, os dois PCs fazem só conexões de saída, que passam por qualquer rede. O transporte foi escrito como um `MultiplayerPeerExtension` (`core/network/relay_peer.gd`): para o resto do jogo ele é igual ao ENet, então as mesmas RPCs funcionam pelo relay ou por IP direto, e trocar por outro transporte (por exemplo Steam) não exige mexer no jogo.

**2. Ataques do chefão determinísticos, sincronizados por semente.**
Em vez de enviar a posição de cada projétil, o host envia "o ataque X começou, com esta semente" (`core/network/boss_sync.gd`) e cada PC simula o ataque sozinho. Isso reduz o tráfego a poucas mensagens por ataque e deixa a luta idêntica nas duas telas mesmo com atraso. Só a vida do chefão é reenviada periodicamente, para corrigir mensagens perdidas.

**3. Predição para o jogador local e dano decidido por quem joga.**
Movimento, pulo e tiro do jogador local respondem na hora, sem esperar a rede. O jogador remoto é mostrado 100 ms no passado e interpolado entre os estados recebidos (`core/network/player_sync.gd`), o que esconde pacotes atrasados ou perdidos. A decisão de "fui atingido" é tomada no PC de quem joga, para que ninguém leve dano de algo que já desviou na própria tela.

## Como rodar o projeto

Requisitos: [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), Node.js 22 e Python 3 (só para o teste de partida pelo relay).

```sh
git clone https://github.com/rbtzinn/jogo-coop.git
cd jogo-coop
```

- **Jogo:** abra `project.godot` na Godot e pressione F5. Os presets de exportação (**Windows Desktop** e **Android Preview**) estão em `export_presets.cfg`.
- **Servidor local:**

  ```sh
  cd server
  npm ci
  npm start            # escuta na porta 8080; ws://localhost:8080/relay
  ```

  Para o jogo usar esse servidor numa execução de depuração, defina `GAME_RELAY_URL=ws://127.0.0.1:8080/relay` antes de abrir a Godot.
- **Ferramentas de arte:** os scripts de `tools/` recortam e preparam as artes do jogo a partir das folhas de referência de arte, que não estão no repositório. As artes prontas já estão versionadas, então o jogo e os testes não precisam desses scripts.

## Como rodar os testes

Os testes da Godot são cenas em `tests/` que rodam sem janela e imprimem `FAIL` quando algo dá errado. Defina `GODOT` com o caminho do executável da Godot.

```sh
# Servidor
cd server && npm test

# Todos os testes do jogo, incluindo host e cliente em rede local com e sem simulação de internet ruim
GODOT=/caminho/para/godot sh tests/run_all.sh

# Um teste específico
$GODOT --headless --path . --fixed-fps 60 res://tests/test_tamer.tscn

# Partida completa com dois processos da Godot pelo relay (o mesmo do CI)
GODOT=/caminho/para/godot python3 tests/run_relay.py
```

No Windows (PowerShell): `tests\run_all.ps1 -GodotPath C:\caminho\para\Godot_console.exe`.

## Sobre o desenvolvimento

O código, a arte e a documentação foram produzidos com assistência de ferramentas de IA (Claude, ChatGPT e Codex). A direção do projeto, as decisões de design e os testes de jogo são meus.
