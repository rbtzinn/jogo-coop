class_name Spring
extends RefCounted
## Mola amortecida para movimento secundário (chapéu balançando, cabeça atrasada, coice): o valor persegue o
## alvo com atraso e passa um pouco do ponto antes de assentar. `kick` dá um tranco (soma velocidade).

var value := 0.0
var speed := 0.0
## Força que puxa para o alvo (maior = mais rápido) e freio (maior = balança menos).
var stiffness := 200.0
var damping := 14.0


func _init(new_stiffness := 200.0, new_damping := 14.0) -> void:
	stiffness = new_stiffness
	damping = new_damping


func step(target: float, delta: float) -> float:
	speed += ((target - value) * stiffness - speed * damping) * delta
	value += speed * delta
	return value


func kick(impulse: float) -> void:
	speed += impulse
