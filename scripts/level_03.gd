## Level 3 · Fetch
## For complete beginners: ANX first walks through what memory, an address, the PC and the IR
## are, one sentence at a time, with the part being explained highlighted. Then the player
## fetches: go to the cell the PC points at, the instruction lands in IR, PC adds 1, except
## after JMP, which rewrites it. Fetch until HALT.
extends "res://scripts/flat_canvas.gd"

const Bits := preload("res://scripts/bit_logic.gd")
const Cpu := preload("res://scripts/cpu_logic.gd")
const Levels := preload("res://scripts/levels.gd")

## Teaching sentences shown before play, and which part of the screen each one is about.
const TEACH := [
	{"key": "l3_t1", "focus": "memory"},
	{"key": "l3_t2", "focus": "memory"},
	{"key": "l3_t3", "focus": "memory"},
	{"key": "l3_t4", "focus": "pc"},
	{"key": "l3_t5", "focus": "ir"},
]
const CELLS := 8
const MENU_RECT := Rect2(1100, 36, 140, 48)
const PC_RECT := Rect2(80, 104, 300, 116)
const IR_RECT := Rect2(408, 104, 792, 116)
const CELL_W := 128.0
const CELL_H := 128.0
const CELL_GAP := 14.0
const CELL_Y := 304.0
const NEXT_BTN := Rect2(1076, 608, 140, 52)
const REPLAY_RECT := Rect2(400, 462, 220, 56)
const MENU_BTN_RECT := Rect2(660, 462, 220, 56)

var mem: Array = Cpu.PROGRAM.duplicate()
var pc := 0
var ir := -1
var cursor := 0
var fetched := 0
var visited: Array = []
var teach := 0
var done := false
var wrong_flash := 0.0
var fetch_flash := 0.0
var msg_key := "l3_t1"
var msg_args := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in TEACH.size():
		if "--demo=teach%d" % (i + 1) in args:
			teach = i
			msg_key = TEACH[i]["key"]
	if "--demo=complete" in args:
		_skip_teach()
		for a in Cpu.fetch_order(mem):
			cursor = a
			_fetch()
	elif "--demo=jump" in args:
		_skip_teach()
		for a in [0, 1, 2]:
			cursor = a
			_fetch()
	elif "--demo=play" in args:
		_skip_teach()


func _process(delta: float) -> void:
	super(delta)
	wrong_flash = maxf(0.0, wrong_flash - delta * 2.0)
	fetch_flash = maxf(0.0, fetch_flash - delta * 2.0)


func teaching() -> bool:
	return teach < TEACH.size()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = make_input_local(event).position
		if MENU_RECT.has_point(pos):
			_to_menu()
		elif teaching():
			_advance()
		elif done:
			if REPLAY_RECT.has_point(pos):
				_restart()
			elif MENU_BTN_RECT.has_point(pos):
				_to_menu()
		else:
			for a in CELLS:
				if _cell_rect(a).grow(6).has_point(pos):
					cursor = a
					_fetch()
					return
	elif event.is_action_pressed("ui_cancel"):
		_to_menu()
	elif teaching():
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right"):
			_advance()
	elif done:
		if event.is_action_pressed("ui_accept"):
			_restart()
	elif event.is_action_pressed("ui_left"):
		cursor = maxi(cursor - 1, 0)
	elif event.is_action_pressed("ui_right"):
		cursor = mini(cursor + 1, CELLS - 1)
	elif event.is_action_pressed("ui_accept"):
		_fetch()


## Next teaching sentence; after the last one, play starts.
func _advance() -> void:
	if not teaching():
		return
	teach += 1
	if teaching():
		msg_key = TEACH[teach]["key"]
	else:
		msg_key = "l3_go"
	msg_args = {}


func _skip_teach() -> void:
	while teaching():
		_advance()


func _fetch() -> void:
	if done or teaching():
		return
	if cursor != pc:
		wrong_flash = 1.0
		msg_key = "l3_wrong"
		msg_args = {"got": cursor, "dec": pc}
		return
	ir = mem[pc]
	fetched += 1
	visited.append(pc)
	fetch_flash = 1.0
	if Cpu.is_halt(ir):
		done = true
		msg_key = "l3_complete"
		msg_args = {}
		return
	var next := Cpu.next_pc(pc, ir)
	if Cpu.opcode(ir) == Cpu.Op.JMP:
		msg_key = "l3_jump"
		msg_args = {"dec": next}
	else:
		msg_key = "l3_fetched"
		msg_args = {"mn": Cpu.mnemonic(ir), "mean": meaning(ir), "dec": next}
	pc = next


