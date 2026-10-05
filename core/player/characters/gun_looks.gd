class_name GunLooks
## Desenho de cada pistola na mão do personagem: a luva com a pistola, onde fica a boca (de onde
## sai o tiro) e o clarão do disparo. Recortados por tools/cut_weapon_art.gd.
## Posições no espaço da mão da arma (pixels da textura; o Sprite2D da mão usa escala 0,5),
## com o punho no (0, 0) e a pistola apontando para a direita.

const DIR := "res://core/player/characters/shared/guns/"
## Centro das texturas das luvas em relação ao punho (o mesmo nas quatro).
const HAND_OFFSET := Vector2(92.5, -12.5)

const GLOVES := {
	"cork_gun": preload(DIR + "glove_cork_gun.png"),
	"confetti_fan": preload(DIR + "glove_confetti_fan.png"),
	"juggling_club": preload(DIR + "glove_juggling_club.png"),
	"soap_bubble": preload(DIR + "glove_soap_bubble.png"),
}
## Boca de cada pistola, medida no desenho.
const MUZZLES := {
	"cork_gun": Vector2(176, 2),
	"confetti_fan": Vector2(162, -14),
	"juggling_club": Vector2(184, 6),
	"soap_bubble": Vector2(174, 0),
}
const FLASHES := {
	"cork_gun": preload(DIR + "flash_cork_gun.tres"),
	"confetti_fan": preload(DIR + "flash_confetti_fan.tres"),
	"juggling_club": preload(DIR + "flash_juggling_club.tres"),
	"soap_bubble": preload(DIR + "flash_soap_bubble.tres"),
}


static func glove(weapon: String) -> Texture2D:
	return GLOVES.get(weapon, GLOVES["cork_gun"])


static func muzzle(weapon: String) -> Vector2:
	return MUZZLES.get(weapon, MUZZLES["cork_gun"])


static func flash(weapon: String) -> FrameAnimation:
	return FLASHES.get(weapon, FLASHES["cork_gun"])
