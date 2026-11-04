## Level 2 · The Clock Ticks
## A clock drives an 8-bit shift register. The player sets input D; on each rising edge the
## register shifts left and captures D on the right. Load G, then O, at a faster clock.
extends "res://scripts/flat_canvas.gd"

const Bits := preload("res://scripts/bit_logic.gd")
const Clock := preload("res://scripts/clock_logic.gd")
const Levels := preload("res://scripts/levels.gd")

const TARGETS := ["G", "O"]
## Seconds per clock cycle for each target: the second round runs faster.
const PERIODS := [1.3, 0.85]
const MENU_RECT := Rect2(1100, 36, 140, 48)
const D_RECT := Rect2(80, 322, 120, 132)
const REG_X := 300.0
const REG_Y := 330.0
const CELL_W := 100.0
const CELL_GAP := 12.0
const WAVE_RECT := Rect2(300, 214, 884, 64)
## Pixels per clock cycle in the waveform; the "now" marker sits at the wave's left third.
const WAVE_PX := 200.0
const REPLAY_RECT := Rect2(400, 462, 220, 56)
const MENU_BTN_RECT := Rect2(660, 462, 220, 56)

var reg: Array = [0, 0, 0, 0, 0, 0, 0, 0]
var d := 0
var phase := 0.25
var stage := 0
var busy := false
var done := false
var msg_key := "l2_intro"
var msg_args := {}
var edge_flash := 0.0
var edges := 0


func _ready() -> void:
	if "--demo=complete" in OS.get_cmdline_user_args():
		stage = TARGETS.size()
		done = true
		msg_key = "l2_complete"


func _process(delta: float) -> void:
	super(delta)
	edge_flash = maxf(0.0, edge_flash - delta * 3.0)
	if busy or done:
		return
	phase += delta / float(PERIODS[stage])
	if phase >= 1.0:
		phase -= 1.0
		_on_rising_edge()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = make_input_local(event).position
		if MENU_RECT.has_point(pos):
			_to_menu()
		elif done and REPLAY_RECT.has_point(pos):
			_restart()
		elif done and MENU_BTN_RECT.has_point(pos):
			_to_menu()
		elif D_RECT.grow(16).has_point(pos):
			_toggle_d()
	elif event.is_action_pressed("ui_cancel"):
		_to_menu()
	elif event.is_action_pressed("ui_accept"):
		if done:
			_restart()
		else:
			_toggle_d()


func _toggle_d() -> void:
	if done:
		return
	d = 1 - d


func _on_rising_edge() -> void:
	reg = Clock.shift_in(reg, d)
	edges += 1
	edge_flash = 1.0
	if msg_key == "l2_intro" and edges >= 2:
		_show_hint()
	_check()


func _target_bits() -> String:
	return Bits.bits_to_string(Bits.int_to_bits(String(TARGETS[stage]).unicode_at(0)))


func _show_hint() -> void:
	msg_key = "l2_hint" if stage == 0 else "l2_hint_fast"
	msg_args = {"letter": TARGETS[stage], "bits": _target_bits()}


func _check() -> void:
	var letter: String = TARGETS[stage]
	if Bits.bits_to_int(reg) != letter.unicode_at(0):
		return
	busy = true
	msg_key = "l2_success"
	msg_args = {"letter": letter, "bits": _target_bits()}
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	stage += 1
	if stage >= TARGETS.size():
		done = true
		msg_key = "l2_complete"
		msg_args = {}
	else:
		reg = [0, 0, 0, 0, 0, 0, 0, 0]
		d = 0
		phase = 0.25
		_show_hint()
	busy = false


func _restart() -> void:
	reg = [0, 0, 0, 0, 0, 0, 0, 0]
	d = 0
	phase = 0.25
	stage = 0
	edges = 0
	done = false
	msg_key = "l2_intro"
	msg_args = {}


func _to_menu() -> void:
	get_tree().change_scene_to_file(Levels.MENU)


# ---------------------------------------------------------------- drawing

func _cell_rect(i: int) -> Rect2:
	return Rect2(REG_X + i * (CELL_W + CELL_GAP), REG_Y, CELL_W, 116)


func _draw() -> void:
	draw_background()
	rrect(Rect2(60, 470, 1160, 28), P.SHELF, 14)
	text(Vector2(40, 72), Loc.text("level2_title"), 34, P.INK)
	button(MENU_RECT, Loc.text("menu"))
	_draw_goal()
	_draw_wave()
	_draw_input()
	_draw_register()
	_draw_readout()
	_draw_dialogue()
	if done:
		_draw_card()


func _draw_goal() -> void:
	var label := Loc.text("goal")
	text(Vector2(560 - text_width(label, 22), 160), label, 22, P.QUIET)
	for i in TARGETS.size():
		var r := Rect2(580 + i * 64, 124, 52, 52)
		if i < stage:
			rrect(r, P.TEAL, 14)
			text_c(r, r.position.y + 37, TARGETS[i], 28, P.WHITE)
		elif i == stage and not done:
			rrect(r, P.WHITE, 14, P.YELLOW, 3)
			text_c(r, r.position.y + 37, TARGETS[i], 28, P.INK)
		else:
			rrect(r, P.WHITE, 14)
			text_c(r, r.position.y + 37, TARGETS[i], 28, P.SHELF)
	if not done:
		text(Vector2(720, 160), "= " + _target_bits(), 26, P.INK)


