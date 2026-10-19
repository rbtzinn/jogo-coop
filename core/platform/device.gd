class_name Device
extends RefCounted
## Onde o jogo está rodando. Na versão de navegador (16/10/2026) a Godot não marca "mobile" no celular:
## o sistema vem nas marcas web_android/web_ios, e o iPad se apresenta como Mac, então vale a tela de toque.


## Celular ou tablet, no app ou no navegador: controles de toque e menus maiores.
static func is_touch() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return OS.has_feature("web_macos") and DisplayServer.is_touchscreen_available()


static func is_web() -> bool:
	return OS.has_feature("web")


## Janela própria (modo de tela, tamanho, VSync): só o jogo de PC instalado.
static func has_window() -> bool:
	return not OS.has_feature("mobile") and not is_web()


## O navegador não deixa um jogo fechar a aba.
static func can_quit() -> bool:
	return not is_web()


## Navegador do iPhone (o iPad se apresenta como Mac e já deixa pôr em tela cheia).
static func is_ios_web() -> bool:
	return OS.has_feature("web_ios")


## Aberto pelo ícone da Tela de Início (modo app, sem as barras do navegador).
static func is_installed_web_app() -> bool:
	if not is_web():
		return false
	return bool(JavaScriptBridge.eval("window.navigator.standalone === true"
		+ " || window.matchMedia('(display-mode: standalone)').matches"
		+ " || window.matchMedia('(display-mode: fullscreen)').matches", true))


## Bordas da tela que o sistema ocupa (entalhe da câmera, cantos arredondados, barra de status e a barrinha de
## Início do iPhone), em unidades da tela do jogo: x esquerda, y cima, z direita, w baixo.
## Só no navegador; vem do CSS env(safe-area-inset-*), que vale porque a página usa viewport-fit=cover.
static func safe_insets(visible_size: Vector2) -> Vector4:
	if not is_web():
		return Vector4.ZERO
	var measured = JavaScriptBridge.eval("""(function () {
		var probe = document.createElement('div');
		probe.style.cssText = 'position:fixed;left:0;top:0;visibility:hidden;pointer-events:none;'
			+ 'padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';
		document.body.appendChild(probe);
		var style = getComputedStyle(probe);
		var values = [style.paddingLeft, style.paddingTop, style.paddingRight, style.paddingBottom].map(parseFloat);
		probe.remove();
		return values.concat([window.innerWidth, window.innerHeight]).join(',');
	})()""", true)
	if not measured is String:
		return Vector4.ZERO
	var values: PackedFloat64Array = (measured as String).split_floats(",")
	if values.size() < 6:
		return Vector4.ZERO
	return insets_in_game(Vector4(values[0], values[1], values[2], values[3]), Vector2(values[4], values[5]), visible_size)


## Bordas do sistema medidas na página (`css`: esquerda, cima, direita, baixo, numa página de tamanho `page`)
## convertidas para a tela do jogo. A tela do jogo mantém a proporção, centralizada: só conta o que a borda
## invade além das faixas pretas.
static func insets_in_game(css: Vector4, page: Vector2, visible_size: Vector2) -> Vector4:
	if page.x <= 0.0 or page.y <= 0.0:
		return Vector4.ZERO
	var fit := minf(page.x / visible_size.x, page.y / visible_size.y)
	var band := (page - visible_size * fit) * 0.5
	return Vector4(maxf(css.x - band.x, 0.0), maxf(css.y - band.y, 0.0),
		maxf(css.z - band.x, 0.0), maxf(css.w - band.y, 0.0)) / fit
