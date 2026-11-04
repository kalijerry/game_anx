## Developer console (autoload). Open with the ` key, or tap the top-left corner 5 times on touch.
## Commands: test (level select), menu, lang zh|en, help.
extends CanvasLayer

const P := preload("res://scripts/palette.gd")
const Levels := preload("res://scripts/levels.gd")
const UI_FONT: FontFile = preload("res://assets/fonts/anx_ui.ttf")
const TAP_CORNER := Rect2(0, 0, 90, 90)

var root: Control
var input: LineEdit
var output: Label
var level_box: VBoxContainer
var taps: Array[float] = []


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	root.hide()
	# Screenshot helper: godot --path . -- --demo=console
	if "--demo=console" in OS.get_cmdline_user_args():
		toggle.call_deferred()
		run.call_deferred("test")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
		toggle()
		get_viewport().set_input_as_handled()
	elif root.visible and event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and not root.visible:
		_count_tap(event.position)


func _count_tap(pos: Vector2) -> void:
	var local: Vector2 = root.get_global_transform_with_canvas().affine_inverse() * pos
	if not TAP_CORNER.has_point(local):
		taps.clear()
		return
	var now := Time.get_ticks_msec() / 1000.0
	taps.append(now)
	taps = taps.filter(func(t: float) -> bool: return now - t < 2.0)
	if taps.size() >= 5:
		taps.clear()
		toggle()


func toggle() -> void:
	root.visible = not root.visible
	if root.visible:
		level_box.hide()
		output.text = Loc.text("console_help")
		input.clear()
		input.grab_focus()
	else:
		input.release_focus()


func run(command: String) -> void:
	var parts := command.strip_edges().to_lower().split(" ", false)
	if parts.is_empty():
		return
	match parts[0]:
		"test":
			_show_levels()
		"menu":
			_go(Levels.MENU)
		"lang":
			if parts.size() > 1 and parts[1] in ["zh", "en"]:
				Loc.set_mode(Loc.Mode.ZH if parts[1] == "zh" else Loc.Mode.EN)
				_refresh_levels()
			output.text = Loc.text("console_help")
		"help":
			output.text = Loc.text("console_help")
		_:
			output.text = Loc.text("console_unknown", {"cmd": parts[0]})


func _on_submit(command: String) -> void:
	input.clear()
	run(command)
	if root.visible:
		input.grab_focus()


func _show_levels() -> void:
	_refresh_levels()
	level_box.show()
	output.text = Loc.text("level_select")


func _refresh_levels() -> void:
	for c in level_box.get_children():
		c.queue_free()
	for i in Levels.LEVELS.size():
		var lv: Dictionary = Levels.LEVELS[i]
		var b := Button.new()
		b.text = Loc.text(lv["title"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_go.bind(lv["scene"]))
		level_box.add_child(b)


func _go(scene: String) -> void:
	root.hide()
	input.release_focus()
	get_tree().change_scene_to_file(scene)


# ---------------------------------------------------------------- UI

func _build() -> void:
	var theme := Theme.new()
	theme.default_font = UI_FONT
	theme.default_font_size = 20
	theme.set_stylebox("normal", "Button", _box(Color(P.WHITE, 0.08), 12))
	theme.set_stylebox("hover", "Button", _box(Color(P.TEAL, 0.35), 12))
	theme.set_stylebox("pressed", "Button", _box(P.TEAL, 12))
	theme.set_stylebox("focus", "Button", _box(Color(P.TEAL, 0.35), 12))
	theme.set_color("font_color", "Button", P.WHITE)
	theme.set_color("font_hover_color", "Button", P.WHITE)
	theme.set_stylebox("normal", "LineEdit", _box(Color(P.WHITE, 0.1), 10))
	theme.set_stylebox("focus", "LineEdit", _box(Color(P.WHITE, 0.14), 10))
	theme.set_color("font_color", "LineEdit", P.WHITE)
	theme.set_color("caret_color", "LineEdit", P.YELLOW)
	theme.set_color("font_color", "Label", Color(P.WHITE, 0.8))

	root = Control.new()
	root.theme = theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(P.INK, 0.96), 20, 20))
	panel.position = Vector2(40, 40)
	panel.custom_minimum_size = Vector2(640, 0)
	root.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var title := Label.new()
	title.text = "> console"
	title.add_theme_color_override("font_color", P.YELLOW)
	col.add_child(title)

	input = LineEdit.new()
	input.placeholder_text = "test / help"
	input.custom_minimum_size = Vector2(0, 44)
	input.text_submitted.connect(_on_submit)
	col.add_child(input)

	output = Label.new()
	output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output.add_theme_font_size_override("font_size", 16)
	col.add_child(output)

	level_box = VBoxContainer.new()
	level_box.add_theme_constant_override("separation", 8)
	col.add_child(level_box)


func _box(color: Color, radius: int, margin := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.6
	sb.content_margin_bottom = margin * 0.6
	return sb
