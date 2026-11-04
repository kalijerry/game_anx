## Level 1 · A Bit Is Born
## The player flips 8 switches (one byte) to spell A, N, X in ASCII.
## Everything is drawn in code in the flat vector style, so there are no art assets yet.
extends "res://scripts/flat_canvas.gd"

const Bits := preload("res://scripts/bit_logic.gd")
const Levels := preload("res://scripts/levels.gd")

const TARGETS := ["A", "N", "X"]
const CARD_W := 112.0
const CARD_H := 150.0
const CARD_GAP := 24.0
const CARD_Y := 300.0
const MENU_RECT := Rect2(1100, 36, 140, 48)
const ASCII_RECT := Rect2(940, 36, 144, 48)
const TABLE_RECT := Rect2(100, 96, 1080, 508)
const TABLE_COLS := 9
const CLOSE_RECT := Rect2(560, 530, 160, 52)
const REPLAY_RECT := Rect2(400, 462, 220, 56)
const NEXT_RECT := Rect2(660, 462, 220, 56)

var bits: Array = [0, 0, 0, 0, 0, 0, 0, 0]
var cursor := 0
var stage := 0
var busy := false
var done := false
var msg_key := "intro"
var msg_args := {}
var anx_x := 0.0
var table_open := false
var table_seen := false


func _ready() -> void:
	anx_x = _card_rect(cursor).get_center().x
	# Screenshot helper: godot --path . res://scenes/level_01.tscn -- --demo=complete
	if "--demo=complete" in OS.get_cmdline_user_args():
		stage = TARGETS.size()
		done = true
		msg_key = "complete"
	# Screenshot helper: ... -- --demo=table  (goal N, bits currently spell M)
	if "--demo=table" in OS.get_cmdline_user_args():
		stage = 1
		bits = Bits.int_to_bits(77)
		table_open = true
		table_seen = true
		_show_hint()


