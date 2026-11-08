## Localization autoload. The player picks Chinese or English in the main menu;
## the choice is saved to user://settings.cfg.
extends Node

signal changed

enum Mode { ZH, EN }

const Strings := preload("res://data/strings.gd")
const SETTINGS_PATH := "user://settings.cfg"

var mode: Mode = Mode.ZH
## Keys asked for that have no text yet; the playtest bot reports them.
var missing := {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		mode = cfg.get_value("ui", "language", Mode.ZH) as Mode
	else:
		mode = Mode.ZH if OS.get_locale_language() == "zh" else Mode.EN


## Text for a key in the chosen language, with {placeholders} filled from args.
func text(key: String, args: Dictionary = {}) -> String:
	if not Strings.STRINGS.has(key):
		missing[key] = true
	var entry: Dictionary = Strings.STRINGS.get(key, {"zh": key, "en": key})
	return String(entry["zh" if mode == Mode.ZH else "en"]).format(args)


func set_mode(m: Mode) -> void:
	if m == mode:
		return
	mode = m
	var cfg := ConfigFile.new()
	cfg.set_value("ui", "language", mode)
	cfg.save(SETTINGS_PATH)
	changed.emit()
