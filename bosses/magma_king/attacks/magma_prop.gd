class_name MagmaProp
extends BossProp
## Objeto de ataque do Rei Magma: bola de lava, poça, gema, coroa, pingo, coluna ou onda (BossProp). O jato da
## Rajada é o JetBeam.

const KINDS := {
	&"ball": {"frames": ["fx_ball_1", "fx_ball_2", "fx_ball_3", "fx_ball_4"], "scale": 0.55, "fps": 12.0,
			"circle": 34.0, "anchor": "center"},
	&"puddle": {"frames": ["fx_puddle_1", "fx_puddle_2", "fx_puddle_3", "fx_puddle_4"], "scale": 0.75, "fps": 0.0,
			"rect": Vector2(150, 26), "at": Vector2(0, -13), "anchor": "bottom"},
	&"gem": {"frames": ["fx_gem_1", "fx_gem_2"], "scale": 0.55, "fps": 6.0, "circle": 32.0, "anchor": "center"},
	&"crown": {"frames": ["fx_crown_1", "fx_crown_2", "fx_crown_3", "fx_crown_4"], "scale": 0.7, "fps": 14.0,
			"circle": 62.0, "anchor": "center"},
	&"drop": {"frames": ["fx_drop_1", "fx_drop_2"], "scale": 0.55, "fps": 10.0, "circle": 24.0, "anchor": "center"},
	&"drop_parry": {"frames": ["fx_drop_parry"], "scale": 0.55, "fps": 0.0, "circle": 26.0, "anchor": "center"},
	&"splash": {"frames": ["fx_splash_1", "fx_splash_2", "fx_splash_3"], "scale": 0.55, "fps": 0.0,
			"rect": Vector2(110, 40), "at": Vector2(0, -20), "anchor": "bottom"},
	&"column": {"frames": ["column_1", "column_2", "column_3", "column_4"], "scale": 0.36, "fps": 0.0,
			"rect": Vector2(96, 225), "at": Vector2(0, -112), "anchor": "bottom"},
	&"wave": {"frames": ["wave_1", "wave_2", "wave_3", "wave_4"], "scale": 0.4, "fps": 0.0,
			"rect": Vector2(170, 150), "at": Vector2(-10, -75), "anchor": "bottom"},
	&"orbit_crown": {"frames": ["fx_crown_1", "fx_crown_2", "fx_crown_3", "fx_crown_4"], "scale": 0.55,
			"fps": 16.0, "circle": 50.0, "anchor": "center"},
}


func _kinds() -> Dictionary:
	return KINDS


func _art() -> String:
	return "res://bosses/magma_king/art/"

