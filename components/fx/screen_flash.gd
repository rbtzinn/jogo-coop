class_name ScreenFlash
extends CanvasLayer
## Clarão rápido na tela inteira (bônus em dupla). Fraco de propósito, para não cansar a vista
## nem esconder os ataques.


static func spawn(color: Color, duration := 0.3) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var flash := ScreenFlash.new()
	flash.layer = 14
	tree.current_scene.add_child(flash)
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.add_child(rect)
	var tween := flash.create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)
