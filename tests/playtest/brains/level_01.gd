## Bot brain for Level 1: reads the goal letter, opens the ASCII table once like a curious
## beginner, then walks to each wrong switch with the arrow keys and flips it with Space.
extends RefCounted

const Bits := preload("res://scripts/bit_logic.gd")

var looked_at_table := false


func act(bot, lvl) -> void:
	if lvl.busy:
		return  # ANX is celebrating; wait like a player would
	if lvl.table_open:
		bot.click_label(Loc.text("close"))
		return
	if not looked_at_table:
		looked_at_table = true
		bot.click_label(Loc.text("ascii_button"))
		return
	var want: Array = Bits.int_to_bits(String(lvl.TARGETS[lvl.stage]).unicode_at(0))
	for i in want.size():
		if int(lvl.bits[i]) != int(want[i]):
			if lvl.cursor < i:
				bot.key(KEY_RIGHT)
			elif lvl.cursor > i:
				bot.key(KEY_LEFT)
			else:
				bot.key(KEY_SPACE)
			return


## Leaves the finished level the way a player would: the "next level" button on the card.
func leave(bot, _lvl) -> void:
	bot.click_label(Loc.text("next_level"))
