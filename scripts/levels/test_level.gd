extends Node2D
## Nivel jugable. Une la vida del jugador con el HUD y controla el portal.
## Permite construir ocho variantes: día, atardecer, noche, abismo, cielo,
## fortaleza, inversa y espejo.
## Desde 2026-11-12 el juego es un plataformas lineal: hay checkpoints,
## tres vidas por nivel, fundido entre escenas y una pantalla de final.
## Sin vidas o sin tiempo la expedición vuelve a empezar en el nivel 1.
## Fase contrarreloj (2026-11-17): el reloj sigue corriendo al morir, no hay
## bonus de tiempo y el resultado se guarda con medalla y mejor tiempo.

@export var level_variant: int = 1
@export_file("*.tscn") var next_level_path: String = ""
@export var level_name: String = "NIVEL 1"
@export var time_limit: float = 70.0
## Nivel "horneado" (editable a mano en Godot): el mundo ya está colocado en la
## propia escena, así que no se ejecuta el generador de `level_variant`.
@export var baked: bool = false
## Camino de la salida (solo niveles con ruta, como el laberinto): puntos que
## alimentan la barra de progreso y las medallas.
@export var route_points: PackedVector2Array = PackedVector2Array()
@export var gold_medal_time: float = 35.0
@export var silver_medal_time: float = 50.0
@export var bronze_medal_time: float = 70.0

const MAX_LIVES := 3
const FIRST_LEVEL_PATH := "res://scenes/levels/level_one.tscn"
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const RESULTS_PATH := "res://scenes/ui/level_results.tscn"
const HEART_FULL := "\u2665"
const HEART_EMPTY := "\u2661"

@onready var player: Player = $Player
@onready var portal: ExitPortal = $ExitPortal
@onready var camera: HorizontalCamera = $Camera
@onready var portal_hint: Label = $HUD/PortalHint
@onready var timer_label: Label = $HUD/TimerLabel
@onready var medal_label: Label = $HUD/MedalLabel
@onready var progress_bar: ProgressBar = $HUD/LevelProgress
@onready var progress_label: Label = $HUD/LevelProgress/ProgressLabel
@onready var game_over_label: Label = $HUD/GameOver
@onready var completed_label: Label = $HUD/Completed
@onready var health_icons: Label = $HUD/HealthIcons
@onready var lives_label: Label = $HUD/LivesLabel
@onready var damage_flash: ColorRect = $HUD/DamageFlash

var _completed: bool = false
var _time_left: float = 0.0
var _timer := RunTimer.new()
var _progress_start_x: float = 0.0
## Ruta del recorrido (2026-11-18) para niveles que no avanzan en línea recta
## (laberinto): el progreso y las medallas usan su longitud, no la distancia en x.
var _route: PackedVector2Array = PackedVector2Array()
var _route_length: float = 0.0
var _timer_expired: bool = false
var _lives: int = MAX_LIVES
var _level_deaths: int = 0
var _respawn_point: Vector2 = Vector2.ZERO
## Tiempo que sobraba al activar el último control (2026-11-24); al reaparecer la
## cuenta regresiva vuelve a ese valor. Sin control activado, el límite completo.
var _respawn_time_left: float = 0.0
var _fade_rect: ColorRect
var _damage_tween: Tween


