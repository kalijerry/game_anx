## Level 1 · A Bit Is Born
## The player flips 8 switches (one byte) to spell A, N, X in ASCII.
## Everything is drawn in code in the flat vector style, so there are no art assets yet.
extends Node2D

const P := preload("res://scripts/palette.gd")
const Bits := preload("res://scripts/bit_logic.gd")

const TARGETS := ["A", "N", "X"]
## Language button label for each Loc.Mode: both, Chinese, English.
const LANG_LABELS := ["中+EN", "中文", "EN"]
const CARD_W := 112.0
const CARD_H := 150.0
const CARD_GAP := 24.0
const CARD_Y := 300.0
const LANG_RECT := Rect2(1060, 36, 180, 48)
const REPLAY_RECT := Rect2(530, 462, 220, 56)

var bits: Array = [0, 0, 0, 0, 0, 0, 0, 0]
var cursor := 0
var stage := 0
var busy := false
var done := false
var msg_key := "intro"
var msg_args := {}
var anx_x := 0.0
var time := 0.0
var font: SystemFont


func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray([
		"PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "Noto Sans SC",
		"Source Han Sans SC", "WenQuanYi Zen Hei", "sans-serif",
	])
	anx_x = _card_rect(cursor).get_center().x
	Loc.changed.connect(queue_redraw)
	# Screenshot helper: godot --path . -- --demo=complete
	if "--demo=complete" in OS.get_cmdline_user_args():
		stage = TARGETS.size()
		done = true
		msg_key = "complete"


func _process(delta: float) -> void:
	time += delta
	var target_x := _card_rect(cursor).get_center().x
	anx_x = lerpf(anx_x, target_x, minf(1.0, delta * 14.0))
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(make_input_local(event).position)
	elif event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		_flip(cursor)


func _on_click(pos: Vector2) -> void:
	if LANG_RECT.has_point(pos):
		Loc.cycle()
		return
	if done:
		if REPLAY_RECT.has_point(pos):
			_restart()
		return
	for i in Bits.BYTE_SIZE:
		if _card_rect(i).grow(8).has_point(pos):
			cursor = i
			_flip(i)
			return


func _move(dir: int) -> void:
	if done:
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
	_draw_background()
	_draw_header()
	_draw_goal()
	for i in Bits.BYTE_SIZE:
		_draw_switch(i)
	_draw_anx(Vector2(anx_x, 232 + sin(time * 3.0) * 4.0), 1.0)
	_draw_readout()
	_draw_dialogue()
	if done:
		_draw_card()


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), P.BG)
	draw_circle(Vector2(1120, 110), 170, P.SUN)
	draw_circle(Vector2(110, 640), 210, P.MINT)
	draw_rect(Rect2(0, 470, 1280, 250), P.FLOOR)
	_rrect(Rect2(80, 450, 1120, 28), P.SHELF, 14)


func _draw_header() -> void:
	var t := Loc.lines("level_title")
	_text(Vector2(40, 66), t[0], 34, P.INK)
	if t.size() > 1:
		_text(Vector2(40, 100), t[1], 20, P.QUIET)
	_rrect(LANG_RECT, P.INK, 24)
	_text_c(LANG_RECT, LANG_RECT.position.y + 32, LANG_LABELS[Loc.mode], 20, P.WHITE)


func _draw_goal() -> void:
	var label := Loc.short("goal")
	_text(Vector2(500, 170), label, 22, P.QUIET)
	for i in TARGETS.size():
		var r := Rect2(640 + i * 64, 134, 52, 52)
		if i < stage:
			_rrect(r, P.TEAL, 14)
			_text_c(r, r.position.y + 37, TARGETS[i], 28, P.WHITE)
		elif i == stage and not done:
			_rrect(r, P.WHITE, 14, P.YELLOW, 3)
			_text_c(r, r.position.y + 37, TARGETS[i], 28, P.INK)
		else:
			_rrect(r, P.WHITE, 14)
			_text_c(r, r.position.y + 37, TARGETS[i], 28, P.SHELF)


func _draw_switch(i: int) -> void:
	var r := _card_rect(i)
	var on := int(bits[i]) == 1
	var fill := P.YELLOW if on else P.WHITE
	var border := P.YELLOW_DARK if i == cursor and not done else (P.YELLOW if on else P.SHELF)
	_rrect(r, fill, 22, border, 4 if i == cursor and not done else 2)
	_text_c(r, r.position.y + 78, str(bits[i]), 54, P.INK if on else P.QUIET)
	_text_c(r, r.position.y + 126, str(Bits.weight(i)), 20, P.INK if on else P.QUIET)


