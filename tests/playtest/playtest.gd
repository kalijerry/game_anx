## AI playtest: a bot plays the whole game like a player (only key presses and clicks), in
## each language, from the main menu through every level, then hammers each level with random
## input and checks it can still be finished. It writes a report for people and for AI agents.
##
## Run through tools/playtest.sh (it adds --fixed-fps 60 and checks the log for script errors):
##   tools/playtest.sh              # headless, fast; what CI runs
##   tools/playtest.sh --shots      # real renderer under xvfb, saves screenshots too
## Options after "--": --lang=zh|en (default both), --no-monkey, --out=DIR (default build/playtest)
extends SceneTree

const Levels := preload("res://scripts/levels.gd")

## Each level needs a brain at tests/playtest/brains/<scene name>.gd with act(bot, level) and
## leave(bot, level). A level without one fails the playtest, so every new level gets a bot.
## (Loaded at run time: brains use the Loc autoload, which a -s script cannot see while compiling.)
const BRAIN_DIR := "res://tests/playtest/brains/"
const FPS := 60
## A short pause between actions, roughly how fast a person clicks.
const ACTION_GAP := 12
## Per level limits: past these the bot reports the level as stuck.
const MAX_ACTIONS := 400
const MAX_SECONDS := 300.0
const STUCK_ACTIONS := 60
const MONKEY_ACTIONS := 300
## Beginner readability: messages longer than this get a warning (characters).
const LONG_MSG := {"zh": 70, "en": 170}
## Text must stay this far inside the 1280 x 720 screen.
const SCREEN := Rect2(0, 0, 1280, 720)
const MARGIN := 24.0
## Monkey clicks avoid the Menu button and the console's tap corner, which only leave the level.
const MONKEY_NO_CLICK := [Rect2(1090, 26, 160, 68), Rect2(0, 0, 100, 100)]
const MONKEY_KEYS := [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE, KEY_ENTER, KEY_TAB, KEY_A, KEY_1]

var out_dir := "build/playtest"
var langs: Array = ["zh", "en"]
var monkey := true
var shots := false
var frame := 0
var shot_n := 0
var actions := 0
var runs: Array = []
var issues: Array = []
var issue_seen := {}
var lang := "zh"
var level_name := ""
## The Loc autoload, fetched at run time (see BRAIN_DIR).
var Loc: Node


func _initialize() -> void:
	Loc = root.get_node("Loc")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			langs = [a.trim_prefix("--lang=")]
		elif a == "--no-monkey":
			monkey = false
		elif a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	shots = DisplayServer.get_name() != "headless"
	if not out_dir.is_absolute_path():
		out_dir = ProjectSettings.globalize_path("res://").path_join(out_dir)
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("shots"))
	load("res://scripts/flat_canvas.gd").probe_on = true
	await _main()
	_write_report()
	var errors := issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "error").size()
	print("playtest: %d error(s), %d warning(s). Report: %s" % [
		errors, issues.size() - errors, out_dir.path_join("report.md")])
	quit(1 if errors > 0 else 0)


func _main() -> void:
	for l in langs:
		lang = l
		await _play_through()
	if monkey:
		lang = langs[0]
		Loc.set_mode(Loc.Mode.ZH if lang == "zh" else Loc.Mode.EN)
		for i in Levels.LEVELS.size():
			await _monkey(i)


# ---------------------------------------------------------------- full playthrough

## Main menu -> pick language -> Start -> every level in order, moving on with the level's own
## "next" button. If a level fails, the bot jumps to the next one so later levels are still tested.
func _play_through() -> void:
	change_scene_to_file(Levels.MENU)
	await _wait_for_scene(Levels.MENU)
	level_name = "menu"
	await shot("menu")
	click_label("中文" if lang == "zh" else "English")
	await frames(ACTION_GAP)
	_audit_screen()
	click_label(Loc.text("start"))
	for i in Levels.LEVELS.size():
		var scene: String = Levels.LEVELS[i]["scene"]
		if not await _wait_for_scene(scene):
			_issue("error", "flow", "Did not reach %s from the previous screen; jumping there directly." % scene)
			change_scene_to_file(scene)
			await _wait_for_scene(scene)
		var run := await _play_level(i, "play")
		runs.append(run)
		if run["result"] != "pass":
			continue
		var brain = run["brain"]
		brain.leave(self, current_scene)
		await frames(ACTION_GAP)
	for r in runs:
		r.erase("brain")


