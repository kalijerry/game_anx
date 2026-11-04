## Run: godot --headless --path . -s tests/test_bit_logic.gd
extends SceneTree

const Bits := preload("res://scripts/bit_logic.gd")
const Strings := preload("res://data/strings.gd")

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

	print("strings")
	for key in Strings.STRINGS:
		var e: Dictionary = Strings.STRINGS[key]
		check(e.has("zh") and e.has("en") and e["zh"] != "" and e["en"] != "", "%s has zh and en" % key)

	print("%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
