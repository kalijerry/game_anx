## Registry of scenes, shared by the menu, the levels and the developer console.
extends RefCounted

const MENU := "res://scenes/main_menu.tscn"

## Each level: its scene and the string key of its title.
const LEVELS := [
	{"scene": "res://scenes/level_01.tscn", "title": "level_title"},
	{"scene": "res://scenes/level_02.tscn", "title": "level2_title"},
]
