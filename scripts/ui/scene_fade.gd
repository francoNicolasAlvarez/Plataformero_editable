class_name SceneFade
extends RefCounted
## Fundido a negro reutilizable para cambios de escena desde menús y pantallas
## (2026-11-12). El CanvasLayer vive en la raíz, así que sobrevive al cambio de
## escena; tras cambiar, se desvanece para revelar el destino.

const LAYER_NAME := "SceneFadeLayer"


static func change_scene(tree: SceneTree, path: String, duration: float = 0.35) -> void:
	if tree == null or path.is_empty():
		return
	if tree.root.has_node(LAYER_NAME):
		return

	var layer := CanvasLayer.new()
	layer.name = LAYER_NAME
	layer.layer = 100
	tree.root.add_child(layer)

	var rect := ColorRect.new()
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade_in := layer.create_tween()
	fade_in.tween_property(rect, "color:a", 1.0, duration)
	await fade_in.finished

	tree.change_scene_to_file(path)
	await tree.process_frame

	var fade_out := layer.create_tween()
	fade_out.tween_property(rect, "color:a", 0.0, duration)
	await fade_out.finished
	layer.queue_free()
