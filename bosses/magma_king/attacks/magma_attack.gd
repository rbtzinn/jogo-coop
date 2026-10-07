class_name MagmaAttack
extends BossAttack
## Base dos ataques do Rei Magma: acesso ao chefão, ao rei e ao chão, e a criação dos objetos.

const FLOOR_Y := 1000.0
## Tempo andando no lago antes de cada ataque da fase 2.
const WADE := 0.8
## Jangadas da arena (meio em x e tampo em y; batem com RaftLeft/RaftRight de magma_king_fight.tscn)
## e metade da largura do tampo.
const RAFTS := [Vector2(620, 760), Vector2(1260, 760)]
const RAFT_HALF := 160.0


## Onde algo que cai em `x` para: no tampo de uma jangada, se tiver uma ali, ou no chão.
static func surface_y(x: float) -> float:
	for raft: Vector2 in RAFTS:
		if absf(x - raft.x) <= RAFT_HALF:
			return raft.y
	return FLOOR_Y

var boss: MagmaKingBoss
var king: MagmaKing


func _ready() -> void:
	boss = get_parent().get_parent()
	king = boss.get_node("King")


func _on_begin() -> void:
	_start()


func _on_tick(_delta: float) -> void:
	_tick(elapsed)


func _on_end() -> void:
	_stop()
	for child in get_children():
		if child is MagmaProp:
			child.queue_free()
	if not boss.is_defeated:
		king.idle()


## Cria um objeto deste ataque. `index` identifica o objeto nos dois PCs (parry).
func spawn(kind: StringName, at: Vector2, pink := false, index := 0) -> MagmaProp:
	var prop := MagmaProp.new()
	prop.kind = kind
	prop.pink = pink
	prop.parry_id = "%s:%d:%d" % [name, run_seed, index]
	add_child(prop)
	prop.global_position = at
	prop.reset_physics_interpolation()
	return prop


## No lago (fase 2), cada ataque começa com ele andando pela lava de `args[0]` até `args[1]` (o host
## escolhe). Devolve true enquanto ainda anda.
func wade(t: float) -> bool:
	var u := clampf(t / WADE, 0.0, 1.0)
	king.global_position.x = lerpf(float(args[0]), float(args[1]), smoothstep(0.0, 1.0, u))
	if u < 1.0:
		king.pose(&"lake", int(t * 6.0) % 4)
		return true
	return false


## Remove um objeto (null-seguro).
static func free_prop(prop: Node) -> void:
	if prop != null and is_instance_valid(prop):
		prop.queue_free()


# --- Para cada ataque ---

func _start() -> void:
	pass


func _tick(_t: float) -> void:
	pass


func _stop() -> void:
	pass
