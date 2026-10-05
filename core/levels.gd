class_name Levels
## Caminhos das cenas principais (menu e mapa), usados por várias telas.

const MENU := "res://core/ui/main_menu.tscn"
## Mapa da área: o mundo 3D da aventura (piloto de 03/10/2026). O mapa 2D antigo
## (levels/circus_map/) fica guardado, sem uso.
const MAP := "res://levels/world/world_area1.tscn"

## Tenda por onde os dois entraram por último no mundo 3D (id do save); ao voltar, nascem na frente dela.
static var return_door := ""