## Plain-language meaning of an instruction byte.
static func meaning(byte: int) -> String:
	var n := Cpu.operand(byte)
	match Cpu.opcode(byte):
		Cpu.Op.LDA:
			return Loc.text("mean_lda", {"n": n})
		Cpu.Op.LDB:
			return Loc.text("mean_ldb", {"n": n})
		Cpu.Op.ADD:
			return Loc.text("mean_add")
		Cpu.Op.JMP:
			return Loc.text("mean_jmp", {"n": n})
		Cpu.Op.HALT:
			return Loc.text("mean_halt")
	return ""


func _restart() -> void:
	pc = 0
	ir = -1
	cursor = 0
	fetched = 0
	visited = []
	done = false
	msg_key = "l3_go"
	msg_args = {}


func _to_menu() -> void:
	get_tree().change_scene_to_file(Levels.MENU)


# ---------------------------------------------------------------- drawing

func _cell_rect(a: int) -> Rect2:
	var total := CELL_W * CELLS + CELL_GAP * (CELLS - 1)
	var x0 := (1280.0 - total) / 2.0
	return Rect2(x0 + a * (CELL_W + CELL_GAP), CELL_Y, CELL_W, CELL_H)


func _memory_rect() -> Rect2:
	var first := _cell_rect(0)
	return Rect2(first.position.x, CELL_Y - 34, _cell_rect(CELLS - 1).end.x - first.position.x, CELL_H + 34)


func _focus() -> String:
	return TEACH[teach]["focus"] if teaching() else ""


func _draw() -> void:
	draw_background()
	text(Vector2(40, 72), Loc.text("level3_title"), 34, P.INK)
	button(MENU_RECT, Loc.text("menu"))
	_draw_pc()
	_draw_ir()
	_draw_pointer()
	for a in CELLS:
		_draw_cell(a)
	_draw_spotlight()
	var mem_label := Loc.text("memory")
	text(Vector2(_cell_rect(0).position.x, CELL_Y + CELL_H + 70), mem_label, 18, P.QUIET)
	if not teaching():
		var count := Loc.text("fetched_count", {"n": fetched, "total": Cpu.fetch_order(mem).size()})
		text(Vector2(_cell_rect(CELLS - 1).end.x - text_width(count, 18), CELL_Y + CELL_H + 70), count, 18, P.QUIET)
	_draw_dialogue()
	if done:
		_draw_card()


func _draw_pc() -> void:
	var r := PC_RECT
	rrect(r, P.WHITE, 20, P.BLUE, 3)
	text(Vector2(r.position.x + 20, r.position.y + 30), Loc.text("pc_label"), 17, P.BLUE)
	var value := Loc.text("pc_value", {"n": pc})
	text(Vector2(r.position.x + 20, r.position.y + 74), value, 34, P.INK)
	text(Vector2(r.position.x + 28 + text_width(value, 34), r.position.y + 74), Cpu.addr_bits(pc), 16, P.QUIET)
	text(Vector2(r.position.x + 20, r.position.y + 102), Loc.text("pc_sub"), 15, P.QUIET)


func _draw_ir() -> void:
	var r := IR_RECT
	var fill := P.WHITE if fetch_flash < 0.05 else P.YELLOW.lerp(P.WHITE, 1.0 - fetch_flash)
	rrect(r, fill, 20, P.YELLOW_DARK, 3)
	text(Vector2(r.position.x + 20, r.position.y + 30), Loc.text("ir_label"), 17, P.YELLOW_DARK)
	if ir < 0:
		text(Vector2(r.position.x + 20, r.position.y + 76), Loc.text("ir_empty"), 26, P.SHELF)
		return
	var mn := Cpu.mnemonic(ir)
	text(Vector2(r.position.x + 20, r.position.y + 76), mn, 34, P.TEAL_DARK)
	var x := r.position.x + 36 + text_width(mn, 34)
	text(Vector2(x, r.position.y + 76), Bits.bits_to_string(Bits.int_to_bits(ir)), 18, P.QUIET)
	text(Vector2(r.position.x + 20, r.position.y + 104), "= " + meaning(ir), 19, P.INK)


## Blue line from the PC box down to the cell it names, so "PC points here" is visible.
func _draw_pointer() -> void:
	if done:
		return
	var target := _cell_rect(pc)
	var start := Vector2(PC_RECT.get_center().x, PC_RECT.end.y)
	var mid_y := 246.0
	var tip := Vector2(target.get_center().x, CELL_Y - 34)
	var col := P.BLUE
	draw_polyline(PackedVector2Array([start, Vector2(start.x, mid_y), Vector2(tip.x, mid_y), tip]), col, 4.0)
	var bob := sin(time * 4.0) * 3.0
	draw_colored_polygon(PackedVector2Array([
		tip + Vector2(-11, -6 + bob), tip + Vector2(11, -6 + bob), tip + Vector2(0, 8 + bob),
	]), col)


