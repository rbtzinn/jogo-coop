class_name RustMaestroBoss
extends BossBrain
## Maestro Ferrugem (Área 3): rege a luta num compasso. Todo ataque dura um número inteiro de tempos (BEAT) e o
## respiro entre ataques é um tempo, então os golpes caem na batida do metrônomo do palco.
## Fases: Afinação (pauta, batuta, metrônomo), Crescendo (o órgão das costas acorda: ondas graves e colcheias)
## e Fortíssimo (tubos de órgão do chão, combos mais rápidos e a reverência com a caixa de música aberta).

## Um tempo do compasso (100 batidas por minuto).
const BEAT := 0.6
const HOME := Vector2(1610, 930)
const FLOOR := 930.0
const PLAY_LEFT := 27.0
const PLAY_RIGHT := 1473.0

var started := false
## Tempo desde o começo do último ataque (zera nos dois PCs no começo de cada um): marca o compasso.
var beat_clock := 0.0

@onready var actor: MaestroActor = $Actor


func _init() -> void:
	max_health = 1250
	intro_time = BEAT * 4
	pause_between_attacks = Vector2(BEAT, BEAT)
	phase_shares = [0.34, 0.33, 0.33]
	phase_titles = ["Afinação", "Crescendo", "Fortíssimo"]
	# Toda fase tem uma pauta (notas nas três alturas, de uma parede à outra): ninguém fica parado seguro.
	phase_attacks = [[&"Staff", &"Baton", &"Metronome"],
		[&"StaffWaves", &"Waves", &"Eighths"],
		[&"StaffEighths", &"Pipes", &"BatonWaves"]]
	phase_intros = [&"", &"IntroOrgan", &"IntroFinale"]


func _ready() -> void:
	super()
	z_index = 2
	actor.position = HOME
	connect_hurtbox(actor.hurtbox, actor)
	connect_hurtbox(actor.chest, actor, "chest")


func _physics_process(delta: float) -> void:
	beat_clock += delta
	actor.beat_clock = beat_clock
	actor.hitbox.active = started and not is_defeated
	super(delta)


func play_attack(attack_name: StringName, seed_value: int, skip: float, extra: Array = []) -> void:
	started = true
	beat_clock = skip
	super(attack_name, seed_value, skip, extra)


func _args_for(_attack_name: StringName) -> Array:
	var players := alive_players()
	players.sort_custom(func(a: Player, b: Player) -> bool: return a.slot < b.slot)
	var targets: Array = []
	for player in players:
		# Alvo travado no aviso: depois do disparo nada persegue o jogador.
		targets.append(Vector2(clampf(player.global_position.x, PLAY_LEFT, PLAY_RIGHT),
			clampf(player.global_position.y - 55.0, 180.0, FLOOR - 35.0)))
	return targets


## Visual de cada fase: o órgão das costas solta vapor a partir da fase 2.
func set_stage(index: int) -> void:
	actor.organ_awake = index >= 1


func apply_damage(amount: int, source := "", part := "") -> void:
	super(amount * (2 if part == "chest" and actor.chest_open else 1), source, part)


func _on_catch_up() -> void:
	actor.position = HOME
	set_stage(phase)
	actor.idle()


func _on_defeated() -> void:
	actor.defeat()