func _draw_anx(c: Vector2, s: float) -> void:
	# Antenna
	draw_line(c + Vector2(0, -34) * s, c + Vector2(0, -56) * s, P.FACE, 5 * s)
	draw_circle(c + Vector2(0, -60) * s, 9 * s, P.YELLOW)
	# Body
	_rrect(Rect2(c + Vector2(-50, -34) * s, Vector2(100, 84) * s), P.TEAL, int(32 * s))
	# Eyes, blinking every few seconds
	var blink := fmod(time, 3.2) < 0.12
	for ex in [-18.0, 18.0]:
		var e := c + Vector2(ex, 2) * s
		if blink:
			draw_line(e + Vector2(-8, 0) * s, e + Vector2(8, 0) * s, P.FACE, 4 * s)
		else:
			draw_circle(e, 9 * s, P.FACE)
			draw_circle(e + Vector2(3, -3) * s, 3 * s, P.WHITE)
	# Cheeks and smile
	draw_circle(c + Vector2(-36, 18) * s, 6 * s, Color(P.PINK, 0.7))
	draw_circle(c + Vector2(36, 18) * s, 6 * s, Color(P.PINK, 0.7))
	draw_arc(c + Vector2(0, 16) * s, 12 * s, 0.3, PI - 0.3, 12, P.FACE, 4 * s)


func _draw_readout() -> void:
	var value := Bits.bits_to_int(bits)
	var items := [
		[Loc.short("binary"), Bits.bits_to_string(bits)],
		[Loc.short("decimal"), str(value)],
		[Loc.short("char"), Bits.to_char(value)],
	]
	var x := 120.0
	for it in items:
		var label: String = it[0]
		var val: String = it[1]
		_text(Vector2(x, 518), label, 18, P.QUIET)
		var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		_text(Vector2(x + lw + 12, 520), val, 28, P.INK)
		x += lw + 12 + font.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 64
	var c := Loc.lines("controls")
	_text(Vector2(120, 552), c[0], 15, P.QUIET)


func _draw_dialogue() -> void:
	var box := Rect2(40, 570, 1200, 124)
	_rrect(box, P.WHITE, 28)
	_draw_anx(Vector2(112, 640), 0.55)
	var speaker := Loc.short("speaker")
	var lines := Loc.lines(msg_key, msg_args)
	_text(Vector2(180, 616), speaker + "：", 24, P.TEAL_DARK)
	var sw := font.get_string_size(speaker + "：", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	_text(Vector2(180 + sw, 616), lines[0], 24, P.INK)
	if lines.size() > 1:
		_text(Vector2(180, 654), lines[1], 20, P.QUIET)


func _draw_card() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(P.INK, 0.45))
	var r := Rect2(240, 90, 800, 450)
	_rrect(r, P.WHITE, 32)
	_rrect(Rect2(r.position.x, r.position.y, r.size.x, 88), P.TEAL, 32)
	draw_rect(Rect2(r.position.x, r.position.y + 56, r.size.x, 32), P.TEAL)
	var title := Loc.lines("card_title")
	_text_c(r, r.position.y + 56, title[0], 30, P.WHITE)
	var y := r.position.y + 140
	for key in ["card_1", "card_2", "card_3"]:
		var ls := Loc.lines(key)
		draw_circle(Vector2(r.position.x + 56, y - 8), 8, P.YELLOW)
		_text(Vector2(r.position.x + 80, y), ls[0], 22, P.INK)
		if ls.size() > 1:
			_text(Vector2(r.position.x + 80, y + 30), ls[1], 17, P.QUIET)
		y += 88
	_rrect(REPLAY_RECT, P.INK, 28)
	_text_c(REPLAY_RECT, REPLAY_RECT.position.y + 36, Loc.short("replay"), 20, P.WHITE)


# ---------------------------------------------------------------- helpers

func _rrect(r: Rect2, color: Color, radius: int, border := Color.TRANSPARENT, border_w := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	draw_style_box(sb, r)


func _text(pos: Vector2, s: String, size: int, color: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_c(r: Rect2, baseline: float, s: String, size: int, color: Color) -> void:
	draw_string(font, Vector2(r.position.x, baseline), s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, color)
