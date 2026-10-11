// Respeitável Público — interações da página: idioma, cenas presas ao scroll, controles e downloads.
(() => {
  const root = document.documentElement;
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));

  // ---------- Idioma ----------
  let lang = "pt";
  try { lang = localStorage.getItem("rp-lang") || (/^en\b/i.test(navigator.language) ? "en" : "pt"); } catch { /* sem storage */ }

  function applyLang(next) {
    lang = I18N[next] ? next : "pt";
    const dict = I18N[lang];
    root.lang = lang === "pt" ? "pt-BR" : "en";
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const text = dict[el.dataset.i18n];
      if (text !== undefined) el.textContent = text;
    });
    document.querySelectorAll("[data-i18n-attr]").forEach((el) => {
      const [attr, key] = el.dataset.i18nAttr.split(":");
      if (dict[key]) el.setAttribute(attr, dict[key]);
    });
    document.title = dict["meta.title"];
    try { localStorage.setItem("rp-lang", lang); } catch { /* sem storage */ }
    updateDownloads();
  }
  document.querySelector("[data-lang-toggle]").addEventListener("click", () => applyLang(lang === "pt" ? "en" : "pt"));

  // ---------- Versão mais recente (GitHub Releases) ----------
  let release = null;
  function updateDownloads() {
    document.querySelectorAll("[data-version]").forEach((el) => {
      el.textContent = release ? "· " + release.tag : "";
    });
    if (release === false) {
      // Ainda não há versão publicada: os botões levam à página de versões.
      document.querySelectorAll("[data-download]").forEach((a) => {
        a.href = "https://github.com/rbtzinn/jogo-coop/releases";
        a.classList.add("is-soon");
      });
    } else if (release && !release.android) {
      document.querySelectorAll('[data-download="android"]').forEach((a) => {
        a.href = release.url;
        a.classList.add("is-soon");
      });
    }
  }
  fetch("https://api.github.com/repos/rbtzinn/jogo-coop/releases/latest", { headers: { Accept: "application/vnd.github+json" } })
    .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
    .then((data) => {
      const names = (data.assets || []).map((a) => a.name);
      release = { tag: data.tag_name, url: data.html_url, android: names.some((n) => n.endsWith(".apk")) };
      updateDownloads();
    })
    .catch((status) => { if (status === 404) { release = false; updateDownloads(); } });

  // ---------- Cenas presas ao scroll ----------
  // Cada cena tem uma altura maior que a tela e um palco "sticky"; o progresso (0 a 1) é quanto da
  // cena já passou. Só o que está perto da tela é recalculado.
  const scenes = [...document.querySelectorAll("[data-scene]")];
  const progressOf = (el) => {
    const r = el.getBoundingClientRect();
    const span = r.height - innerHeight;
    return span > 0 ? clamp(-r.top / span) : clamp(1 - r.top / innerHeight);
  };

  const hero = document.querySelector(".hero");
  const showSteps = [...document.querySelectorAll(".show-steps li")];
  const showImgs = [...document.querySelectorAll(".frame-inner img")];
  const showTicks = [...document.querySelectorAll(".frame-ticks i")];
  const showFrame = document.querySelector(".frame-inner");
  const acts = document.querySelector(".acts");
  const track = document.querySelector(".acts-track");
  const cards = [...track.children];
  const flight = document.querySelector(".flight");
  const plane = flight.querySelector(".plane");
  const trail = flight.querySelector(".smoke-trail");
  let lastPuff = 0;
  let lastFly = 0;
  const online = document.querySelector(".online");
  const onlineSteps = [...document.querySelectorAll(".steps li")];
  const nav = document.querySelector(".nav");
  const navLinks = [...document.querySelectorAll(".nav nav a")];
  let lastY = scrollY;
  let showIndex = 0;

  function setShow(index) {
    if (index === showIndex) return;
    showIndex = index;
    showSteps.forEach((li, i) => li.classList.toggle("is-on", i === index));
    showImgs.forEach((img, i) => img.classList.toggle("is-on", i === index));
    showTicks.forEach((t, i) => t.classList.toggle("is-on", i === index));
  }

  function frame() {
    const page = clamp(scrollY / (document.documentElement.scrollHeight - innerHeight));
    root.style.setProperty("--page", page.toFixed(4));

    // Navegação some ao descer e volta ao subir.
    nav.classList.toggle("is-hidden", scrollY > lastY && scrollY > innerHeight * 0.8);
    lastY = scrollY;

    if (!reduced) {
      // Cortina abre na primeira metade da cena.
      hero.style.setProperty("--open", clamp(progressOf(hero) * 1.6).toFixed(4));

      // Espetáculo: quatro passos.
      const show = progressOf(document.querySelector(".show"));
      setShow(Math.min(3, Math.floor(show * 4)));
      showFrame.style.setProperty("--tilt", (Math.sin(show * Math.PI * 4) * 0.5).toFixed(3));

      // Atrações: a faixa anda de lado; o cartão mais perto do meio sobe.
      const p = progressOf(acts);
      const max = track.scrollWidth - innerWidth + parseFloat(getComputedStyle(track).paddingLeft);
      track.style.setProperty("--shift", (p * Math.max(0, max)).toFixed(1));
      acts.style.setProperty("--acts", p.toFixed(4));
      const mid = innerWidth / 2;
      let area = 0;
      cards.forEach((card) => {
        const r = card.getBoundingClientRect();
        const d = Math.abs(r.left + r.width / 2 - mid) / (innerWidth * 0.6);
        const lift = clamp(1 - d);
        card.style.setProperty("--lift", lift.toFixed(3));
        if (card.dataset.area === "2") area = Math.max(area, lift);
      });
      acts.style.setProperty("--area", area.toFixed(3));

      // Voo: o avião entra pela esquerda, sobe e desce num arco e sai pela direita; solta fumaça
      // enquanto anda (só quando a rolagem move o avião).
      const f = progressOf(flight);
      flight.style.setProperty("--fly", f.toFixed(4));
      if (f > 0 && f < 1) {
        const w = plane.offsetWidth;
        const x = -w + f * (innerWidth + w * 2);
        const y = innerHeight * 0.66 - Math.sin(f * Math.PI) * innerHeight * 0.12 + Math.sin(f * Math.PI * 6) * 14 - w / 3;
        const tilt = -Math.cos(f * Math.PI) * 8 + Math.cos(f * Math.PI * 6) * 3;
        plane.style.setProperty("--px", x.toFixed(1) + "px");
        plane.style.setProperty("--py", y.toFixed(1) + "px");
        plane.style.setProperty("--pr", (-tilt).toFixed(2) + "deg");
        const now = performance.now();
        if (Math.abs(f - lastFly) > 0.002 && now - lastPuff > 70) {
          lastPuff = now;
          const puff = document.createElement("i");
          puff.className = "puff";
          puff.style.left = (x + w * 0.12) + "px";
          puff.style.top = (y + w * 0.36) + "px";
          trail.appendChild(puff);
          puff.addEventListener("animationend", () => puff.remove());
        }
        lastFly = f;
      }

      // Online: a linha desenha e os passos acendem; no último, o código vira.
      if (innerWidth > 900) {
        const o = progressOf(online);
        online.style.setProperty("--line", o.toFixed(4));
        onlineSteps.forEach((li, i) => li.classList.toggle("is-on", o >= i / 4 - 0.02));
        if (o > 0.45) flipCode(); else resetCode();
      }
    }

    // Link da seção atual.
    const here = scrollY + innerHeight * 0.4;
    let current = null;
    navLinks.forEach((a) => {
      const target = document.querySelector(a.getAttribute("href"));
      if (target && target.offsetTop <= here) current = a;
    });
    navLinks.forEach((a) => a.classList.toggle("is-current", a === current));
  }

  let ticking = false;
  const request = () => { if (!ticking) { ticking = true; requestAnimationFrame(() => { ticking = false; frame(); }); } };
  addEventListener("scroll", request, { passive: true });
  addEventListener("resize", request);

  // ---------- Código da sala (letreiro que vira) ----------
  const flaps = document.querySelector(".flaps");
  const code = flaps.dataset.code;
  const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let flipped = false;
  function flipCode() {
    if (flipped) return;
    flipped = true;
    [...flaps.children].forEach((span, i) => {
      let n = 0;
      const spins = 5 + i * 2;
      const timer = setInterval(() => {
        span.classList.remove("flip"); void span.offsetWidth; span.classList.add("flip");
        span.textContent = n >= spins ? code[i] : ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
        if (n++ >= spins) clearInterval(timer);
      }, 70);
    });
  }
  function resetCode() {
    if (!flipped) return;
    flipped = false;
    [...flaps.children].forEach((span) => { span.textContent = "?"; });
  }
  if (reduced || innerWidth <= 900) {
    new IntersectionObserver((entries) => entries.forEach((e) => e.isIntersecting && flipCode()), { threshold: 0.6 }).observe(flaps);
  }

  // ---------- Entradas suaves ----------
  const reveal = new IntersectionObserver((entries) => {
    entries.forEach((e) => { if (e.isIntersecting) { e.target.classList.add("in"); reveal.unobserve(e.target); } });
  }, { threshold: 0.15, rootMargin: "0px 0px -8% 0px" });
  document.querySelectorAll("[data-reveal]").forEach((el, i) => {
    el.style.transitionDelay = (i % 4) * 80 + "ms";
    reveal.observe(el);
  });

  // ---------- Controles interativos ----------
  const actionItems = [...document.querySelectorAll(".actions li")];
  const actionTargets = () => [...document.querySelectorAll(".panel:not([hidden]) [data-action]")];
  function light(actions) {
    const set = new Set(actions);
    actionItems.forEach((li) => li.classList.toggle("is-lit", set.has(li.dataset.action)));
    actionTargets().forEach((el) => el.classList.toggle("is-lit", el.dataset.action.split(" ").some((a) => set.has(a))));
  }
  actionItems.forEach((li) => {
    li.addEventListener("mouseenter", () => light([li.dataset.action]));
    li.addEventListener("click", () => light([li.dataset.action]));
  });
  document.querySelectorAll(".panel [data-action]").forEach((el) => {
    const list = el.dataset.action.split(" ");
    el.addEventListener("mouseenter", () => light(list));
    el.addEventListener("pointerdown", () => light(list));
  });

  // Teclado de verdade: apertar as teclas acende o desenho (só enquanto a seção está na tela).
  const controlsSection = document.querySelector("#controls");
  let controlsVisible = false;
  new IntersectionObserver(([e]) => { controlsVisible = e.isIntersecting; }, { threshold: 0.3 }).observe(controlsSection);
  const keyOf = (code) => document.querySelector(`.keyboard kbd[data-key="${code}"]`);
  addEventListener("keydown", (e) => {
    if (!controlsVisible) return;
    const key = keyOf(e.code === "ShiftRight" ? "ShiftLeft" : e.code);
    if (!key) return;
    if (e.code === "Space" || e.code.startsWith("Arrow")) e.preventDefault();
    showTab("keyboard");
    key.classList.add("is-down");
    light(key.dataset.action.split(" "));
  });
  addEventListener("keyup", (e) => {
    const key = keyOf(e.code === "ShiftRight" ? "ShiftLeft" : e.code);
    if (key) key.classList.remove("is-down");
  });

  // Abas.
  const tabs = [...document.querySelectorAll("[data-tab]")];
  function showTab(name) {
    tabs.forEach((t) => t.setAttribute("aria-selected", String(t.dataset.tab === name)));
    document.querySelectorAll("[data-panel]").forEach((p) => { p.hidden = p.dataset.panel !== name; });
    // Ações que não existem no painel (o tiro no celular é automático) ficam apagadas.
    const available = new Set(actionTargets().flatMap((el) => el.dataset.action.split(" ")));
    actionItems.forEach((li) => { li.style.opacity = available.has(li.dataset.action) ? "" : ".35"; });
  }
  tabs.forEach((t) => t.addEventListener("click", () => { showTab(t.dataset.tab); light([]); }));
  if (matchMedia("(pointer: coarse)").matches) showTab("touch");

  // Joystick arrastável.
  const stick = document.querySelector(".stick");
  const knob = stick.querySelector("span");
  let dragging = false;
  const moveStick = (e) => {
    const r = stick.getBoundingClientRect();
    let x = e.clientX - (r.left + r.width / 2);
    let y = e.clientY - (r.top + r.height / 2);
    const max = r.width * 0.32;
    const len = Math.hypot(x, y);
    if (len > max) { x = (x / len) * max; y = (y / len) * max; }
    knob.style.setProperty("--sx", x);
    knob.style.setProperty("--sy", y);
  };
  stick.addEventListener("pointerdown", (e) => { dragging = true; stick.setPointerCapture(e.pointerId); moveStick(e); light(["move"]); });
  stick.addEventListener("pointermove", (e) => dragging && moveStick(e));
  const letGo = () => { dragging = false; knob.style.setProperty("--sx", 0); knob.style.setProperty("--sy", 0); };
  stick.addEventListener("pointerup", letGo);
  stick.addEventListener("pointercancel", letGo);

  // ---------- Início ----------
  applyLang(lang);
  showTab(document.querySelector('[data-tab][aria-selected="true"]').dataset.tab);
  frame();
})();
