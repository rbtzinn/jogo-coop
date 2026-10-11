# Site do jogo (landing page)

Página estática (HTML, CSS e JS puros, sem build) em português e inglês. Fica fora do jogo: a pasta tem
`.gdignore`, então a Godot não importa nada daqui.

## Publicar na Vercel

1. Em https://vercel.com, **Add New > Project** e importar o repositório `rbtzinn/jogo-coop`.
2. Em **Root Directory**, escolher `site`. Framework: **Other**. Sem comando de build.
3. **Deploy**. Cada push na `main` publica de novo.
4. Endereço atual: https://jogo-coop-site.vercel.app/ (está no `og:image`, `og:url` e `canonical` do
   `index.html`; se mudar de domínio, trocar nos três, senão a prévia do link sai sem imagem).

## Downloads

Os botões apontam para `releases/latest/download/RespeitavelPublico-Windows.zip` e `...-Android.apk`
(os nomes que o workflow de versões publica). Enquanto não houver nenhum Release, a página leva os botões
para a lista de versões e mostra os botões apagados; sem o APK no Release, o botão do Android também.

## Arquivos

- `index.html`: a estrutura; os textos vêm de `i18n.js` (`data-i18n`).
- `styles.css`: visual e as cenas presas à rolagem (`position: sticky` e variáveis CSS).
- `main.js`: idioma, progresso das cenas pela rolagem, letreiro do código, controles interativos e
  a versão mais recente (API do GitHub).
- `assets/shots/`: fotos do jogo, tiradas com `tests/screenshots.tscn -- landing <pasta>`.
- `assets/fonts/`: Limelight e Oswald (as fontes do jogo, licença OFL).
