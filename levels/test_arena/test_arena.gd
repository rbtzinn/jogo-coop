extends Node2D
## Arena de teste de movimento. No modo "Testar sozinho", Tab troca qual personagem você controla
## (nó SoloCharacterSwitch).

@onready var _hint: Label = $Hud/HintLabel


func _ready() -> void:
	if Network.is_online():
		_hint.text = "Esc / Start: pausa e configurações"
