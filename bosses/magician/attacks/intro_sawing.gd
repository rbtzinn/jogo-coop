extends MagicianAttack
## Troca para a fase 2: o mágico faz uma reverência, as luzes piscam e ele volta para o canto
## do palco, já anunciando o próximo número.

const BOW := 0.9
const FLICKER := 1.6
const END := 2.4


func _start() -> void:
	boss.zaratan.set_present(true)
	boss.zaratan.vanish = 0.0


func _tick(t: float) -> void:
	var zaratan := boss.zaratan
	zaratan.pose = &"bow" if t < BOW else &"cast"
	if t >= BOW and t < FLICKER:
		boss.darkness.darkness = 0.6 if int(t * 12.0) % 2 == 0 else 0.0
	else:
		boss.darkness.darkness = 0.0
	if t >= FLICKER and zaratan.global_position != MagicianBoss.HOME:
		Fx.spawn(preload("res://components/fx/dust_puff.tscn"), zaratan.global_position)
		zaratan.global_position = MagicianBoss.HOME
		zaratan.reset_physics_interpolation()
		zaratan.facing = -1
		Fx.spawn(preload("res://components/fx/dust_puff.tscn"), MagicianBoss.HOME)


func _is_done() -> bool:
	return elapsed >= END


func _stop() -> void:
	boss.darkness.darkness = 0.0
	boss.zaratan.global_position = MagicianBoss.HOME
	boss.zaratan.pose = &"idle"
