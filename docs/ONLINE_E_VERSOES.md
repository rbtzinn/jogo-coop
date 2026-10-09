# Online por código e versões

Decidido em 09/10/2026 (pedido do Kawa): salas por código num relay gratuito no **Render** (sem cartão)
e atualização pelos **Releases do GitHub**, no Android e no Windows.

## Estado

O relay (`server/`) e o atualizador funcionam, mas o jogo só usa salas por código quando
`OnlineConfig.RELAY_URL` (`core/network/online_config.gd`) estiver preenchido. Vazio, o menu mantém a
conexão por IP. Jogar sozinho funciona sempre.

## Publicar o relay no Render

1. Criar conta em https://render.com (entrar com o GitHub; o plano gratuito não pede cartão).
2. **New > Blueprint** e escolher este repositório. O `render.yaml` cria o serviço na Virgínia (EUA, a região mais perto do Brasil),
   `respeitavel-publico-relay` (Docker, plano free, pasta `server/`).
3. Quando ficar "Live", abrir `https://<endereço>.onrender.com/health`; deve responder `{"ok":true}`.
4. Gravar o endereço no jogo:
   `python scripts/configure_release.py --code <N> --name <versão> --relay-host <endereço>.onrender.com`.

Limites do plano gratuito: o serviço dorme depois de 15 min sem uso, e a primeira sala depois
disso demora de 30 a 60 s para abrir. Ele só guarda salas na memória; reiniciar derruba as partidas
abertas. O transporte é WebSocket/TCP, então perda de rede móvel pode aumentar a latência.
Mudanças incompatíveis nos RPCs precisam aumentar `PROTOCOL` no cliente e no servidor juntos.

Quem preferir uma VM própria pode usar `server/compose.yaml` (com Caddy para o HTTPS):
copiar `.env.example` para `.env`, colocar o hostname em `GAME_HOST` e rodar `docker compose up -d --build`.

## Chave de assinatura do Android (uma vez)

Sem ela, as versões saem só com o ZIP do Windows. Criar **uma vez**, num computador confiável:

    keytool -genkeypair -v -keystore respeitavel.keystore -alias respeitavel -keyalg RSA -keysize 2048 -validity 10000

Usar a mesma senha para a keystore e para a chave. Guardar uma cópia segura dos dois; sem eles, o
Android não aceita atualizar o app instalado. Nunca commitar a chave. Em **Settings > Secrets and
variables > Actions** do repositório, criar os secrets:

- `ANDROID_RELEASE_KEYSTORE_BASE64`: o arquivo em base64 (`base64 -w0 respeitavel.keystore`);
- `ANDROID_RELEASE_KEY_ALIAS`: `respeitavel`;
- `ANDROID_RELEASE_KEY_PASSWORD`: a senha.

Os APKs de preview antigos usam chaves temporárias e precisam ser desinstalados uma vez.

## Lançar uma versão

1. `python scripts/configure_release.py --code 4 --name 0.4` (o código sempre aumenta).
2. Commit e push no `main`.
3. `git tag v0.4 && git push origin v0.4` (a tag é `v` + o nome).

O workflow `Testes e versões` (`.github/workflows/android-online.yml`) roda os testes, exporta o ZIP do
Windows e, com a chave configurada, o APK, e cria o Release com `version.json` e `SHA256SUMS.txt`.

## Como o jogo atualiza

A versão exportada consulta `releases/latest/download/version.json` ao abrir. Havendo versão nova,
o botão do canto do menu vira **Baixar atualização** e abre o download do Release:

- **Android:** o navegador baixa o APK e o Android pede para confirmar a instalação (na primeira vez,
  autorizar a origem). Mesma chave e mesmo pacote preservam os saves.
- **Windows:** o navegador baixa o ZIP novo; extrair por cima da pasta antiga. Os saves ficam na pasta
  de dados do jogo e não se perdem.

O `version.json` só traz a tag e o nome dos arquivos; o link é sempre montado em
`OnlineConfig.RELEASES_URL`, então um manifest adulterado não leva a outro site.

## Testar

`cd server && npm ci && npm test` verifica limite, isolamento, remetente, saída e reconexão.
`GODOT=/caminho/do/godot python tests/run_relay.py` sobe o servidor local e duas instâncias reais
do jogo, executando o teste de mapa, combate, sincronização e reconexão pelo relay.
`res://tests/test_mobile_controls.tscn` verifica multitoque e tiro automático nas cenas reais.
`res://tests/test_game_updates.tscn` verifica o `version.json` e rejeita versões, pacotes, tags e
arquivos inválidos.
