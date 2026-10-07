extends PhoenixAttack
## Troca para a fase 3, "Renascimento": ela se enrola nas próprias asas e vira um ovo gigante incandescente no
## ninho; o fundo pega fogo. Daqui em diante só as duas rachaduras do ovo levam tiro (Casca Dupla).

const WRAP := 0.9
const SETTLE := 0.5


func _start() -> void:
	bird.set_mode(Phoenix.Mode.EGG)
	bird.facing = -1
	bird.global_position = EGG
	bird.reset_physics_interpolation()
	boss.set_stage(2, true)
	boss.reset_shell()


func _tick(t: float) -> void:
	bird.pose(&"egg", 0 if t < WRAP else 1)
	bird.shake = 0.5 if t < WRAP else 0.0


func _is_done() -> bool:
	return elapsed > WRAP + SETTLE