func _process(delta: float) -> void:
	super(delta)
	var target_x := _card_rect(cursor).get_center().x
	anx_x = lerpf(anx_x, target_x, minf(1.0, delta * 14.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(make_input_local(event).position)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_toggle_table()
	elif event.is_action_pressed("ui_cancel"):
		if table_open:
			_toggle_table()
		else:
			_to_menu()
	elif event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		if table_open:
			_toggle_table()
		elif done:
			_next_level()
		else:
			_flip(cursor)


func _on_click(pos: Vector2) -> void:
	if MENU_RECT.has_point(pos):
		_to_menu()
		return
	if table_open:
		# Any click closes the table, so the switches are never blocked.
		_toggle_table()
		return
	if ASCII_RECT.has_point(pos):
		_toggle_table()
		return
	if done:
		if REPLAY_RECT.has_point(pos):
			_restart()
		elif NEXT_RECT.has_point(pos):
			_next_level()
		return
	for i in Bits.BYTE_SIZE:
		if _card_rect(i).grow(8).has_point(pos):
			cursor = i
			_flip(i)
			return


func _toggle_table() -> void:
	table_open = not table_open
	table_seen = true


func _to_menu() -> void:
	get_tree().change_scene_to_file(Levels.MENU)


func _next_level() -> void:
	get_tree().change_scene_to_file(Levels.LEVELS[1]["scene"])


func _move(dir: int) -> void:
	if done or table_open:
		return
	cursor = clampi(cursor + dir, 0, Bits.BYTE_SIZE - 1)


func _flip(i: int) -> void:
	if busy or done:
		return
	bits[i] = 1 - int(bits[i])
	if msg_key == "intro":
		_show_hint()
	_check()


func _check() -> void:
	var value := Bits.bits_to_int(bits)
	var letter: String = TARGETS[stage]
	if value != letter.unicode_at(0):
		return
	busy = true
	msg_key = "success"
	msg_args = {"letter": letter, "value": value}
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	stage += 1
	if stage >= TARGETS.size():
		done = true
		msg_key = "complete"
		msg_args = {}
	else:
		bits = [0, 0, 0, 0, 0, 0, 0, 0]
		_show_hint()
	busy = false


func _show_hint() -> void:
	var letter: String = TARGETS[stage]
	msg_key = "hint"
	msg_args = {"letter": letter, "value": letter.unicode_at(0)}


func _restart() -> void:
	bits = [0, 0, 0, 0, 0, 0, 0, 0]
	cursor = 0
	stage = 0
	done = false
	msg_key = "intro"
	msg_args = {}


# ---------------------------------------------------------------- drawing

func _card_rect(i: int) -> Rect2:
	var total := CARD_W * 8 + CARD_GAP * 7
	var x0 := (1280.0 - total) / 2.0
	return Rect2(x0 + i * (CARD_W + CARD_GAP), CARD_Y, CARD_W, CARD_H)


func _draw() -> void:
	draw_background()
	rrect(Rect2(80, 450, 1120, 28), P.SHELF, 14)
	text(Vector2(40, 72), Loc.text("level_title"), 34, P.INK)
	button(MENU_RECT, Loc.text("menu"))
	_draw_ascii_button()
	_draw_goal()
	for i in Bits.BYTE_SIZE:
		_draw_switch(i)
	draw_anx(Vector2(anx_x, 232 + sin(time * 3.0) * 4.0), 1.0)
	_draw_readout()
	_draw_dialogue()
	if table_open:
		_draw_table()
	elif done:
		_draw_card()


func _draw_goal() -> void:
	var label := Loc.text("goal")
	text(Vector2(620 - text_width(label, 22), 170), label, 22, P.QUIET)
	for i in TARGETS.size():
		var r := Rect2(640 + i * 64, 134, 52, 52)
		if i < stage:
			rrect(r, P.TEAL, 14)
			text_c(r, r.position.y + 37, TARGETS[i], 28, P.WHITE)
		elif i == stage and not done:
			rrect(r, P.WHITE, 14, P.YELLOW, 3)
			text_c(r, r.position.y + 37, TARGETS[i], 28, P.INK)
		else:
			rrect(r, P.WHITE, 14)
			text_c(r, r.position.y + 37, TARGETS[i], 28, P.SHELF)


func _draw_switch(i: int) -> void:
	var r := _card_rect(i)
	var on := int(bits[i]) == 1
	var fill := P.YELLOW if on else P.WHITE
	var focused := i == cursor and not done
	var border := P.YELLOW_DARK if focused else (P.YELLOW if on else P.SHELF)
	rrect(r, fill, 22, border, 4 if focused else 2)
	text_c(r, r.position.y + 78, str(bits[i]), 54, P.INK if on else P.QUIET)
	text_c(r, r.position.y + 126, str(Bits.weight(i)), 20, P.INK if on else P.QUIET)


func _draw_readout() -> void:
	var value := Bits.bits_to_int(bits)
	var items := [
		[Loc.text("binary"), Bits.bits_to_string(bits)],
		[Loc.text("decimal"), str(value)],
		[Loc.text("char"), Bits.to_char(value)],
	]
	var x := 120.0
	for it in items:
		var label: String = it[0]
		var val: String = it[1]
		text(Vector2(x, 518), label, 18, P.QUIET)
		var lw := text_width(label, 18)
		text(Vector2(x + lw + 12, 520), val, 28, P.INK)
		x += lw + 12 + text_width(val, 28) + 64
	text(Vector2(120, 552), Loc.text("controls"), 15, P.QUIET)


func _draw_dialogue() -> void:
	rrect(Rect2(40, 570, 1200, 124), P.WHITE, 28)
	draw_anx(Vector2(112, 640), 0.55)
	var speaker := Loc.text("speaker") + ("：" if Loc.mode == Loc.Mode.ZH else ": ")
	text(Vector2(180, 642), speaker, 24, P.TEAL_DARK)
	text(Vector2(180 + text_width(speaker, 24), 642), Loc.text(msg_key, msg_args), 24, P.INK)


func _draw_card() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(P.INK, 0.45))
	var r := Rect2(200, 110, 880, 430)
	rrect(r, P.WHITE, 32)
	rrect(Rect2(r.position.x, r.position.y, r.size.x, 88), P.TEAL, 32)
	draw_rect(Rect2(r.position.x, r.position.y + 56, r.size.x, 32), P.TEAL)
	text_c(r, r.position.y + 56, Loc.text("card_title"), 30, P.WHITE)
	var y := r.position.y + 150
	for key in ["card_1", "card_2", "card_3"]:
		draw_circle(Vector2(r.position.x + 56, y - 7), 8, P.YELLOW)
		text(Vector2(r.position.x + 80, y), Loc.text(key), 22, P.INK)
		y += 72
	button(REPLAY_RECT, Loc.text("replay"), false)
	button(NEXT_RECT, Loc.text("next_level"))


func _draw_ascii_button() -> void:
	# Pulses in yellow until the player has opened the table once.
	if table_seen or done:
		button(ASCII_RECT, Loc.text("ascii_button"), table_open)
		return
	var glow := 0.5 + 0.5 * sin(time * 4.0)
	rrect(ASCII_RECT.grow(4 * glow), Color(P.YELLOW, 0.5 * glow), 28)
	rrect(ASCII_RECT, P.YELLOW, 24)
	text_c(ASCII_RECT, ASCII_RECT.position.y + 31, Loc.text("ascii_button"), 20, P.INK)


func _draw_table() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(P.INK, 0.45))
	var r := TABLE_RECT
	rrect(r, P.WHITE, 32)
	text_c(r, r.position.y + 52, Loc.text("ascii_title"), 28, P.INK)
	var goal := -1 if done else String(TARGETS[stage]).unicode_at(0)
	var now := Bits.bits_to_int(bits)
	var cw := 112.0
	var ch := 98.0
	var x0 := r.position.x + (r.size.x - cw * TABLE_COLS) / 2.0
	var y0 := r.position.y + 76
	for i in 26:
		var code := 65 + i
		var cell := Rect2(x0 + (i % TABLE_COLS) * cw + 4, y0 + (i / TABLE_COLS) * ch + 4, cw - 8, ch - 8)
		var fill := P.BG
		if code == now:
			fill = Color(P.TEAL, 0.35)
		if code == goal:
			fill = P.YELLOW
		rrect(cell, fill, 14, P.TEAL_DARK if code == now else Color.TRANSPARENT, 3 if code == now else 0)
		text_c(cell, cell.position.y + 34, String.chr(code), 28, P.INK)
		text_c(cell, cell.position.y + 60, str(code), 18, P.INK)
		text_c(cell, cell.position.y + 80, Bits.bits_to_string(Bits.int_to_bits(code)), 13, P.QUIET)
	text_c(r, y0 + ch * 3 + 26, Loc.text("ascii_note"), 16, P.QUIET)
	button(CLOSE_RECT, Loc.text("close"))