func _draw_wave() -> void:
	var w := WAVE_RECT
	var now_x := w.position.x + w.size.x / 3.0
	text(Vector2(w.position.x, w.position.y - 18), Loc.text("clock"), 18, P.QUIET)
	rrect(w.grow(10), P.WHITE, 16)
	var hi := w.position.y + 6
	var lo := w.end.y - 6
	var pts := PackedVector2Array()
	var prev := -1.0
	var x := w.position.x
	while x <= w.end.x:
		var p := phase + (x - now_x) / WAVE_PX
		var y := hi if Clock.is_high(p) else lo
		if prev >= 0.0 and y != prev:
			pts.append(Vector2(x, prev))
		pts.append(Vector2(x, y))
		prev = y
		x += 1.0
	draw_polyline(pts, P.TEAL_DARK, 3.0, true)
	# Marker for "now", and an arrow where the next rising edge will land.
	draw_line(Vector2(now_x, w.position.y - 8), Vector2(now_x, w.end.y + 8), Color(P.INK, 0.5), 2.0)
	var next_x := now_x + (1.0 - phase) * WAVE_PX
	if not done and next_x <= w.end.x:
		draw_line(Vector2(next_x, lo), Vector2(next_x, hi), P.YELLOW_DARK, 4.0)
		text(Vector2(next_x + 8, hi + 18), "↑ " + Loc.text("rising_edge"), 15, P.YELLOW_DARK)


func _draw_input() -> void:
	var r := D_RECT
	var on := d == 1
	text_c(r, r.position.y - 14, Loc.text("input_d"), 18, P.QUIET)
	rrect(r, P.YELLOW if on else P.WHITE, 22, P.YELLOW_DARK, 4)
	text_c(r, r.position.y + 86, str(d), 60, P.INK if on else P.QUIET)
	# Wire from D into the register's right end, routed under the cells.
	var wire := Color(P.YELLOW_DARK if on else P.SHELF)
	var right := _cell_rect(7).end.x + 30
	var yb := REG_Y + 134
	draw_polyline(PackedVector2Array([
		Vector2(r.get_center().x, r.end.y), Vector2(r.get_center().x, yb),
		Vector2(right, yb), Vector2(right, REG_Y + 58), Vector2(_cell_rect(7).end.x + 4, REG_Y + 58),
	]), wire, 4.0)
	draw_anx(Vector2(r.get_center().x, 252 + sin(time * 3.0) * 4.0), 0.75)


func _draw_register() -> void:
	text(Vector2(REG_X, REG_Y - 14), Loc.text("register"), 18, P.QUIET)
	for i in 8:
		var r := _cell_rect(i)
		var on := int(reg[i]) == 1
		var flash := edge_flash if not done else 0.0
		rrect(r, P.YELLOW if on else P.WHITE, 20, Color(P.TEAL, flash), int(4 * flash) if flash > 0.05 else 0)
		text_c(r, r.position.y + 70, str(reg[i]), 48, P.INK if on else P.QUIET)
		text_c(r, r.position.y + 104, str(Bits.weight(i)), 16, P.INK if on else P.QUIET)


func _draw_readout() -> void:
	var value := Bits.bits_to_int(reg)
	var x := 300.0
	for it in [[Loc.text("value"), str(value)], [Loc.text("char"), Bits.to_char(value)]]:
		var label: String = it[0]
		var val: String = it[1]
		text(Vector2(x, 530), label, 18, P.QUIET)
		var lw := text_width(label, 18)
		text(Vector2(x + lw + 12, 532), val, 28, P.INK)
		x += lw + 12 + text_width(val, 28) + 64
	text(Vector2(x + 24, 530), Loc.text("l2_controls"), 15, P.QUIET)


func _draw_dialogue() -> void:
	rrect(Rect2(40, 570, 1200, 124), P.WHITE, 28)
	draw_anx(Vector2(112, 640), 0.55)
	var speaker := Loc.text("speaker") + ("：" if Loc.mode == Loc.Mode.ZH else ": ")
	text(Vector2(180, 642), speaker, 24, P.TEAL_DARK)
	text(Vector2(180 + text_width(speaker, 24), 642), Loc.text(msg_key, msg_args), 22, P.INK)


func _draw_card() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(P.INK, 0.45))
	var r := Rect2(200, 110, 880, 430)
	rrect(r, P.WHITE, 32)
	rrect(Rect2(r.position.x, r.position.y, r.size.x, 88), P.TEAL, 32)
	draw_rect(Rect2(r.position.x, r.position.y + 56, r.size.x, 32), P.TEAL)
	text_c(r, r.position.y + 56, Loc.text("card2_title"), 30, P.WHITE)
	var y := r.position.y + 150
	for key in ["card2_1", "card2_2", "card2_3"]:
		draw_circle(Vector2(r.position.x + 56, y - 7), 8, P.YELLOW)
		text(Vector2(r.position.x + 80, y), Loc.text(key), 22, P.INK)
		y += 72
	button(REPLAY_RECT, Loc.text("replay"))
	button(MENU_BTN_RECT, Loc.text("main_menu"), false)
