class_name BossAttack
extends Node2D
## Base dos ataques de chefão. Cada ataque é uma "linha do tempo": dado o tempo desde o
## início, ele sabe onde tudo está. Assim os dois PCs simulam o mesmo ataque a partir de
## "ataque X começou no tempo T" (com a mesma semente), sem sincronizar cada projétil.

signal finished

## Tempo desde o começo do ataque, em segundos.
var elapsed := 0.0
## Números "aleatórios" iguais nos dois PCs.
var rng := RandomNumberGenerator.new()
## Dados extras escolhidos pelo host (ex.: onde cair, quem perseguir).
var args: Array = []
var _running := false


## `seed_value`: semente combinada pela rede. `skip`: quanto do ataque já passou
## (o cliente recebe a ordem com atraso e adianta a simulação).
func begin(seed_value: int, skip := 0.0, extra_args: Array = []) -> void:
	rng.seed = seed_value
	args = extra_args
	elapsed = 0.0
	_running = true
	_on_begin()
	if skip > 0.0:
		_advance(skip)


func is_running() -> bool:
	return _running


func _physics_process(delta: float) -> void:
	if _running:
		_advance(delta)


func _advance(delta: float) -> void:
	elapsed += delta
	_on_tick(delta)
	if _running and _is_done():
		_running = false
		_on_end()
		finished.emit()


## Para o ataque na hora (troca de fase, fim da luta).
func cancel() -> void:
	if _running:
		_running = false
		_on_end()


## Ponto de um pulo em arco de `from` até `to`, subindo `height` acima da linha reta (u de 0 a 1).
static func arc_point(from: Vector2, to: Vector2, height: float, u: float) -> Vector2:
	return from.lerp(to, u) + Vector2(0, -4.0 * height * u * (1.0 - u))


# --- Para cada ataque sobrescrever ---

func _on_begin() -> void:
	pass


func _on_tick(_delta: float) -> void:
	pass


func _is_done() -> bool:
	return true


func _on_end() -> void:
	pass
