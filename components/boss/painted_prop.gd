class_name PaintedProp
extends BossProp
## Efeito de uma luta com catálogo próprio; não depende da arte de outro chefão.
var definitions := {}
var folder := ""


func _kinds() -> Dictionary:
	return definitions


func _art() -> String:
	return folder