func _ready() -> void:
	SaveGame.ensure_loaded()
	GameSettings.ensure_loaded()
	GameSettings.apply_brightness($Brightness)
	GameSettings.apply_audio()

	if baked:
		_prepare_baked_level()
	elif level_variant == 2:
		_prepare_level_two()
	elif level_variant == 3:
		_prepare_level_three()
	elif level_variant == 4:
		_prepare_level_four()
	elif level_variant == 5:
		_prepare_level_five()
	elif level_variant == 6:
		_prepare_level_six()
	elif level_variant == 7:
		_prepare_level_seven()
	elif level_variant == 8:
		_prepare_level_eight()
	elif level_variant == 9:
		_prepare_level_nine()
	elif level_variant == 10:
		_prepare_level_ten()
	elif level_variant == 11:
		_prepare_level_eleven()
	elif level_variant == 12:
		_prepare_level_twelve()
	elif level_variant == 13:
		_prepare_level_thirteen()
	elif level_variant == 14:
		_prepare_level_fourteen()
	elif level_variant == 15:
		_prepare_level_fifteen()
	elif level_variant == 16:
		_prepare_level_sixteen()
	elif level_variant == 17:
		_prepare_level_seventeen()
	elif level_variant == 18:
		_prepare_level_eighteen()
	elif level_variant == 19:
		_prepare_level_nineteen()
	elif level_variant == 20:
		_prepare_level_twenty()
	elif level_variant == 21:
		_prepare_level_twentyone()
	elif level_variant == 22:
		_prepare_level_twentytwo()
	elif level_variant == 23:
		_prepare_level_twentythree()
	elif level_variant == 24:
		_prepare_level_twentyfour()
	elif level_variant == 25:
		_prepare_level_twentyfive()
	elif level_variant == 26:
		_prepare_level_twentysix()
	elif level_variant == 27:
		_prepare_level_twentyseven()
	elif level_variant == 28:
		_prepare_level_twentyeight()
	elif level_variant == 29:
		_prepare_level_twentynine()
	elif level_variant == 30:
		_prepare_level_thirty()

	_apply_run_variation()
	_decorate_base_hills()
	_add_boundary_walls()
	_timer.start(time_limit)
	_respawn_time_left = _timer.remaining
	_time_left = _timer.remaining
	_level_deaths = 0
	_progress_start_x = player.global_position.x
	_respawn_point = player.global_position
	# Punto de inicio del nivel: lo lee TeleportTrap.
	set_meta("start_point", player.global_position)
	player.health.died.connect(_on_player_died)
	player.health.health_changed.connect(_on_health_changed)
	player.health.damaged.connect(_on_player_damaged)
	_on_health_changed(player.health.current_health, player.health.max_health)
	_update_lives_label()
	_connect_checkpoints()
	game_over_label.visible = false
	completed_label.visible = false
	portal_hint.visible = false
	portal.reached.connect(_on_portal_reached)

	# El nivel se nombra siempre por su código "zona-nivel" (2026-11-20).
	var level_config := LevelRegistry.get_level(level_variant)
	if level_config != null:
		level_name = "NIVEL %s" % level_config.code()
	HudLayout.apply($HUD, "%s · %s" % [level_name, MOODS.get(level_variant, "")])
	_calibrate_medals()
	_update_timer_label()
	_update_medal_label()
	_update_progress_bar()
	_show_level_banner()
	ScreenFx.add_vignette(self)
	_build_fade()
	SaveGame.set_level(level_variant)
	Sfx.start_music(level_variant)


func _add_boundary_walls() -> void:
	## Muros invisibles en los límites laterales de la cámara (2026-11-18): el
	## jugador ya no puede salirse de la pantalla por el borde del nivel (antes
	## podía ir a la izquierda del inicio y morir fuera de cámara).
	if camera == null or get_node_or_null("BoundaryWalls") != null:
		return
	var walls := Node2D.new()
	walls.name = "BoundaryWalls"
	add_child(walls)
	for side in [-1, 1]:
		var limit := camera.limit_left if side < 0 else camera.limit_right
		if absi(limit) > 1000000:
			continue
		var wall := StaticBody2D.new()
		wall.name = "LeftWall" if side < 0 else "RightWall"
		wall.collision_layer = 1
		wall.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40.0, 6000.0)
		shape.shape = rect
		wall.add_child(shape)
		wall.position = Vector2(float(limit) + 20.0 * float(side), 360.0)
		walls.add_child(wall)


func _connect_checkpoints() -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		if checkpoint is Checkpoint and not checkpoint.activated.is_connected(_on_checkpoint_activated):
			checkpoint.activated.connect(_on_checkpoint_activated)


