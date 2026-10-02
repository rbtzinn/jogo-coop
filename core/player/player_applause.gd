class_name PlayerApplause
extends Node
## Barra de Aplausos: até 5 estrelas. Enche causando dano ao chefão e com parries
## (+1 estrela cada). As estrelas pagam o Tiro EX (1) e o Grande Número (5).
## Também conta parries e estrelas usadas na luta (para a nota no fim).
## O PC do dono conta; o outro PC só recebe os valores pela rede para mostrar.

const MAX_STARS := 5.0
## Dano que vale 1 estrela.
const DAMAGE_PER_STAR := 45.0

var stars := 0.0
## Parries certos nesta luta (inclui reviver o parceiro).
var parries := 0
## Estrelas gastas nesta luta.
var stars_used := 0


func add_stars(amount: float) -> void:
	stars = clampf(stars + amount, 0.0, MAX_STARS)


func add_damage(amount: float) -> void:
	add_stars(amount / DAMAGE_PER_STAR)


## Gasta estrelas inteiras; retorna falso se não tiver o bastante.
func spend(amount: int) -> bool:
	if stars < amount:
		return false
	stars -= amount
	stars_used += amount
	return true


func full_stars() -> int:
	return int(floor(stars + 0.0001))
