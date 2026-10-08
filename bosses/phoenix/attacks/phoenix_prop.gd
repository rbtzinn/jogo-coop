class_name PhoenixProp
extends BossProp
## Objeto de ataque da Fênix das Cinzas: pena, ovinho, pintinho de brasa, fagulha, anel de fogo, e os que só
## avisam (rastro do rasante, vento), que não machucam (BossProp).

const KINDS := {
	&"feather": {"frames": ["fx_feather_1", "fx_feather_2", "fx_feather_3", "fx_feather_4"], "scale": 0.45,
			"fps": 8.0, "circle": 28.0, "anchor": "center"},
	&"feather_parry": {"frames": ["fx_feather_parry_1", "fx_feather_parry_2", "fx_feather_parry_3",
			"fx_feather_parry_4"], "scale": 0.45, "fps": 8.0, "circle": 30.0, "anchor": "center"},
	&"egg": {"frames": ["fx_egg_1", "fx_egg_2"], "scale": 0.42, "fps": 6.0, "circle": 28.0, "anchor": "center"},
	&"egg_parry": {"frames": ["fx_egg_parry_1", "fx_egg_parry_2"], "scale": 0.42, "fps": 6.0, "circle": 30.0,
			"anchor": "center"},
	&"egg_crack": {"frames": ["fx_egg_crack_1", "fx_egg_crack_2"], "scale": 0.42, "fps": 0.0,
			"rect": Vector2(56, 56), "at": Vector2(0, -28), "anchor": "bottom"},
	&"egg_splash": {"frames": ["fx_egg_splash_1", "fx_egg_splash_2"], "scale": 0.45, "fps": 0.0,
			"rect": Vector2(80, 36), "at": Vector2(0, -18), "anchor": "bottom"},
	&"chick": {"frames": ["fx_chick_1", "fx_chick_2", "fx_chick_3", "fx_chick_4"], "scale": 0.5, "fps": 12.0,
			"rect": Vector2(60, 56), "at": Vector2(0, -28), "anchor": "bottom"},
	&"spark": {"frames": ["fx_spark_1", "fx_spark_2"], "scale": 0.7, "fps": 10.0, "circle": 20.0, "anchor": "center"},
	&"ring": {"frames": ["ring_1", "ring_2", "ring_3", "ring_4"], "scale": 0.56, "fps": 10.0,
			"rect": Vector2(220, 64), "at": Vector2(0, -32), "anchor": "bottom"},
	# Só avisam: o ataque desliga `active`.
	&"trail": {"frames": ["fx_trail_1", "fx_trail_2", "fx_trail_3", "fx_trail_4"], "scale": 0.8, "fps": 0.0,
			"circle": 1.0, "anchor": "center"},
	&"wind": {"frames": ["wind_1", "wind_2", "wind_3", "wind_4"], "scale": 0.8, "fps": 8.0, "circle": 1.0,
			"anchor": "center"},
}


func _kinds() -> Dictionary:
	return KINDS


func _art() -> String:
	return "res://bosses/phoenix/art/"


## Ataques maiores e com contorno claro: no cenário de lava eles sumiam (pedido do usuário, 08/10/2026).
func _look() -> float:
	return 1.15
