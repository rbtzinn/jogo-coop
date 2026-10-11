// Respeitável Público — a página acompanha o espetáculo sem prender a rolagem.
(() => {
  const root = document.documentElement;
  root.classList.add("has-js");
  const motion = matchMedia("(prefers-reduced-motion: reduce)");
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
  const releasePage = "https://github.com/rbtzinn/jogo-coop/releases";
  let release = null;
  let lang = "pt";
  try { lang = localStorage.getItem("rp-lang") || (/^en\b/i.test(navigator.language) ? "en" : "pt"); } catch { /* sem storage */ }

  function updateDownloads() {
    document.querySelectorAll("[data-version]").forEach((el) => {
      el.textContent = release && release.tag ? "· " + release.tag : "";
    });
    if (release === null) return;
    // Sem APK publicado, o Android aparece como "em breve" e o Windows passa a ser o botão principal.
    const noAndroid = !(release && release.android);
    root.classList.toggle("no-android", noAndroid);
    document.querySelectorAll("[data-download]").forEach((a) => {
      const platform = a.dataset.download;
      const asset = release && release[platform];
      const soon = platform === "android" && noAndroid;
      a.href = soon ? "#download" : asset || (release && release.url) || releasePage;
      a.classList.toggle("is-soon", !asset);
      const label = a.querySelector("[data-i18n]");
      const key = asset ? "cta." + platform : soon ? "cta.android.soon" : "cta." + platform + ".versions";
      if (label) { label.dataset.i18n = key; label.textContent = I18N[lang][key]; }
    });
  }
  function applyLang(next) {
    lang = I18N[next] ? next : "pt";
    const dict = I18N[lang];
    root.lang = lang === "pt" ? "pt-BR" : "en";
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const value = dict[el.getAttribute("data-i18n")];
      if (value !== undefined) el.textContent = value;
    });
    document.querySelectorAll("[data-i18n-attr]").forEach((el) => {
      const [attr, key] = el.getAttribute("data-i18n-attr").split(":");
      if (dict[key]) el.setAttribute(attr, dict[key]);
    });
    document.title = dict["meta.title"];
    try { localStorage.setItem("rp-lang", lang); } catch { /* sem storage */ }
    updateDownloads();
  }
  document.querySelector("[data-lang-toggle]").addEventListener("click", () => applyLang(lang === "pt" ? "en" : "pt"));
  fetch("https://api.github.com/repos/rbtzinn/jogo-coop/releases/latest", { headers: { Accept: "application/vnd.github+json" } })
    .then((response) => response.ok ? response.json() : Promise.reject(response.status))
    .then((data) => {
      const assets = data.assets || [];
      const android = assets.find((asset) => /\.apk$/i.test(asset.name));
      const windows = assets.find((asset) => /windows.*\.zip$/i.test(asset.name));
      release = { tag: data.tag_name, url: data.html_url, android: android?.browser_download_url, windows: windows?.browser_download_url };
      updateDownloads();
    })
    .catch(() => { release = false; updateDownloads(); });

  // Menu de celular, com Escape, retorno de foco e links de verdade.
  const nav = document.querySelector(".nav");
  const menuButton = document.querySelector(".menu-toggle");
  const navLinks = [...document.querySelectorAll(".nav nav a")];
  const closeMenu = () => { nav.classList.remove("is-menu-open"); menuButton.setAttribute("aria-expanded", "false"); };
  menuButton.addEventListener("click", () => {
    const open = menuButton.getAttribute("aria-expanded") !== "true";
    nav.classList.toggle("is-menu-open", open);
    menuButton.setAttribute("aria-expanded", String(open));
  });
  navLinks.forEach((a) => a.addEventListener("click", closeMenu));
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && nav.classList.contains("is-menu-open")) { closeMenu(); menuButton.focus(); }
  });
  document.addEventListener("pointerdown", (e) => { if (!nav.contains(e.target)) closeMenu(); });

  // A cortina começa aberta se não houver JavaScript ou a imagem não carregar.
  // Quando a arte está pronta, abre uma única vez. Texto e links ficam na frente.
  const hero = document.querySelector(".hero");
  if (!motion.matches && scrollY < 200) {
    const fabric = new Image();
    fabric.src = "assets/art/curtain-v2.webp";
    fabric.decode().then(() => {
      if (scrollY < 200 && !motion.matches) hero.classList.add("is-entering");
    }).catch(() => { /* o enquadramento aberto continua disponível */ });
  }
  hero.addEventListener("animationend", (e) => {
    if (e.animationName === "curtain-right") hero.classList.remove("is-entering");
  });

  // Galeria do espetáculo: toque e teclado; nenhuma etapa depende de scroll.
  const showSteps = [...document.querySelectorAll(".show-steps li")];
  const showButtons = [...document.querySelectorAll("[data-show]")];
  const showImages = [...document.querySelectorAll(".frame-inner img")];
  function setShow(index) {
    showSteps.forEach((li, i) => li.classList.toggle("is-on", i === index));
    showButtons.forEach((button, i) => button.setAttribute("aria-pressed", String(i === index)));
    showImages.forEach((image, i) => { image.classList.toggle("is-on", i === index); image.setAttribute("aria-hidden", String(i !== index)); });
  }
  showButtons.forEach((button, i) => button.addEventListener("click", () => setShow(i)));
  setShow(0);

  // Cartazes filtrados por área: scroll nativo, também navegável por teclado.
  const track = document.querySelector(".acts-track");
  const cards = [...track.querySelectorAll(".act")];
  const areaButtons = [...document.querySelectorAll("[data-area-filter]")];
  function setArea(area) {
    areaButtons.forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.areaFilter === area)));
    cards.forEach((card) => { card.hidden = card.dataset.area !== area; });
    track.scrollLeft = 0;
  }
  areaButtons.forEach((button) => button.addEventListener("click", () => setArea(button.dataset.areaFilter)));
  setArea("1");

  // O avião usa os oito quadros originais e um percurso suave pelo cenário novo.
  const flight = document.querySelector(".flight");
  const stage = document.querySelector(".flight-stage");
  const plane = document.querySelector(".plane");
  const trail = document.querySelector(".smoke-trail");
  let visibleFlight = false;
  let currentFlight = .5;
  let lastTime = 0;
  let lastPuff = 0;
  let lastX = 0;
  let frameId = 0;
  const request = () => { if (!frameId && !document.hidden) frameId = requestAnimationFrame(frame); };
  function frame(now) {
    frameId = 0;
    if (innerWidth > 900) closeMenu();
    const here = innerHeight * .35;
    let current = null;
    navLinks.forEach((a) => {
      const target = document.querySelector(a.getAttribute("href"));
      if (target && target.getBoundingClientRect().top <= here) current = a;
    });
    navLinks.forEach((a) => a.classList.toggle("is-current", a === current));
    if (motion.matches) return;
    const heroRect = hero.getBoundingClientRect();
    if (heroRect.bottom > 0 && heroRect.top < innerHeight) {
      hero.style.setProperty("--hero-drift", (clamp(-heroRect.top / heroRect.height) * 20).toFixed(1) + "px");
    }
    if (!visibleFlight) return;
    const rect = flight.getBoundingClientRect();
    const target = clamp((innerHeight - rect.top) / (innerHeight + rect.height));
    const dt = Math.min(34, now - lastTime || 16);
    lastTime = now;
    currentFlight += (target - currentFlight) * (1 - Math.exp(-dt / 85));
    if (Math.abs(target - currentFlight) < .0005) currentFlight = target;
    const progress = clamp((currentFlight - .14) / .72);
    const width = plane.offsetWidth;
    const x = -width + progress * (innerWidth + width);
    const y = stage.offsetHeight * .63 - width * .25 - Math.sin(progress * Math.PI) * stage.offsetHeight * .08;
    const angle = -Math.cos(progress * Math.PI) * 7;
    plane.style.setProperty("--px", x.toFixed(1) + "px");
    plane.style.setProperty("--py", y.toFixed(1) + "px");
    plane.style.setProperty("--pr", angle.toFixed(1) + "deg");
    flight.style.setProperty("--sky-drift", ((currentFlight - .5) * -32).toFixed(1) + "px");
    flight.style.setProperty("--cloud-drift", ((currentFlight - .5) * 65).toFixed(1) + "px");
    if (Math.abs(x - lastX) > 3 && now - lastPuff > 100 && progress > .04 && progress < .96 && trail.childElementCount < 16) {
      const puff = document.createElement("i");
      puff.className = "puff";
      puff.style.left = (x + width * .12) + "px";
      puff.style.top = (y + width * .36) + "px";
      trail.appendChild(puff);
      puff.addEventListener("animationend", () => puff.remove(), { once: true });
      lastPuff = now;
    }
    lastX = x;
    if (currentFlight !== target) request();
  }
  new IntersectionObserver(([entry]) => {
    visibleFlight = entry.isIntersecting;
    flight.classList.toggle("is-visible", visibleFlight && !document.hidden);
    if (visibleFlight) {
      const rect = flight.getBoundingClientRect();
      currentFlight = clamp((innerHeight - rect.top) / (innerHeight + rect.height));
      request();
    } else trail.replaceChildren();
  }, { threshold: 0 }).observe(flight);
  addEventListener("scroll", request, { passive: true });
  addEventListener("resize", request);
  motion.addEventListener("change", () => {
    hero.classList.remove("is-entering");
    if (motion.matches) {
      hero.style.removeProperty("--hero-drift");
      trail.replaceChildren();
    }
    request();
  });
  document.addEventListener("visibilitychange", () => {
    flight.classList.toggle("is-visible", visibleFlight && !document.hidden);
    if (document.hidden) { cancelAnimationFrame(frameId); frameId = 0; trail.replaceChildren(); }
    else request();
  });

  // Letreiro de exemplo: anima uma única vez ao entrar na tela.
  const flaps = document.querySelector(".flaps");
  const code = flaps.dataset.code;
  function flipCode() {
    if (motion.matches) return;
    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    [...flaps.children].forEach((span, index) => {
      let tick = 0;
      const limit = 4 + index;
      const timer = setInterval(() => {
        if (motion.matches || document.hidden || tick >= limit) {
          span.textContent = code[index];
          span.classList.remove("flip");
          clearInterval(timer);
          return;
        }
        span.classList.remove("flip");
        void span.offsetWidth;
        span.classList.add("flip");
        span.textContent = alphabet[Math.floor(Math.random() * alphabet.length)];
        tick++;
      }, 75);
    });
  }
  const codeObserver = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) { flipCode(); codeObserver.disconnect(); }
  }, { threshold: .6 });
  codeObserver.observe(flaps);

  // Entradas curtas, limitadas a cada elemento; sem efeitos obrigatórios.
  const reveal = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) { entry.target.classList.add("in"); reveal.unobserve(entry.target); }
    });
  }, { threshold: .08 });
  document.querySelectorAll("[data-reveal]").forEach((el) => reveal.observe(el));

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
    if (!controlsVisible || !controlsSection.contains(document.activeElement)) return;
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
    tabs.forEach((t) => {
      const selected = t.dataset.tab === name;
      t.setAttribute("aria-selected", String(selected));
      t.tabIndex = selected ? 0 : -1;
    });
    document.querySelectorAll("[data-panel]").forEach((p) => { p.hidden = p.dataset.panel !== name; });
    // Ações que não existem no painel (o tiro no celular é automático) ficam apagadas.
    const available = new Set(actionTargets().flatMap((el) => el.dataset.action.split(" ")));
    actionItems.forEach((li) => { li.style.opacity = available.has(li.dataset.action) ? "" : ".35"; });
  }
  tabs.forEach((t) => t.addEventListener("click", () => { showTab(t.dataset.tab); light([]); }));
  tabs.forEach((tab, index) => tab.addEventListener("keydown", (event) => {
    let next;
    if (event.key === "ArrowRight") next = (index + 1) % tabs.length;
    else if (event.key === "ArrowLeft") next = (index + tabs.length - 1) % tabs.length;
    else if (event.key === "Home") next = 0;
    else if (event.key === "End") next = tabs.length - 1;
    else return;
    event.preventDefault();
    showTab(tabs[next].dataset.tab);
    tabs[next].focus();
  }));
  document.querySelector(".keyboard").tabIndex = 0;

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
  stick.addEventListener("lostpointercapture", letGo);

  // ---------- Início ----------
  applyLang(lang);
  showTab(matchMedia("(pointer: coarse)").matches ? "touch" : "keyboard");
  request();
})();
