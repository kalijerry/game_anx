## Bot brain for Level 3: reads every teaching sentence by pressing the Continue button, then
## follows the blue PC arrow: clicks the cell the PC points at until HALT.
extends RefCounted


func act(bot, lvl) -> void:
	if lvl.teaching():
		bot.click_label(Loc.text("continue"))
		return
	bot.click(lvl._cell_rect(lvl.pc).get_center())


## Last level so far: the card offers Replay and Main menu, so go back to the menu.
func leave(bot, _lvl) -> void:
	bot.click_label(Loc.text("main_menu"))
