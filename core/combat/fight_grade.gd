class_name FightGrade
## Crítica da plateia no fim da luta (docs/combat.md): tempo, vida restante, números em dupla (Número
## Perfeito, Grande Número em Dupla e resgates) e truques (parries e estrelas usadas) viram pontos (de 0 a 100),
## e os pontos viram a nota C, B, A ou S. No cartaz, a nota aparece como a reação da plateia (`verdict`).
## Desde 06/10/2026 (pedido do usuário): antes eram só tempo, vida, parries e estrelas, o mesmo conjunto do
## Cuphead; agora o que a dupla faz junta pesa um quarto da nota.

## Pontos máximos de cada critério na dupla (somam 100).
const TIME_POINTS := 30.0
const HEALTH_POINTS := 25.0
const DUO_POINTS := 25.0
const TRICK_POINTS := 20.0
## Sozinho não há número em dupla: os pontos vão para o tempo, a vida e os truques (somam 100).
const SOLO_TIME_POINTS := 35.0
const SOLO_HEALTH_POINTS := 30.0
const SOLO_TRICK_POINTS := 35.0
## Quantos números em dupla e truques (parries + estrelas usadas) contam no máximo.
const MAX_DUO_ACTS := 3
const MAX_TRICKS := 8
## Pontos mínimos de cada nota (do melhor para o pior).
const GRADES := [["S", 90.0], ["A", 75.0], ["B", 55.0], ["C", 0.0]]
## O que a plateia faz em cada nota (o carimbo do cartaz e o aviso da tenda no mapa).
const VERDICTS := {"S": "Ovação!", "A": "Aplausos", "B": "Palmas", "C": "Silêncio"}


## `target_time`: tempo de uma luta bem jogada (até ele, pontos cheios; no dobro, zero).
static func compute(time: float, target_time: float, health: int, max_health: int, parries: int,
		stars_used: int, duo_acts := 0, solo := false) -> Dictionary:
	var time_share := clampf(2.0 - time / target_time, 0.0, 1.0)
	var health_share := clampf(float(health) / maxf(max_health, 1), 0.0, 1.0)
	var trick_share := float(mini(parries + stars_used, MAX_TRICKS)) / MAX_TRICKS
	var duo_share := float(mini(duo_acts, MAX_DUO_ACTS)) / MAX_DUO_ACTS
	var score := 0.0
	if solo:
		score = SOLO_TIME_POINTS * time_share + SOLO_HEALTH_POINTS * health_share + SOLO_TRICK_POINTS * trick_share
	else:
		score = TIME_POINTS * time_share + HEALTH_POINTS * health_share + DUO_POINTS * duo_share \
				+ TRICK_POINTS * trick_share
	return {
		"time": time,
		"health": health,
		"max_health": max_health,
		"parries": parries,
		"stars_used": stars_used,
		"duo_acts": duo_acts,
		"solo": solo,
		"score": score,
		"grade": grade_for(score),
	}


static func grade_for(score: float) -> String:
	for entry in GRADES:
		if score >= entry[1] - 0.001:
			return entry[0]
	return "C"


## A reação da plateia para uma nota ("" sem nota).
static func verdict(grade: String) -> String:
	return VERDICTS.get(grade, "")


## Posição da nota (S = 3, A = 2, B = 1, C = 0, sem nota = -1), para comparar recordes.
static func rank(grade: String) -> int:
	return ["C", "B", "A", "S"].find(grade)