func _draw_cell(a: int) -> void:
	var r := _cell_rect(a)
	var byte: int = mem[a]
	var is_code := Cpu.fetch_order(mem).has(a)
	var playing := not teaching() and not done
	var focused := playing and a == cursor
	var fill := P.WHITE
	if focused and wrong_flash > 0.05:
		fill = P.PINK.lerp(P.WHITE, 1.0 - wrong_flash)
	var border := P.SHELF
	var bw := 2
	if a == pc and not done:
		border = P.BLUE
		bw = 4
	if focused:
		border = P.YELLOW_DARK
		bw = 4
	rrect(r, fill, 18, border, bw)
	# Address above the cell
	var tag_col := P.BLUE if a == pc and not done else P.QUIET
	text_c(r, r.position.y - 10, Loc.text("cell_addr", {"n": a}), 18, tag_col)
	# Contents: the byte, then what it is
	var bits := Bits.bits_to_string(Bits.int_to_bits(byte))
	text_c(r, r.position.y + 46, bits, 18, P.QUIET)
	if is_code:
		text_c(r, r.position.y + 90, Cpu.mnemonic(byte), 26, P.INK)
	elif byte == 0:
		text_c(r, r.position.y + 90, Loc.text("empty"), 22, P.SHELF)
	else:
		text_c(r, r.position.y + 90, Loc.text("data_n", {"n": byte}), 22, P.QUIET)
	if visited.has(a):
		draw_circle(Vector2(r.end.x - 16, r.position.y + 16), 10, P.TEAL)
		draw_polyline(PackedVector2Array([
			Vector2(r.end.x - 21, r.position.y + 16), Vector2(r.end.x - 17, r.position.y + 20),
			Vector2(r.end.x - 11, r.position.y + 12),
		]), P.WHITE, 2.5)
	if focused:
		draw_anx(Vector2(r.get_center().x, r.end.y + 6 + sin(time * 3.0) * 2.0), 0.3)


## Pulsing yellow outline around whatever the current teaching sentence is about.
func _draw_spotlight() -> void:
	var r: Rect2
	match _focus():
		"memory":
			r = _memory_rect()
		"pc":
			r = PC_RECT
		"ir":
			r = IR_RECT
		_:
			return
	var glow := 0.5 + 0.5 * sin(time * 4.0)
	rrect(r.grow(10 + 3 * glow), Color.TRANSPARENT, 26, Color(P.YELLOW_DARK, 0.5 + 0.5 * glow), 4)


func _draw_dialogue() -> void:
	var hint := Loc.text("l3_controls_teach") if teaching() else Loc.text("l3_controls")
	text(Vector2(_cell_rect(0).position.x, 552), hint, 15, P.QUIET)
	rrect(Rect2(40, 570, 1200, 136), P.WHITE, 28)
	draw_anx(Vector2(112, 640), 0.55)
	var speaker := Loc.text("speaker")
	text(Vector2(180, 612), speaker, 20, P.TEAL_DARK)
	var width := (NEXT_BTN.position.x - 24 if teaching() else 1210.0) - 180.0
	text_wrap(Vector2(180, 646), Loc.text(msg_key, msg_args), 22, P.INK, width, 32)
	if teaching():
		var step := "%d / %d" % [teach + 1, TEACH.size()]
		text_c(NEXT_BTN, NEXT_BTN.position.y - 10, step, 14, P.QUIET)
		button(NEXT_BTN, Loc.text("continue"))


func _draw_card() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(P.INK, 0.45))
	var r := Rect2(160, 110, 960, 430)
	rrect(r, P.WHITE, 32)
	rrect(Rect2(r.position.x, r.position.y, r.size.x, 88), P.TEAL, 32)
	draw_rect(Rect2(r.position.x, r.position.y + 56, r.size.x, 32), P.TEAL)
	text_c(r, r.position.y + 56, Loc.text("card3_title"), 30, P.WHITE)
	var y := r.position.y + 150
	for key in ["card3_1", "card3_2", "card3_3"]:
		draw_circle(Vector2(r.position.x + 56, y - 7), 8, P.YELLOW)
		text(Vector2(r.position.x + 80, y), Loc.text(key), 22, P.INK)
		y += 72
	button(REPLAY_RECT, Loc.text("replay"))
	button(MENU_BTN_RECT, Loc.text("main_menu"), false)
