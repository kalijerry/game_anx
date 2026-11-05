## Level 3 · Fetch
## Memory holds a tiny program. The PC names the address of the next instruction; ANX goes to
## that shelf and fetches the byte into IR. PC then goes up by 1, except after JMP, which
## rewrites it. Fetch until HALT.
extends "res://scripts/flat_canvas.gd"

const Bits := preload("res://scripts/bit_logic.gd")
const Cpu := preload("res://scripts/cpu_logic.gd")
const Levels := preload("res://scripts/levels.gd")

const MENU_RECT := Rect2(1100, 36, 140, 48)
const GRID_X := 88.0
const GRID_Y := 250.0
const CELL_W := 128.0
const CELL_H := 104.0
const CELL_GAP := 10.0
const REPLAY_RECT := Rect2(400, 462, 220, 56)
const MENU_BTN_RECT := Rect2(660, 462, 220, 56)

var mem: Array = Cpu.PROGRAM.duplicate()
var pc := 0
var ir := -1
var cursor := 0
var fetched := 0
var done := false
var wrong_flash := 0.0
var fetch_flash := 0.0
var msg_key := "l3_intro"
var msg_args := {}


func _ready() -> void:
	if "--demo=complete" in OS.get_cmdline_user_args():
		done = true
		ir = 0xF0
		pc = 7
		fetched = Cpu.fetch_order(mem).size()
		msg_key = "l3_complete"
	elif "--demo=jump" in OS.get_cmdline_user_args():
		for a in [0, 1, 2]:
			cursor = a
			_fetch()


func _process(delta: float) -> void:
	super(delta)
	wrong_flash = maxf(0.0, wrong_flash - delta * 2.5)
	fetch_flash = maxf(0.0, fetch_flash - delta * 2.5)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = make_input_local(event).position
		if MENU_RECT.has_point(pos):
			_to_menu()
			return
		if done:
			if REPLAY_RECT.has_point(pos):
				_restart()
			elif MENU_BTN_RECT.has_point(pos):
				_to_menu()
			return
		for a in 16:
			if _cell_rect(a).has_point(pos):
				cursor = a
				_fetch()
				return
	elif event.is_action_pressed("ui_cancel"):
		_to_menu()
	elif done:
		if event.is_action_pressed("ui_accept"):
			_restart()
	elif event.is_action_pressed("ui_left"):
		cursor = (cursor + 15) % 16
	elif event.is_action_pressed("ui_right"):
		cursor = (cursor + 1) % 16
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		cursor = (cursor + 8) % 16
	elif event.is_action_pressed("ui_accept"):
		_fetch()


func _fetch() -> void:
	if done:
		return
	if cursor != pc:
		wrong_flash = 1.0
		msg_key = "l3_wrong"
		msg_args = {"addr": Cpu.addr_bits(pc), "dec": pc}
		return
	ir = mem[pc]
	fetched += 1
	fetch_flash = 1.0
	if Cpu.is_halt(ir):
		done = true
		msg_key = "l3_complete"
		msg_args = {}
		return
	var next := Cpu.next_pc(pc, ir)
	if Cpu.opcode(ir) == Cpu.Op.JMP:
		msg_key = "l3_jump"
		msg_args = {"addr": Cpu.addr_bits(next), "dec": next}
	else:
		msg_key = "l3_fetched"
		msg_args = {"mn": Cpu.mnemonic(ir), "addr": Cpu.addr_bits(next), "dec": next}
	pc = next


func _restart() -> void:
	pc = 0
	ir = -1
	cursor = 0
	fetched = 0
	done = false
	msg_key = "l3_intro"
	msg_args = {}


func _to_menu() -> void:
	get_tree().change_scene_to_file(Levels.MENU)


# ---------------------------------------------------------------- drawing

func _cell_rect(a: int) -> Rect2:
	return Rect2(GRID_X + (a % 8) * (CELL_W + CELL_GAP), GRID_Y + (a / 8) * (CELL_H + 22), CELL_W, CELL_H)


