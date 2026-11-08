## Base for screens drawn in code in the flat vector style:
## shared font, background, rounded boxes, text, and the ANX character.
extends Node2D

const P := preload("res://scripts/palette.gd")
const UI_FONT: FontFile = preload("res://assets/fonts/anx_ui.ttf")

var font: Font
var time := 0.0

## Playtest probe: when the bot turns it on, every label and button drawn is recorded, so the
## bot can "see" the screen and the UI audit can spot text that spills out of its box.
## ui_seen holds the last finished frame; ui_drawing collects the frame being drawn.
static var probe_on := false
var ui_seen: Array = []
var ui_drawing: Array = []


func _init() -> void:
	# Bundled subset of Noto Sans SC (tools/subset_font.py); system fonts only as a fallback.
	font = UI_FONT.duplicate()
	var system := SystemFont.new()
	system.font_names = PackedStringArray(["PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	font.fallbacks = [system]


func _enter_tree() -> void:
	if not Loc.changed.is_connected(queue_redraw):
		Loc.changed.connect(queue_redraw)


func _process(delta: float) -> void:
	time += delta
	if probe_on:
		ui_seen = ui_drawing
		ui_drawing = []
	queue_redraw()


func _probe(kind: String, s: String, r: Rect2, box := Rect2()) -> void:
	if probe_on:
		ui_drawing.append({"kind": kind, "text": s, "rect": r, "box": box})


func draw_background() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), P.BG)
	draw_circle(Vector2(1120, 110), 170, P.SUN)
	draw_circle(Vector2(110, 640), 210, P.MINT)
	draw_rect(Rect2(0, 470, 1280, 250), P.FLOOR)


func draw_anx(c: Vector2, s: float) -> void:
	# Antenna
	draw_line(c + Vector2(0, -34) * s, c + Vector2(0, -56) * s, P.FACE, 5 * s)
	draw_circle(c + Vector2(0, -60) * s, 9 * s, P.YELLOW)
	# Body
	rrect(Rect2(c + Vector2(-50, -34) * s, Vector2(100, 84) * s), P.TEAL, int(32 * s))
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


## A pill button. Filled when active, outlined otherwise.
func button(r: Rect2, label: String, active := true) -> void:
	_probe("button", label, r)
	if active:
		rrect(r, P.INK, int(r.size.y / 2))
		text_c(r, r.position.y + r.size.y / 2 + 7, label, 20, P.WHITE)
	else:
		rrect(r, P.WHITE, int(r.size.y / 2), P.SHELF, 2)
		text_c(r, r.position.y + r.size.y / 2 + 7, label, 20, P.QUIET)


func rrect(r: Rect2, color: Color, radius: int, border := Color.TRANSPARENT, border_w := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	draw_style_box(sb, r)


func text(pos: Vector2, s: String, size: int, color: Color) -> void:
	_probe("text", s, Rect2(pos.x, pos.y - size, text_width(s, size), size))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func text_c(r: Rect2, baseline: float, s: String, size: int, color: Color) -> void:
	if probe_on:
		var w := text_width(s, size)
		var box := Rect2(r.position.x, baseline - size, r.size.x, size)
		_probe("text", s, Rect2(r.get_center().x - w / 2.0, baseline - size, w, size), box)
	draw_string(font, Vector2(r.position.x, baseline), s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, color)


func text_width(s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Greedy line wrap that works for both languages: each CJK character can break, English
## breaks at spaces. Returns the lines; does not depend on the text server's ICU data.
func wrap_lines(s: String, size: int, width: float) -> Array:
	var tokens: Array = []
	var word := ""
	for ch in s:
		var code := ch.unicode_at(0)
		if ch == " ":
			if word != "":
				tokens.append(word)
			tokens.append(" ")
			word = ""
		elif code >= 0x2E80:
			if word != "":
				tokens.append(word)
			tokens.append(ch)
			word = ""
		else:
			word += ch
	if word != "":
		tokens.append(word)
	var lines: Array = []
	var line := ""
	for t in tokens:
		var trial: String = line + t
		if line != "" and text_width(trial, size) > width:
			lines.append(line.strip_edges())
			line = "" if t == " " else t
		else:
			line = trial
	if line.strip_edges() != "":
		lines.append(line.strip_edges())
	return lines


func text_wrap(pos: Vector2, s: String, size: int, color: Color, width: float, line_h: float) -> void:
	var y := pos.y
	for line in wrap_lines(s, size, width):
		text(Vector2(pos.x, y), line, size, color)
		y += line_h
