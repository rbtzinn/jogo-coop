class_name FightGrade
## Nota da dupla no fim da luta (docs/combat.md): tempo, vida restante, parries e estrelas
## usadas viram pontos (de 0 a 100) e os pontos viram a nota C, B, A ou S.

## Pontos máximos de cada critério (somam 100).
const TIME_POINTS := 40.0
const HEALTH_POINTS := 30.0
const PARRY_POINTS := 15.0
const STAR_POINTS := 15.0
## Quantos parries e estrelas usadas contam no máximo.
const MAX_PARRIES := 3
const MAX_STARS := 6
## Pontos mínimos de cada nota (do melhor para o pior).
const GRADES := [["S", 90.0], ["A", 75.0], ["B", 55.0], ["C", 0.0]]


## `target_time`: tempo de uma luta bem jogada (até ele, pontos cheios; no dobro, zero).
static func compute(time: float, target_time: float, health: int, max_health: int, parries: int,
		stars_used: int) -> Dictionary:
	var time_part := TIME_POINTS * clampf(2.0 - time / target_time, 0.0, 1.0)
	var health_part := HEALTH_POINTS * clampf(float(health) / maxf(max_health, 1), 0.0, 1.0)
	var parry_part := PARRY_POINTS * mini(parries, MAX_PARRIES) / MAX_PARRIES
	var star_part := STAR_POINTS * mini(stars_used, MAX_STARS) / MAX_STARS
	var score := time_part + health_part + parry_part + star_part
	return {
		"time": time,
		"health": health,
		"max_health": max_health,
		"parries": parries,
		"stars_used": stars_used,
		"score": score,
		"grade": grade_for(score),
	}


static func grade_for(score: float) -> String:
	for entry in GRADES:
		if score >= entry[1] - 0.001:
			return entry[0]
	return "C"


## Posição da nota (S = 3, A = 2, B = 1, C = 0, sem nota = -1), para comparar recordes.
static func rank(grade: String) -> int:
	return ["C", "B", "A", "S"].find(grade)