func _draw() -> void:
	draw_background()
	text(Vector2(40, 72), Loc.text("level3_title"), 34, P.INK)
	button(MENU_RECT, Loc.text("menu"))
	_draw_registers()
	text(Vector2(GRID_X, GRID_Y - 30), Loc.text("memory"), 18, P.QUIET)
	for a in 16:
		_draw_cell(a)
	_draw_dialogue()
	if done:
		_draw_card()


func _draw_registers() -> void:
	# PC
	var pr := Rect2(88, 112, 300, 84)
	rrect(pr, P.WHITE, 20, P.BLUE, 3)
	text(Vector2(pr.position.x + 20, pr.position.y + 30), Loc.text("pc_label"), 16, P.QUIET)
	text(Vector2(pr.position.x + 20, pr.position.y + 68), "%s  (%d)" % [Cpu.addr_bits(pc), pc], 30, P.INK)
	# IR
	var irr := Rect2(412, 112, 420, 84)
	rrect(irr, P.WHITE if fetch_flash < 0.05 else P.YELLOW.lerp(P.WHITE, 1.0 - fetch_flash), 20, P.YELLOW_DARK, 3)
	text(Vector2(irr.position.x + 20, irr.position.y + 30), Loc.text("ir_label"), 16, P.QUIET)
	if ir >= 0:
		var bits := Bits.bits_to_string(Bits.int_to_bits(ir))
		text(Vector2(irr.position.x + 20, irr.position.y + 68), bits, 30, P.INK)
		text(Vector2(irr.position.x + 200, irr.position.y + 68), Cpu.mnemonic(ir), 30, P.TEAL_DARK)
	else:
		text(Vector2(irr.position.x + 20, irr.position.y + 68), "—", 30, P.SHELF)
	# Progress
	var total := Cpu.fetch_order(mem).size()
	var label := Loc.text("fetched_count", {"n": fetched, "total": total})
	text(Vector2(860, 166), label, 20, P.QUIET)


func _draw_cell(a: int) -> void:
	var r := _cell_rect(a)
	var byte: int = mem[a]
	var is_code := Cpu.fetch_order(mem).has(a)
	var mn := Cpu.mnemonic(byte) if is_code else ""
	var focused := a == cursor and not done
	var fill := P.WHITE
	if focused and wrong_flash > 0.05:
		fill = P.PINK.lerp(P.WHITE, 1.0 - wrong_flash)
	var border := P.YELLOW_DARK if focused else (P.BLUE if a == pc and not done else P.SHELF)
	rrect(r, fill, 16, border, 4 if focused else 2)
	# Address tag above the shelf
	var tag_col := P.BLUE if a == pc and not done else P.QUIET
	text(Vector2(r.position.x + 4, r.position.y - 4), "%s · %d" % [Cpu.addr_bits(a), a], 14, tag_col)
	# Contents
	if byte == 0 and not is_code:
		text_c(r, r.position.y + 58, "—", 26, P.SHELF)
	else:
		text_c(r, r.position.y + 44, mn if mn != "" else Loc.text("data"), 22, P.INK if mn != "" else P.QUIET)
		text_c(r, r.position.y + 82, Bits.bits_to_string(Bits.int_to_bits(byte)), 15, P.QUIET)
	if focused:
		draw_anx(Vector2(r.end.x - 18, r.position.y + 10 + sin(time * 3.0) * 2.0), 0.28)


func _draw_dialogue() -> void:
	text(Vector2(GRID_X, 540), Loc.text("l3_controls"), 15, P.QUIET)
	rrect(Rect2(40, 570, 1200, 124), P.WHITE, 28)
	draw_anx(Vector2(112, 640), 0.55)
	var speaker := Loc.text("speaker") + ("：" if Loc.mode == Loc.Mode.ZH else ": ")
	text(Vector2(180, 642), speaker, 24, P.TEAL_DARK)
	text(Vector2(180 + text_width(speaker, 24), 642), Loc.text(msg_key, msg_args), 22, P.INK)


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