## Plays the current scene, which must be level i, until it is done or the bot gets stuck.
func _play_level(i: int, mode: String) -> Dictionary:
	var lvl: Node = current_scene
	level_name = "L%d" % (i + 1)
	var scene: String = Levels.LEVELS[i]["scene"]
	var run := {
		"level": level_name, "title": Loc.text(Levels.LEVELS[i]["title"]), "lang": lang, "mode": mode,
		"result": "pass", "actions": 0, "seconds": 0.0, "wrong": 0, "messages": [], "read_chars": 0,
	}
	var brain_path := BRAIN_DIR + scene.get_file().get_basename() + ".gd"
	if not ResourceLoader.exists(brain_path):
		run["result"] = "no_brain"
		_issue("error", "bot", "No bot brain for this level: add %s" % brain_path)
		return run
	var brain = load(brain_path).new()
	run["brain"] = brain
	var start_frame := frame
	var start_actions := actions
	var last_msg := ""
	var last_screen := ""
	var same_screen := 0
	await shot("start")
	while not lvl.done:
		var msg: String = Loc.text(lvl.msg_key, lvl.msg_args)
		if msg != last_msg:
			last_msg = msg
			run["messages"].append(msg)
			run["read_chars"] += msg.length()
			if "wrong" in String(lvl.msg_key):
				run["wrong"] += 1
			if msg.length() > LONG_MSG[lang]:
				_issue("warning", "long_message", "%d characters: %s" % [msg.length(), msg])
			await shot(lvl.msg_key)
		_audit_screen()
		var screen := _screen_text(lvl)
		same_screen = 0 if screen != last_screen else same_screen + 1
		last_screen = screen
		var used := actions - start_actions
		var secs := float(frame - start_frame) / FPS
		if same_screen >= STUCK_ACTIONS or used >= MAX_ACTIONS or secs >= MAX_SECONDS:
			run["result"] = "stuck"
			_issue("error", "stuck", "Bot stuck after %d actions, %.0f s. Last message: %s" % [used, secs, msg])
			await shot("stuck")
			break
		brain.act(self, lvl)
		await frames(ACTION_GAP)
		if not is_instance_valid(lvl) or current_scene != lvl:
			run["result"] = "left_level"
			_issue("error", "flow", "The level closed before it was finished.")
			break
	if run["result"] == "pass":
		var msg: String = Loc.text(lvl.msg_key, lvl.msg_args)
		run["messages"].append(msg)
		run["read_chars"] += msg.length()
		await frames(2)
		_audit_screen()
		await shot("done")
	run["actions"] = actions - start_actions
	run["seconds"] = snappedf(float(frame - start_frame) / FPS, 0.1)
	return run


# ---------------------------------------------------------------- monkey

## Random taps and keys, then the brain must still be able to finish: no crash, no dead end.
func _monkey(i: int) -> void:
	var scene: String = Levels.LEVELS[i]["scene"]
	change_scene_to_file(scene)
	await _wait_for_scene(scene)
	level_name = "L%d" % (i + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + i
	var left := 0
	for n in MONKEY_ACTIONS:
		if current_scene == null or current_scene.scene_file_path != scene:
			left += 1
			change_scene_to_file(scene)
			await _wait_for_scene(scene)
		if rng.randf() < 0.5:
			key(MONKEY_KEYS[rng.randi() % MONKEY_KEYS.size()])
		else:
			var p := Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720))
			if MONKEY_NO_CLICK.any(func(r: Rect2) -> bool: return r.has_point(p)):
				continue
			click(p)
		await frames(3)
	if current_scene == null or current_scene.scene_file_path != scene:
		change_scene_to_file(scene)
		await _wait_for_scene(scene)
	var run := await _play_level(i, "monkey")
	run.erase("brain")
	run["note"] = "%d random actions first (seed %d), level left %d time(s)" % [MONKEY_ACTIONS, 1234 + i, left]
	runs.append(run)


# ---------------------------------------------------------------- what the bot can do

func frames(n: int) -> void:
	for _i in n:
		await process_frame
		frame += 1


func key(code: Key) -> void:
	actions += 1
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		root.push_input(ev, true)


func click(pos: Vector2) -> void:
	actions += 1
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = pressed
		root.push_input(ev, true)


