## Localization autoload. Shows Chinese, English, or both at once.
extends Node

signal changed

enum Mode { BOTH, ZH, EN }

const Strings := preload("res://data/strings.gd")

var mode: Mode = Mode.BOTH


## Returns the lines to display for a key in the current mode (1 or 2 lines).
func lines(key: String, args: Dictionary = {}) -> Array:
	var entry: Dictionary = Strings.STRINGS.get(key, {"zh": key, "en": key})
	var zh: String = String(entry["zh"]).format(args)
	var en: String = String(entry["en"]).format(args)
	match mode:
		Mode.ZH:
			return [zh]
		Mode.EN:
			return [en]
		_:
			return [zh, en]


## Returns a single line: "中文 English" in BOTH mode.
func short(key: String, args: Dictionary = {}) -> String:
	return " ".join(lines(key, args))


func cycle() -> void:
	mode = ((mode + 1) % 3) as Mode
	changed.emit()
