extends Control
## Pantalla de resultados por nivel (2026-11-17): muestra tiempo real, medalla,
## muertes y mejor marca antes de continuar, repetir el nivel o volver al menú.

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const COMPLETE_SCENE := "res://scenes/ui/game_complete.tscn"

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/VBox/Subtitle
@onready var time_label: Label = $Center/Panel/Margin/VBox/Stats/TimeLabel
@onready var medal_label: Label = $Center/Panel/Margin/VBox/Stats/MedalLabel
@onready var deaths_label: Label = $Center/Panel/Margin/VBox/Stats/DeathsLabel
@onready var best_label: Label = $Center/Panel/Margin/VBox/BestLabel
@onready var continue_button: Button = $Center/Panel/Margin/VBox/Buttons/ContinueButton
@onready var repeat_button: Button = $Center/Panel/Margin/VBox/Buttons/RepeatButton
@onready var menu_button: Button = $Center/Panel/Margin/VBox/Buttons/MenuButton

var _level_number: int = SaveGame.FIRST_LEVEL


func _ready() -> void:
	SaveGame.ensure_loaded()
	Sfx.stop_music(0.4)
	_level_number = clampi(SaveGame.last_result_level, SaveGame.FIRST_LEVEL, SaveGame.LAST_LEVEL)
	var config: LevelConfig = LevelRegistry.get_level(_level_number)
	title_label.text = "NIVEL %s COMPLETADO" % config.code()
	subtitle_label.text = config.label()
	time_label.text = "TIEMPO: %s" % SaveGame.format_time_precise(SaveGame.last_result_time)
	medal_label.text = "MEDALLA: %s" % MedalRules.display(SaveGame.last_result_medal)
	medal_label.add_theme_color_override("font_color", _medal_color(SaveGame.last_result_medal))
	deaths_label.text = "MUERTES: %d" % SaveGame.last_result_deaths
	best_label.text = "MEJOR MARCA: %s" % SaveGame.format_time_precise(SaveGame.get_best_time(_level_number))
	var next_level := LevelRegistry.next_implemented_level(_level_number)
	if next_level == -1:
		continue_button.text = "VER RESULTADO FINAL"
	elif SaveGame.is_level_unlocked(next_level):
		continue_button.text = "SIGUIENTE NIVEL"
	else:
		# El mundo siguiente sigue bloqueado: hay que superar este en una pasada seguida.
		continue_button.text = "VOLVER AL MENÚ"
	subtitle_label.text += _pass_status_text(config)
	continue_button.pressed.connect(_on_continue_pressed)
	repeat_button.pressed.connect(_on_repeat_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	continue_button.grab_focus()


func _pass_status_text(config: LevelConfig) -> String:
	if SaveGame.last_world_cleared > 0:
		return "
¡ZONA %d SUPERADA! Se desbloquea la zona %d." % [SaveGame.last_world_cleared, SaveGame.last_world_cleared + 1]
	if SaveGame.world_run == config.world_number and SaveGame.world_run > 0:
		return "
PASADA DE LA ZONA %d: %d/%d niveles seguidos." % [SaveGame.world_run, SaveGame.world_run_progress, SaveGame.world_run_total()]
	if not SaveGame.is_world_cleared(config.world_number):
		return "
Práctica: para desbloquear la siguiente zona completa sus niveles seguidos desde el primero."
	return ""


func _medal_color(medal: String) -> Color:
	match medal:
		MedalRules.GOLD:
			return Color(1.0, 0.84, 0.25)
		MedalRules.SILVER:
			return Color(0.82, 0.87, 0.94)
		MedalRules.BRONZE:
			return Color(0.88, 0.58, 0.32)
	return Color(0.62, 0.68, 0.78)


func _on_continue_pressed() -> void:
	Sfx.play("ui", -10.0)
	var next_level := LevelRegistry.next_implemented_level(_level_number)
	if next_level == -1:
		SaveGame.finish_game()
		SceneFade.change_scene(get_tree(), COMPLETE_SCENE)
		return
	if not SaveGame.is_level_unlocked(next_level):
		SceneFade.change_scene(get_tree(), MENU_SCENE)
		return
	SaveGame.set_level(next_level)
	SceneFade.change_scene(get_tree(), LevelRegistry.scene_path_for(next_level))


func _on_repeat_pressed() -> void:
	Sfx.play("ui", -10.0)
	SaveGame.start_at_level(_level_number)
	SceneFade.change_scene(get_tree(), LevelRegistry.scene_path_for(_level_number))


func _on_menu_pressed() -> void:
	Sfx.play("ui", -10.0)
	SceneFade.change_scene(get_tree(), MENU_SCENE)
