# Android online

Esta branch prepara salas por código para duas pessoas e consulta de atualização dentro do jogo.
O tiro automático permanece ativo no combate mobile; `SHOW_TEST_MODE` permanece falso.

## Estado

O relay funciona localmente. **Nenhum servidor público foi publicado.** Os endpoints em
`core/network/online_config.gd` estão vazios intencionalmente. A interface explica isso ao tentar
criar/entrar em uma sala ou consultar atualização. Jogar sozinho continua funcionando.

Para publicar falta uma máquina acessível na internet, um hostname HTTPS apontando para ela e
uma chave permanente de assinatura Android. O pacote da beta é
`com.rbtzinn.respeitavelpublico.beta`; a primeira beta é uma instalação separada dos APKs de preview.
Os previews antigos foram assinados com chaves temporárias e não servem como base de atualização.

## Publicar o serviço

1. Criar uma VM Linux e instalar Docker com Compose. Uma VM gratuita pode atender a beta;
   disponibilidade, limites e continuidade dependem do provedor. Não é necessário servidor Godot:
   a simulação permanece no celular de quem cria a sala.
2. Apontar um hostname (inclusive subdomínio gratuito) ao IP da VM. Liberar TCP 80 e 443
   no firewall da VM e do provedor. Não expor 8080 à internet.
3. Copiar a pasta `server` à VM, copiar `.env.example` para `.env`, colocar o hostname real em
   `GAME_HOST` e rodar `docker compose up -d --build` dentro da pasta.
4. Conferir `https://HOST/health`. O Caddy emite o certificado HTTPS; o hostname precisa resolver
   ao IP correto e as portas 80/443 precisam estar acessíveis.
5. Configurar o jogo com `python scripts/configure_android_release.py --host HOST --code 3 --name 0.3-beta`.

O serviço só guarda salas na memória; reiniciar derruba partidas abertas. Limites padrão:
200 salas, 500 conexões, 1 MiB por pacote e 4 MiB/s por conexão. Os códigos não são contas pessoais.
Ambos precisam ficar no jogo e ter internet. O host continua simulando a partida e, ao sair,
encerra a sala. Este transporte usa WebSocket/TCP; perda de rede móvel pode aumentar a latência
por retransmissão. Medir em dois celulares e operadoras diferentes antes de divulgar a beta.
Alterações incompatíveis em RPCs precisam aumentar `PROTOCOL` no cliente e no servidor juntos.

## Assinatura e APK

Criar **uma vez**, em computador confiável, uma keystore release com `keytool -genkeypair`.
Guardar uma cópia segura da keystore e de sua senha; não commitar a chave nem a senha.
Todas as futuras versões desse pacote devem reutilizar a mesma chave.

O workflow `android-online.yml` testa sempre. Só exporta APK quando estão definidos:

- variável de repositório `ANDROID_SERVICE_HOST` (hostname sem `https://`);
- secrets `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEY_ALIAS`,
  `ANDROID_RELEASE_KEY_PASSWORD`.

A senha usada para a keystore e a chave deve ser a mesma no exportador Godot. O workflow usa o
certificado fornecido, verifica o APK e publica um artifact privado de build. Ele não abre o
repositório e não publica automaticamente nada na internet.

## Atualizar

1. Aumentar o código e nome da versão em `online_config.gd` e no preset Android
   (o script `configure_android_release.py` atualiza os dois).
2. Gerar o APK com a mesma assinatura. Baixar o artifact validado.
3. Rodar `python scripts/publish_android_release.py CAMINHO_DO_APK` na versão do código correspondente.
4. Copiar o APK versionado para `server/releases` na VM **antes** de copiar o novo `latest.json`.

O botão **Verificar atualização** consulta o manifest HTTPS. Se houver versão mais recente,
muda para **Baixar atualização** e abre o download no navegador. O usuário abre o APK e confirma
a instalação no Android (com autorização para a origem quando necessário). Não é atualização
silenciosa. Mesma assinatura + mesmo pacote preservam os dados do aplicativo. O sistema valida
a assinatura ao instalar; o SHA-256 no manifest permite conferir o arquivo na publicação.

## Testar

`cd server && npm ci && npm test` verifica limite, isolamento, remetente, saída e reconexão.
`GODOT=/caminho/do/godot python tests/run_relay.py` sobe o servidor local e duas instâncias reais
do jogo, executando o teste de mapa, combate, sincronização e reconexão existente pelo relay.
O teste usa arquivos de save próprios e logs em `build/relay-*.log`.
`res://tests/test_mobile_controls.tscn` verifica multitoque e tiro automático nas cenas reais.
`res://tests/test_android_updates.tscn` verifica manifests de atualização e rejeita versões,
pacotes e URLs inválidos.
