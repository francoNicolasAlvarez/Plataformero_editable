extends Control
## Pantalla final del juego (2026-11-12): resume tiempo total y muertes de la
## expedición y permite empezar otra partida o volver al menú.

const LEVEL_ONE := "res://scenes/levels/level_one.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var stats_label: Label = $Center/Panel/Margin/VBox/Stats
@onready var replay_button: Button = $Center/Panel/Margin/VBox/Buttons/ReplayButton
@onready var menu_button: Button = $Center/Panel/Margin/VBox/Buttons/MenuButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/Buttons/QuitButton


func _ready() -> void:
	SaveGame.ensure_loaded()
	Sfx.stop_music(0.4)
	stats_label.text = "Tiempo total: %s   ·   Muertes: %d" % [
		SaveGame.format_time(SaveGame.total_time),
		SaveGame.deaths,
	]
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	replay_button.grab_focus()


func _on_replay_pressed() -> void:
	Sfx.play("ui", -10.0)
	SaveGame.begin_new_run()
	SceneFade.change_scene(get_tree(), LEVEL_ONE)


func _on_menu_pressed() -> void:
	Sfx.play("ui", -10.0)
	SaveGame.begin_new_run()
	SceneFade.change_scene(get_tree(), MENU_SCENE)


func _on_quit_pressed() -> void:
	Sfx.play("ui", -10.0)
	get_tree().quit()
