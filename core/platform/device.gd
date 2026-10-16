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
