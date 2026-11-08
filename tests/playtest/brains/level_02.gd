## Bot brain for Level 2: watches the register and sets input D to the next bit the goal letter
## needs before each rising edge, using clicks on the D box (and Space for the second letter).
extends RefCounted

const Bits := preload("res://scripts/bit_logic.gd")


func act(bot, lvl) -> void:
	if lvl.busy:
		return
	var want: Array = Bits.int_to_bits(String(lvl.TARGETS[lvl.stage]).unicode_at(0))
	# Longest prefix of the goal already sitting at the right end of the register.
	var k := 8
	while k > 0 and lvl.reg.slice(8 - k) != want.slice(0, k):
		k -= 1
	if k >= 8:
		return
	if int(lvl.d) != int(want[k]):
		if lvl.stage == 0:
			bot.click(lvl.D_RECT.get_center())
		else:
			bot.key(KEY_SPACE)


func leave(bot, _lvl) -> void:
	bot.click_label(Loc.text("next_level"))
