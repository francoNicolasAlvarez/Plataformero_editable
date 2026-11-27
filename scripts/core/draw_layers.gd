class_name DrawLayers
extends RefCounted
## Orden de dibujo común (2026-11-27). Capas (`z_index`) del mundo:
##   <= -6  decoración y fondos (parallax, árboles, colinas)
##   -2     sierras
##   -1     BEHIND_GROUND: trampas y objetos apoyados en el suelo (pinchos,
##          minas, lanzadores, teletransportes, palancas, botones, respiraderos,
##          pilas de rocas, controles, hierbas, llaves y portal)
##    0     suelo, plataformas, jugador y enemigos
## Así la base de una trampa u objeto queda tapada por el suelo o la
## plataforma en la que se apoya: no asoma su borde inferior ni parece flotar.

const BEHIND_GROUND := -1
## Sombra a ras de suelo: por encima del suelo (capa neta +1), para que no
## quede cortada por la mitad al estar el objeto detrás.
const GROUND_SHADOW := 2


static func behind_ground(node: CanvasItem) -> void:
	## Solo cambia la capa si nadie la tocó (respeta lo editado en el editor).
	if node.z_index == 0:
		node.z_index = BEHIND_GROUND
	var shadow := node.get_node_or_null("Shadow") as CanvasItem
	if shadow != null and shadow.z_index == 0:
		shadow.z_index = GROUND_SHADOW
