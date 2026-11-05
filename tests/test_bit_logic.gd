## Run: godot --headless --path . -s tests/test_bit_logic.gd
extends SceneTree

const Bits := preload("res://scripts/bit_logic.gd")
const Strings := preload("res://data/strings.gd")
const Clock := preload("res://scripts/clock_logic.gd")
const Cpu := preload("res://scripts/cpu_logic.gd")

var failures := 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)


func _init() -> void:
	print("bit_logic")
	check(Bits.weight(0) == 128 and Bits.weight(7) == 1, "weights run 128..1")
	check(Bits.bits_to_int([0, 1, 0, 0, 0, 0, 0, 1]) == 65, "01000001 = 65")
	check(Bits.bits_to_int([1, 1, 1, 1, 1, 1, 1, 1]) == 255, "11111111 = 255")
	check(Bits.int_to_bits(88) == [0, 1, 0, 1, 1, 0, 0, 0], "88 -> 01011000")
	for v in [0, 1, 65, 78, 88, 200, 255]:
		check(Bits.bits_to_int(Bits.int_to_bits(v)) == v, "round trip %d" % v)
	check(Bits.bits_to_string([0, 1, 0, 0, 0, 0, 0, 1]) == "0100 0001", "formats with a space")
	check(Bits.to_char(65) == "A" and Bits.to_char(88) == "X", "65 = A, 88 = X")
	check(Bits.to_char(7) == "·", "non-printable shows a dot")

	print("clock_logic")
	var reg := [0, 0, 0, 0, 0, 0, 0, 0]
	for b in Clock.send_order(71):  # G
		reg = Clock.shift_in(reg, b)
	check(Bits.bits_to_int(reg) == 71, "8 edges MSB first load G = 71")
	check(Clock.shift_in([1, 0, 0, 0, 0, 0, 0, 1], 1) == [0, 0, 0, 0, 0, 0, 1, 1], "shift drops the left bit")
	check(Clock.shift_in(reg, 0).size() == 8, "register stays 8 bits")
	check(Clock.is_high(0.0) and Clock.is_high(0.49) and not Clock.is_high(0.5), "high for first half of a cycle")
	check(Clock.is_high(3.2) and not Clock.is_high(-0.2), "phase wraps")

	print("cpu_logic")
	check(Cpu.fetch_order(Cpu.PROGRAM) == [0, 1, 2, 6, 7], "program runs 0,1,2 then jumps to 6 and halts at 7")
	check(Cpu.mnemonic(0x13) == "LDA 3" and Cpu.mnemonic(0x46) == "JMP 6", "mnemonics")
	check(Cpu.next_pc(15, 0x13) == 0, "PC wraps after 15")
	check(Cpu.addr_bits(6) == "0110", "4-bit address")

	print("strings")
	for key in Strings.STRINGS:
		var e: Dictionary = Strings.STRINGS[key]
		check(e.has("zh") and e.has("en") and e["zh"] != "" and e["en"] != "", "%s has zh and en" % key)

	print("font")
	var font: FontFile = load("res://assets/fonts/anx_ui.ttf")
	var missing := ""
	for key in Strings.STRINGS:
		for lang in ["zh", "en"]:
			for ch in String(Strings.STRINGS[key][lang]):
				if ch != " " and not font.has_char(ch.unicode_at(0)) and not ch in missing:
					missing += ch
	check(missing == "", "bundled font covers all text (missing: '%s'; run tools/subset_font.py)" % missing)

	print("%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
