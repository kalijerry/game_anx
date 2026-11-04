## Plays Level 2 headlessly: sends G bit by bit on rising edges and checks the level accepts it.
## Run: godot --headless --path . -s tests/test_level_02.gd
extends SceneTree

const Clock := preload("res://scripts/clock_logic.gd")

var failures := 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)


func _initialize() -> void:
	print("level_02 playthrough")
	var lvl: Node = load("res://scenes/level_02.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	var period: float = lvl.PERIODS[0]
	# Wrong bits first: they must shift out without breaking anything.
	for i in 3:
		lvl.d = 1
		lvl._process(period)
	for b in Clock.send_order("G".unicode_at(0)):
		lvl.d = b
		lvl._process(period)
	check(lvl.reg == [0, 1, 0, 0, 0, 1, 1, 1], "register holds G after 8 edges")
	check(lvl.busy and lvl.msg_key == "l2_success", "level reports success for G")
	var edges_before: int = lvl.edges
	lvl._process(period)
	check(lvl.edges == edges_before, "clock pauses during the success message")
	lvl.free()
	print("%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
