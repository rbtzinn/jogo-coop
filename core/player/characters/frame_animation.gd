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


func frame_count() -> int:
	return frames.size()