const MOODS := {1: "DÍA", 2: "ATARDECER", 3: "NOCHE", 4: "ABISMO", 5: "CIELO", 6: "FORTALEZA", 7: "INVERSO", 8: "ESPEJO", 9: "RUINAS", 10: "TEMPLO", 11: "VIENTO", 12: "DUNAS", 13: "OASIS", 14: "CAÑÓN", 15: "TORMENTA", 16: "GRUTA", 17: "MINA", 18: "CRISTALES", 19: "GALERÍA", 20: "DERRUMBE", 21: "LABERINTO", 22: "CAMPANARIO", 23: "PUENTES", 24: "NUBES", 25: "CIUDADELA", 26: "FOSO", 27: "MURALLAS", 28: "MAZMORRA", 29: "CATAPULTAS", 30: "SALA DEL TRONO"}


## Cartel del nivel al comenzar: aparece centrado y se desvanece solo.
func _show_level_banner() -> void:
	var hud := get_node_or_null("HUD")
	if hud == null:
		return
	var banner := Label.new()
	banner.name = "LevelBanner"
	banner.text = "%s · %s" % [level_name, MOODS.get(level_variant, "")]
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 108.0
	banner.offset_bottom = 150.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_font_size_override("font_size", 30)
	banner.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82, 1.0))
	banner.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	banner.add_theme_constant_override("outline_size", 6)
	hud.add_child(banner)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(banner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(banner.queue_free)


func _process(delta: float) -> void:
	if _completed:
		return

	# El reloj avanza también mientras el jugador está muerto: la muerte no
	# puede conceder tiempo extra ni congelar la medalla (2026-11-17).
	_timer.tick(delta)
	_time_left = _timer.remaining
	_update_timer_label()
	_update_progress_bar()
	_update_medal_label()

	if _timer.expired:
		if not _timer_expired:
			_timer_expired = true
			player.health.take_damage(9999)
		return

	if player.health.is_dead:
		return
	if _is_outside_view():
		player.health.take_damage(9999)


func _is_outside_view() -> bool:
	## Muerte por salir del mapa visible (2026-11-24): p. ej. una corriente que
	## lanza al jugador por encima del borde superior de la cámara.
	if camera == null or DisplayServer.get_name() == "headless":
		return false
	var size := get_viewport_rect().size / camera.zoom
	var center := camera.get_screen_center_position()
	var margin := 40.0
	return absf(player.global_position.y - center.y) > size.y * 0.5 + margin


func _prepare_baked_level() -> void:
	## El mundo viene colocado en la escena: solo hay que reponer lo que el
	## generador hacía en tiempo de ejecución y no se puede guardar en el .tscn.
	if not route_points.is_empty():
		set_route(route_points)
	if level_variant == 7:
		LevelSevenLayout._style_enemies(self)


func _prepare_level_two() -> void:
	# La variante 2 limpia el contenido base del nivel 1 y construye el
	# atardecer con sus propios enemigos (incluidos los ráfaga comunes).
	_clear_base_content()
	LevelTwoLayout.build(self)


func _prepare_level_three() -> void:
	# La variante 3 limpia el contenido base del nivel 1 y construye la
	# granja nocturna con sus propios enemigos (incluidos los ráfaga comunes).
	_clear_base_content()
	LevelThreeLayout.build(self)


func _prepare_level_four() -> void:
	# La variante 4 limpia el contenido base y construye el gran pozo.
	_clear_base_content()
	LevelFourLayout.build(self)


func _prepare_level_five() -> void:
	# La variante 5 construye el cielo de plataformas y los voladores.
	_clear_base_content()
	LevelFiveLayout.build(self)


func _prepare_level_six() -> void:
	# La variante 6 construye la fortaleza de trampas y saltos largos.
	_clear_base_content()
	LevelSixLayout.build(self)


func _prepare_level_seven() -> void:
	_clear_base_content()
	LevelSevenLayout.build(self)


func _prepare_level_eight() -> void:
	_clear_base_content()
	LevelEightLayout.build(self)


func _prepare_level_nine() -> void:
	_clear_base_content()
	LevelNineLayout.build(self)


func _prepare_level_ten() -> void:
	_clear_base_content()
	LevelTenLayout.build(self)


func _prepare_level_eleven() -> void:
	_clear_base_content()
	LevelElevenLayout.build(self)


func _prepare_level_twelve() -> void:
	_clear_base_content()
	LevelTwelveLayout.build(self)


func _prepare_level_thirteen() -> void:
	_clear_base_content()
	LevelThirteenLayout.build(self)


func _prepare_level_fourteen() -> void:
	_clear_base_content()
	LevelFourteenLayout.build(self)


func _prepare_level_fifteen() -> void:
	_clear_base_content()
	LevelFifteenLayout.build(self)


func _prepare_level_sixteen() -> void:
	_clear_base_content()
	LevelSixteenLayout.build(self)


func _prepare_level_seventeen() -> void:
	_clear_base_content()
	LevelSeventeenLayout.build(self)


func _prepare_level_eighteen() -> void:
	_clear_base_content()
	LevelEighteenLayout.build(self)


func _prepare_level_nineteen() -> void:
	_clear_base_content()
	LevelNineteenLayout.build(self)


func _prepare_level_twenty() -> void:
	_clear_base_content()
	LevelTwentyLayout.build(self)


func _prepare_level_twentyone() -> void:
	_clear_base_content()
	LevelTwentyoneLayout.build(self)


func _prepare_level_twentytwo() -> void:
	_clear_base_content()
	LevelTwentytwoLayout.build(self)


func _prepare_level_twentythree() -> void:
	_clear_base_content()
	LevelTwentythreeLayout.build(self)


func _prepare_level_twentyfour() -> void:
	_clear_base_content()
	LevelTwentyfourLayout.build(self)


func _prepare_level_twentyfive() -> void:
	_clear_base_content()
	LevelTwentyfiveLayout.build(self)


func _prepare_level_twentysix() -> void:
	_clear_base_content()
	LevelTwentysixLayout.build(self)


func _prepare_level_twentyseven() -> void:
	_clear_base_content()
	LevelTwentysevenLayout.build(self)


func _prepare_level_twentyeight() -> void:
	_clear_base_content()
	LevelTwentyeightLayout.build(self)


func _prepare_level_twentynine() -> void:
	_clear_base_content()
	LevelTwentynineLayout.build(self)


func _prepare_level_thirty() -> void:
	_clear_base_content()
	LevelThirtyLayout.build(self)


func _clear_base_content() -> void:
	for child in $Platforms.get_children():
		child.free()

	var base_nodes := [
		"TrainingDummy", "WalkerEnemy", "RangedEnemy", "SpreadEnemy",
		"HealingHerbLeft", "HealingHerbRight",
	]
	for node_name in base_nodes:
		var node := get_node_or_null(node_name)
		if node != null:
			node.free()

	$Background.visible = false
	$BackgroundDecor.visible = false


func _apply_run_variation() -> void:
	# Las pruebas headless necesitan posiciones estables.
	if DisplayServer.get_name() == "headless":
		return

	# Variación procedural: el fondo cambia ligeramente en cada partida.
	for hill in $BackgroundDecor.get_children():
		hill.position.x += randf_range(-70.0, 70.0)
		hill.position.y += randf_range(-18.0, 12.0)


func _decorate_base_hills() -> void:
	# Detalle de colinas (2026-11-11): solo la variante 1 (día) muestra las
	# colinas base de BackgroundDecor; las variantes 2/3 crean las suyas.
	if not $BackgroundDecor.visible:
		return
	for hill in $BackgroundDecor.get_children():
		MountainBuilder.decorate(
			hill,
			Color("#cfe3dc"),
			hill.color.lightened(0.10),
			hill.color.darkened(0.22),
			true
		)


func _update_timer_label() -> void:
	var seconds := ceili(_time_left)
	timer_label.text = "TIEMPO: %d" % seconds
	var color := Color(1.0, 0.32, 0.28, 1.0) if _time_left <= 10.0 else Color.WHITE
	timer_label.add_theme_color_override("font_color", color)


## Registra la ruta (puntos del camino de la salida) del nivel.
func set_route(points: PackedVector2Array) -> void:
	_route = points
	_route_length = 0.0
	for i in range(1, points.size()):
		_route_length += points[i - 1].distance_to(points[i])


func route_progress(position: Vector2) -> float:
	## Fracción 0..1 recorrida de la ruta: proyecta la posición sobre el
	## segmento más cercano y suma la longitud previa.
	if _route.size() < 2 or _route_length <= 0.0:
		return 0.0
	var best_distance := INF
	var best_along := 0.0
	var accumulated := 0.0
	for i in range(1, _route.size()):
		var a := _route[i - 1]
		var b := _route[i]
		var closest := Geometry2D.get_closest_point_to_segment(position, a, b)
		var d := position.distance_to(closest)
		if d < best_distance:
			best_distance = d
			best_along = accumulated + a.distance_to(closest)
		accumulated += a.distance_to(b)
	return clampf(best_along / _route_length, 0.0, 1.0)


func _calibrate_medals() -> void:
	## Umbrales de medalla según la longitud real del recorrido (2026-11-18).
	var distance := absf(portal.global_position.x - _progress_start_x)
	if _route_length > 0.0:
		distance = _route_length
	var limits := MedalRules.thresholds_for_route(distance, player.stats.run_speed, time_limit)
	gold_medal_time = limits["gold"]
	silver_medal_time = limits["silver"]
	bronze_medal_time = limits["bronze"]


func _update_medal_label() -> void:
	var medal := _current_medal()
	medal_label.text = "MEDALLA ACTUAL: %s  ·  %s" % [
		MedalRules.display(medal),
		SaveGame.format_time_precise(_timer.elapsed),
	]


func _current_medal() -> String:
	return MedalRules.for_time(
		_timer.elapsed,
		gold_medal_time,
		silver_medal_time,
		bronze_medal_time
	)


func _update_progress_bar() -> void:
	if _route_length > 0.0:
		progress_bar.value = route_progress(player.global_position) * 100.0
	else:
		var total_distance := maxf(1.0, portal.global_position.x - _progress_start_x)
		var travelled := player.global_position.x - _progress_start_x
		progress_bar.value = clampf(travelled / total_distance * 100.0, 0.0, 100.0)
	progress_label.text = "PROGRESO DE NIVEL  %d%%" % roundi(progress_bar.value)


func _on_health_changed(current: int, maximum: int) -> void:
	var hearts := ""
	for index in maximum:
		hearts += HEART_FULL if index < current else HEART_EMPTY
	health_icons.text = hearts


func _update_lives_label() -> void:
	lives_label.text = "VIDAS: %d" % _lives


func _on_player_damaged(_amount: int, _source: Node) -> void:
	_flash_damage()
	camera.shake(7.0, 0.25)
	ScreenFx.hit_stop(get_tree())


func _flash_damage() -> void:
	if _damage_tween != null and _damage_tween.is_valid():
		_damage_tween.kill()
	damage_flash.modulate.a = 1.0
	_damage_tween = create_tween()
	_damage_tween.tween_property(damage_flash, "modulate:a", 0.0, 0.35)


func _on_player_died() -> void:
	if _completed:
		return

	_reset_hazards()
	_level_deaths += 1
	SaveGame.register_death()
	_lives = maxi(0, _lives - 1)
	_update_lives_label()
	game_over_label.visible = true

	if _timer_expired:
		game_over_label.text = "TIEMPO AGOTADO - Volviendo al nivel 1..."
		await get_tree().create_timer(2.0).timeout
		await _restart_from_first_level()
		return

	if _lives > 0:
		game_over_label.text = "HAS MUERTO - Reapareciendo..."
		await get_tree().create_timer(1.2).timeout
		_respawn_player()
	else:
		game_over_label.text = "SIN VIDAS"
		await get_tree().create_timer(0.6).timeout
		_show_game_over_choice()


func _reset_hazards() -> void:
	## Al morir (2026-11-18): desaparecen todos los proyectiles, ondas y rocas;
	## los enemigos fijos vuelven a su posición inicial y los que aparecen por
	## sí solos (murciélagos) simplemente desaparecen.
	FlyingSpawner.clear_flying_enemies(get_tree())
	FallingRock.clear_rocks(get_tree())
	for group in ["enemy_projectiles", "thrown_boulders", "shock_waves", "rock_warnings"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is FlyingEnemy:
			continue
		if enemy is TrainingDummy:
			(enemy as TrainingDummy).reset_to_start()
	for sentry in get_tree().get_nodes_in_group("sky_sentries"):
		(sentry as SkySentry).reset()
	for vacuum in get_tree().get_nodes_in_group("vacuum_sentries"):
		(vacuum as VacuumSentry).reset()
	# Obstáculos con ciclo y zonas con efecto (Fase 4, 2026-11-18).
	for hazard in get_tree().get_nodes_in_group("hazards"):
		(hazard as Hazard).reset()
	for zone in get_tree().get_nodes_in_group("gimmick_zones"):
		(zone as GimmickZone).reset()
	# Mundo 6: objetos sujetables y puentes levadizos vuelven a su sitio.
	for item in get_tree().get_nodes_in_group("grab_items"):
		(item as GrabItem).reset_to_start()
	for bridge in get_tree().get_nodes_in_group("drawbridges"):
		(bridge as Drawbridge).reset()


func first_level_of_group() -> int:
	## Primer nivel del grupo (mundo) al que pertenece este nivel.
	var world := LevelRegistry.get_world_for_level(level_variant)
	if world == null or world.levels.is_empty():
		return level_variant
	return world.levels[0].number


func _show_game_over_choice() -> void:
	## Sin vidas (2026-11-18): la pantalla se desvanece a negro y aparece la
	## pantalla de muerte (`GameOverScreen`) con las opciones: reintentar el
	## nivel, empezar el grupo desde su primer nivel (si no lo abre este),
	## volver al nivel 1, ir al menú principal o cerrar el juego.
	if _completed or get_node_or_null("HUD/GameOverChoice") != null:
		return
	_timer.stop()
	game_over_label.visible = false
	var config := LevelRegistry.get_level(level_variant)
	var screen := GameOverScreen.new()
	screen.build(
		config.code() if config != null else str(level_variant),
		str(MOODS.get(level_variant, "")).capitalize(),
		config.world_number if config != null else 1,
		config.index_in_world if config != null else level_variant,
		SaveGame.format_time_precise(_timer.elapsed),
		_level_deaths
	)
	screen.retry_requested.connect(_restart_current_level)
	screen.group_restart_requested.connect(_restart_from_group_start)
	screen.first_level_requested.connect(_restart_from_first_level_choice)
	screen.main_menu_requested.connect(_go_to_main_menu)
	screen.quit_requested.connect(func() -> void: get_tree().quit())
	$HUD.add_child(screen)
	screen.play()


func _restart_from_first_level_choice() -> void:
	_start_over_at(SaveGame.FIRST_LEVEL)


func _go_to_main_menu() -> void:
	var box := get_node_or_null("HUD/GameOverChoice")
	if box != null:
		box.queue_free()
	await _fade_to_scene(MAIN_MENU_PATH)


func _restart_current_level() -> void:
	_start_over_at(level_variant)


func _restart_from_group_start() -> void:
	_start_over_at(first_level_of_group())


func _start_over_at(level_number: int) -> void:
	var box := get_node_or_null("HUD/GameOverChoice")
	if box != null:
		box.queue_free()
	SaveGame.start_at_level(level_number)
	var path := LevelRegistry.scene_path_for(level_number)
	await _fade_to_scene(path if not path.is_empty() else FIRST_LEVEL_PATH)


func _restart_from_first_level() -> void:
	## Game over (2026-11-13): sin vidas o sin tiempo la expedición vuelve a
	## empezar en el nivel 1, reiniciando tiempo y muertes.
	SaveGame.start_at_level(SaveGame.FIRST_LEVEL)
	await _fade_to_scene(FIRST_LEVEL_PATH)


func _respawn_player() -> void:
	if _completed or not player.health.is_dead:
		return
	game_over_label.visible = false
	player.revive(_respawn_point)
	camera.snap_to_target()
	# Se reaparece con el tiempo que sobraba al activar el control (o el límite
	# completo si no hay ninguno); el tiempo real (medalla) sigue contando.
	_timer.restore_countdown(_respawn_time_left)
	_time_left = _timer.remaining
	_update_timer_label()
	_update_progress_bar()
	_update_medal_label()


func _on_checkpoint_activated(checkpoint: Checkpoint) -> void:
	_respawn_point = checkpoint.global_position
	_respawn_time_left = _timer.remaining
	SaveGame.set_level(level_variant)
	_show_checkpoint_banner()


## Aviso de descanso (2026-11-13): confirma que el control curó al jugador y
## que ese punto será la nueva reaparición.
func _show_checkpoint_banner() -> void:
	var hud := get_node_or_null("HUD")
	if hud == null:
		return
	var banner := Label.new()
	banner.name = "CheckpointBanner"
	banner.text = "CONTROL ACTIVADO\nDESCANSO · VIDA RESTAURADA"
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 170.0
	banner.offset_bottom = 226.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_font_size_override("font_size", 20)
	banner.add_theme_color_override("font_color", Color(0.62, 1.0, 0.78, 1.0))
	banner.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	banner.add_theme_constant_override("outline_size", 5)
	hud.add_child(banner)
	var tween := create_tween()
	tween.tween_interval(1.3)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.queue_free)


func _on_portal_reached() -> void:
	if _completed:
		return
	_completed = true
	_timer.stop()
	_time_left = _timer.remaining
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	var elapsed := _timer.elapsed
	var medal := _current_medal()
	_account_time(elapsed)
	SaveGame.record_level_result(level_variant, elapsed, medal, _level_deaths)
	completed_label.text = "%s COMPLETADO · MEDALLA %s" % [
		level_name,
		MedalRules.display(medal),
	]
	completed_label.visible = true

	var next_level := LevelRegistry.next_implemented_level(level_variant)
	if next_level == -1:
		SaveGame.finish_game()
	elif SaveGame.is_level_unlocked(next_level):
		SaveGame.set_level(next_level)

	await get_tree().create_timer(2.0).timeout
	await _fade_to_scene(RESULTS_PATH)


func _account_time(elapsed: float) -> void:
	## El tiempo de la expedición es el tiempo real invertido en el nivel; la
	## medalla usa el mismo valor. Ya no se deriva de la cuenta regresiva.
	SaveGame.add_time(maxf(0.0, elapsed))


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 90
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, 0.45)


func _fade_to_scene(path: String) -> void:
	# Transición (2026-11-12): imagen y música se funden a la vez antes de
	# cambiar de escena; el destino vuelve a entrar con fundido desde negro.
	Sfx.stop_music(0.45)
	if _fade_rect != null:
		_fade_rect.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.4)
		await tween.finished
	if path.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(path)


func is_run_over() -> bool:
	## Consulta del overlay de pausa: evita pausar tras morir, completar el
	## nivel o agotar el tiempo (las transiciones no deben congelarse).
	return _completed or _timer_expired or player.health.is_dead
