class_name Levels
## Caminhos das cenas principais (menu e mapas das áreas), usados por várias telas.

const MENU := "res://core/ui/main_menu.tscn"
## Mapa da Área 1: o parque pintado da aventura (levels/world/).
const MAP := "res://levels/world/world_area1.tscn"
## Mapa de cada área (o número fica no save).
const MAPS := {
	1: MAP,
	2: "res://levels/world/world_area2.tscn",
}
## A viagem de avião entre as áreas.
const TRAVEL := "res://levels/travel/plane_travel.tscn"

## Tenda por onde os dois entraram por último no mundo 3D (id do save); ao voltar, nascem na frente dela.
static var return_door := ""


## Mapa da área atual do save (para onde "Voltar ao mapa" e o menu levam).
static func current_map() -> String:
	return MAPS.get(int(SaveGame.data.get("area", 1)), MAP)


## Se a cena é o mapa de alguma área.
static func is_map(path: String) -> bool:
	return path in MAPS.values()
