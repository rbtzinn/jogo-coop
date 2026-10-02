class_name Health
extends Node
## Vida genérica (jogadores e chefões). Só guarda o número e avisa quando muda;
## quem decide se pode levar dano (invencibilidade, rede) é o dono.

signal changed(current: int, maximum: int)
signal depleted

@export var maximum := 3

var current := 0


func _ready() -> void:
	current = maximum


func damage(amount: int) -> void:
	set_current(current - amount)


## Usado também para aplicar o valor que chegou pela rede.
func set_current(value: int) -> void:
	var clamped := clampi(value, 0, maximum)
	if clamped == current:
		return
	var was_alive := current > 0
	current = clamped
	changed.emit(current, maximum)
	if was_alive and current == 0:
		depleted.emit()


func is_depleted() -> bool:
	return current <= 0


func ratio() -> float:
	return float(current) / float(maximum)
