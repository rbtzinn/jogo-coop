class_name WaterBalloon
extends ConfettiBall
## Bexiga d'água do Baloeiro Assombrado: cai balançando (dois quadros) e estoura numa poça no teto (`splash`).
## A rosa aceita parry. Desenho do pedido de arte D4, recortado por tools/cut_train_challengers.gd.

const WATER_ART := preload("res://components/enemies/art/water_balloon.tres")
const SPLASH_FRAME := 2

var splashed := false


func _init() -> void:
	art = WATER_ART
	pink_frame = 3
	roll_frames = 2


## Estourou no teto: mostra a poça (o meio dela fica um pouco acima do teto).
func splash() -> void:
	if splashed:
		return
	splashed = true
	art.show_on(_art, SPLASH_FRAME)


func _process(delta: float) -> void:
	if not splashed:
		super(delta)
