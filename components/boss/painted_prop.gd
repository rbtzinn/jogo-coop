class_name PaintedProp
extends BossProp
## Efeito de uma luta com catálogo próprio; não depende da arte de outro chefão.
var definitions := {}
var folder := ""


func _kinds() -> Dictionary:
	return definitions


func _art() -> String:
	return folder


## O chefão pede destaque pondo "_look" no catálogo (ex.: 1.3).
func _look() -> float:
	return float(definitions.get(&"_look", 1.0))
