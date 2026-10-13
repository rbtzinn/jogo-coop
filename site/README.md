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

Os botões usam a API de Releases para localizar os arquivos reais da versão mais recente.
Sem um arquivo disponível para a plataforma (ou sem resposta da API), o botão passa a dizer
“Ver versões para Windows/Android” e abre a página de versões, sem prometer um download ausente.

## Arquivos

- `index.html`: a estrutura; os textos vêm de `i18n.js` (`data-i18n`).
- `styles.css`: layout responsivo, cortina automática, cartazes e animação em oito quadros do avião.
- `main.js`: idioma, menu acessível, seleção de imagens e áreas, percurso do avião com suavização,
  letreiro ilustrativo, controles interativos e downloads (API do GitHub).
- `assets/shots/`: fotos do jogo, tiradas com `tests/screenshots.tscn -- landing <pasta>`.
- `assets/fonts/`: Limelight e Oswald (as fontes do jogo, licença OFL).

## Visual e interação (11/10/2026)

- Cortina pintada abre uma vez quando sua imagem carrega; texto e botões ficam legíveis na frente.
- Sem seções `sticky`, scroll artificial, mouse animado ou instruções mandando rolar.
- Espetáculo selecionável por botões; atrações por área, com grid no PC e scroll horizontal nativo no celular.
- Voo suave no cenário gerado; sprite original de oito quadros, fumaça limitada a 16 elementos,
  animação pausada fora da tela e em abas ocultas.
- `prefers-reduced-motion` retira entrada, voo animado e transições. Sem JavaScript o conteúdo continua visível.
- Menu com Escape, abas de controles com setas/Home/End, foco visível e link para pular o cabeçalho.
- Os quatro novos WebP somam aproximadamente 983 KiB.

### Verificação

Abrir no PC e no celular; conferir os dois idiomas, menu, seleção do espetáculo, duas áreas de cartazes,
controles e links de versão. Rolar em ambos os sentidos pela viagem e ativar redução de movimento
no sistema: a página deve continuar natural e legível.
