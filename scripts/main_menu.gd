## Main menu: pick Chinese or English, then start.
extends "res://scripts/flat_canvas.gd"

const LEVEL_1 := "res://scenes/level_01.tscn"
const ZH_RECT := Rect2(440, 420, 180, 56)
const EN_RECT := Rect2(660, 420, 180, 56)
const START_RECT := Rect2(490, 520, 300, 68)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = make_input_local(event).position
		if ZH_RECT.has_point(pos):
			Loc.set_mode(Loc.Mode.ZH)
		elif EN_RECT.has_point(pos):
			Loc.set_mode(Loc.Mode.EN)
		elif START_RECT.has_point(pos):
			_start()
	elif event.is_action_pressed("ui_left"):
		Loc.set_mode(Loc.Mode.ZH)
	elif event.is_action_pressed("ui_right"):
		Loc.set_mode(Loc.Mode.EN)
	elif event.is_action_pressed("ui_accept"):
		_start()


func _start() -> void:
	get_tree().change_scene_to_file(LEVEL_1)


func _draw() -> void:
	draw_background()
	draw_anx(Vector2(640, 170 + sin(time * 2.5) * 6.0), 1.4)
	text_c(Rect2(0, 0, 1280, 0), 320, Loc.text("game_title"), 52, P.INK)
	text_c(Rect2(0, 0, 1280, 0), 364, Loc.text("menu_subtitle"), 22, P.QUIET)
	# Language names stay in their own language so anyone can find theirs.
	button(ZH_RECT, "中文", Loc.mode == Loc.Mode.ZH)
	button(EN_RECT, "English", Loc.mode == Loc.Mode.EN)
	rrect(START_RECT, P.TEAL, 34)
	text_c(START_RECT, START_RECT.position.y + 44, Loc.text("start"), 28, P.WHITE)
	text_c(Rect2(0, 0, 1280, 0), 680, Loc.text("menu_hint"), 16, P.QUIET)
