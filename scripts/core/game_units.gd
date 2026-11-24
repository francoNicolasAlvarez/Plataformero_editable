class_name GameUnits
extends RefCounted
## Unidades de medida del juego (2026-11-18). Todo el juego se mide en PÍXELES
## del mundo (1 px = 1 unidad de Godot). Como referencia humana se usa la
## unidad "J" (un Jugador): la altura del cuerpo de colisión del personaje,
## 48 px (su ancho es 30 px). Sirve para comparar cualquier distancia con algo
## que se ve en pantalla, p. ej. un muro bajo del laberinto mide 2 J.
##
## Tabla de referencia (px -> J):
##   jugador (alto)             48   ->  1
##   muro bajo del laberinto    96   ->  2
##   salto normal (altura)     125   -> 2,6
##   salto del doble salto     ~250  -> 5,2
##   impulso (distancia)       154   -> 3,2
##   foso de los niveles       300   -> 6,3
##   pasillo del laberinto     288   -> 6
##   onda del saltador         260   -> 5,4  (radio)
##   pantalla                 1152x648 -> 24 x 13,5
##   velocidad de correr       532 px/s -> 11 J/s

const PLAYER_HEIGHT_PX := 48.0
const PLAYER_WIDTH_PX := 30.0
## Longitud de un "metro" aproximado si se asume un jugador de 1,7 m.
const PIXELS_PER_METER := PLAYER_HEIGHT_PX / 1.7


## Convierte píxeles a unidades J (jugadores de altura).
static func to_players(pixels: float) -> float:
	return pixels / PLAYER_HEIGHT_PX


## Convierte unidades J a píxeles.
static func from_players(players: float) -> float:
	return players * PLAYER_HEIGHT_PX


## Convierte píxeles a metros aproximados (jugador = 1,7 m).
static func to_meters(pixels: float) -> float:
	return pixels / PIXELS_PER_METER


## Texto legible: "154 px = 3,2 J".
static func describe(pixels: float) -> String:
	return "%d px = %.1f J" % [roundi(pixels), to_players(pixels)]
