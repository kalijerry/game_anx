## Plays Level 3 headlessly: a wrong fetch is refused, then following the PC reaches HALT.
## Run: godot --headless --path . -s tests/test_level_03.gd
extends SceneTree

const Cpu := preload("res://scripts/cpu_logic.gd")

var failures := 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)


func _initialize() -> void:
	print("level_03 playthrough")
	var lvl: Node = load("res://scenes/level_03.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	lvl.cursor = 5
	lvl._fetch()
	check(lvl.pc == 0 and lvl.ir == -1 and lvl.msg_key == "l3_wrong", "fetching the wrong address is refused")
	for addr in [0, 1, 2]:
		lvl.cursor = addr
		lvl._fetch()
	check(lvl.pc == 6 and lvl.msg_key == "l3_jump", "JMP 6 rewrites the PC")
	for addr in [6, 7]:
		lvl.cursor = addr
		lvl._fetch()
	check(lvl.done and lvl.ir == 0xF0 and lvl.fetched == 5, "HALT ends the level after 5 fetches")
	lvl.free()
	print("%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
