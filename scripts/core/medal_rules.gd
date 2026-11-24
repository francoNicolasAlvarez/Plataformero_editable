class_name MedalRules
extends RefCounted
## Reglas de medallas de la fase contrarreloj (2026-11-17): convierten el
## tiempo real invertido en Oro, Plata o Bronce. Se guarda el tiempo exacto y
## la mejor medalla por nivel para que el selector pueda mostrarlos.

const NONE := ""
const BRONZE := "BRONCE"
const SILVER := "PLATA"
const GOLD := "ORO"

const ORDER := [NONE, BRONZE, SILVER, GOLD]


static func for_time(elapsed: float, gold_time: float, silver_time: float, bronze_time: float) -> String:
	## Devuelve la medalla conseguida. Los objetivos se ordenan para que un
	## archivo de configuración con valores invertidos no produzca medallas
	## incoherentes.
	var gold := maxf(0.0, gold_time)
	var silver := maxf(gold, silver_time)
	var bronze := maxf(silver, bronze_time)
	if bronze <= 0.0:
		return NONE
	var seconds := maxf(0.0, elapsed)
	if seconds <= gold:
		return GOLD
	if seconds <= silver:
		return SILVER
	if seconds <= bronze:
		return BRONZE
	return NONE


static func rank(medal: String) -> int:
	var index := ORDER.find(medal)
	return maxi(0, index)


static func is_better(candidate: String, current: String) -> bool:
	return rank(candidate) > rank(current)


static func display(medal: String) -> String:
	return medal if not medal.is_empty() else "SIN MEDALLA"


## Umbrales por nivel (2026-11-18): el oro exige ir un 35 % más lento que una
## carrera recta a velocidad de correr, la plata un 70 % y el bronce es el
## límite del nivel. Así los niveles largos no tienen el mismo listón que los
## cortos. Devuelve {"gold", "silver", "bronze"}.
static func thresholds_for_route(distance: float, run_speed: float, time_limit: float) -> Dictionary:
	var par := maxf(1.0, distance) / maxf(1.0, run_speed)
	var gold := par * 1.35
	var silver := minf(par * 1.7, time_limit - 3.0)
	gold = minf(gold, silver - 3.0)
	return {"gold": snappedf(gold, 0.5), "silver": snappedf(silver, 0.5), "bronze": time_limit}
