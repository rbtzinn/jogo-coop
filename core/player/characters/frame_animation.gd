class_name FrameAnimation
extends Resource
## Animação quadro a quadro de um personagem (ex.: a corrida desenhada por IA).
## O braço da arma continua sendo desenhado por código por cima: cada quadro diz onde
## fica o ombro. Gerado por tools/cut_animation_sheet.gd.

@export var frames: Array[Texture2D] = []
## Escala dos quadros dentro do rig.
@export var frame_scale := 0.5
## Posição (no espaço do rig, pés em y = 0) do canto de cima à esquerda de cada quadro.
@export var origin := Vector2.ZERO
## Ombro da frente em cada quadro, no espaço do rig.
@export var shoulders: PackedVector2Array = []
## Ponto (no espaço do rig) em volta do qual o desenho pode girar (ex.: o meio do tronco no dash).
@export var pivot := Vector2.ZERO
## Deslocamento de cada quadro no espaço do rig (opcional): quando um desenho teve de ser posto
## fora do lugar na célula para caber (ex.: o pé do chute perto da borda), isto o devolve ao lugar.
@export var offsets: PackedVector2Array = []


func frame_count() -> int:
	return frames.size()


## Quadro em um ponto do ciclo (`fraction` de 0 a 1). Com `weights` (duração relativa de cada
## quadro), cada pose fica o tempo que precisa (ex.: na corrida, o pé de apoio recua por igual);
## sem eles, todos os quadros duram o mesmo.
func index_at(fraction: float, weights: PackedFloat32Array = PackedFloat32Array()) -> int:
	var count := frame_count()
	fraction = fposmod(fraction, 1.0)
	if weights.size() != count:
		return mini(int(fraction * count), count - 1)
	var total := 0.0
	for w in weights:
		total += w
	var at := fraction * total
	for i in count:
		at -= weights[i]
		if at < 0.0:
			return i
	return count - 1


## Canto de cima à esquerda do quadro `index` no espaço do rig (a origem mais o deslocamento dele).
func origin_of(index: int) -> Vector2:
	return origin + (offsets[index] if index < offsets.size() else Vector2.ZERO)