## Clicks the button (or label) showing this text, as a player would. Reports it if no such
## text is on screen, which usually means a missing or renamed button.
func click_label(label: String) -> bool:
	var found: Dictionary = {}
	for item in _seen():
		if item["text"] == label and (found.is_empty() or item["kind"] == "button"):
			found = item
	if found.is_empty():
		_issue("error", "bot", "Could not find \"%s\" on screen." % label)
		return false
	click(Rect2(found["rect"]).get_center())
	return true


func _seen() -> Array:
	var s = current_scene
	return s.ui_seen if s != null and "ui_seen" in s else []


func _screen_text(lvl: Node) -> String:
	return "|".join(_seen().map(func(it: Dictionary) -> String: return it["text"])) + str(lvl.get("msg_key"))


func _wait_for_scene(scene: String) -> bool:
	for _i in 120:
		await frames(1)
		if current_scene != null and current_scene.scene_file_path == scene:
			await frames(2)
			return true
	return false


# ---------------------------------------------------------------- checks and report

## Looks at every label on the last frame: off screen, spilling out of its button or box, or a
## raw string key (missing translation).
func _audit_screen() -> void:
	for item in _seen():
		var r: Rect2 = item["rect"]
		var s: String = item["text"]
		if s.strip_edges() == "":
			continue
		if not SCREEN.grow(-MARGIN).encloses(r) and r.size.x > 0:
			_issue("error", "offscreen", "Runs past the screen edge (x %d..%d, y %d): %s" % [r.position.x, r.end.x, r.end.y, s])
		var box: Rect2 = item["box"]
		if box.size.x > 0 and r.size.x > box.size.x - 8:
			_issue("error", "overflow", "Wider than its box (%d > %d px): %s" % [r.size.x, box.size.x, s])
	for k in Loc.missing:
		_issue("error", "missing_text", "No text for key \"%s\" in data/strings.gd" % k)
	Loc.missing.clear()


func _issue(severity: String, kind: String, detail: String) -> void:
	var id := "%s|%s|%s|%s" % [lang, level_name, kind, detail]
	if issue_seen.has(id):
		return
	issue_seen[id] = true
	issues.append({"severity": severity, "kind": kind, "lang": lang, "level": level_name, "detail": detail})
	(printerr if severity == "error" else print).call("  %s [%s %s] %s: %s" % [severity.to_upper(), lang, level_name, kind, detail])


func shot(tag: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	shot_n += 1
	var img := root.get_texture().get_image()
	var file := "%s/shots/%s_%s_%02d_%s.png" % [out_dir, lang, level_name, shot_n, tag.validate_filename()]
	img.save_png(file)


func _write_report() -> void:
	var errors := issues.filter(func(i: Dictionary) -> bool: return i["severity"] == "error")
	var md := PackedStringArray()
	md.append("# AI playtest report")
	md.append("")
	md.append("**%s**: %d error(s), %d warning(s). Bot plays at %d fps game time; seconds below are game time." % [
		"PASS" if errors.is_empty() else "FAIL", errors.size(), issues.size() - errors.size(), FPS])
	md.append("")
	md.append("| Lang | Level | Mode | Result | Actions | Seconds | Wrong moves | Messages | Chars to read |")
	md.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for r in runs:
		md.append("| %s | %s %s | %s | %s | %d | %.1f | %d | %d | %d |" % [
			r["lang"], r["level"], r["title"], r["mode"], "✅" if r["result"] == "pass" else "❌ " + r["result"],
			r["actions"], r["seconds"], r["wrong"], r["messages"].size(), r["read_chars"]])
	md.append("")
	md.append("## Issues")
	md.append("")
	if issues.is_empty():
		md.append("None.")
	for i in issues:
		md.append("- **%s** `%s` %s %s: %s" % [i["severity"], i["kind"], i["lang"], i["level"], i["detail"]])
	md.append("")
	md.append("## What the player reads, in order")
	for r in runs:
		if r["mode"] != "play":
			continue
		md.append("")
		md.append("### %s %s (%s)" % [r["level"], r["title"], r["lang"]])
		md.append("")
		for m in r["messages"]:
			md.append("1. " + m)
	var f := FileAccess.open(out_dir.path_join("report.md"), FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	f = FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"runs": runs, "issues": issues}, "  "))
