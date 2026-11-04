## Pure helpers for bits and bytes. No scene dependencies, so they are unit tested.
extends RefCounted

const BYTE_SIZE := 8


## Weight of the bit at index i, where index 0 is the most significant bit.
static func weight(i: int) -> int:
	return 1 << (BYTE_SIZE - 1 - i)


## Converts an MSB-first array of 0/1 into an integer.
static func bits_to_int(bits: Array) -> int:
	var value := 0
	for b in bits:
		value = (value << 1) | (1 if b else 0)
	return value


## Converts an integer (0-255) into an MSB-first array of 0/1.
static func int_to_bits(value: int) -> Array:
	var bits := []
	for i in BYTE_SIZE:
		bits.append((value >> (BYTE_SIZE - 1 - i)) & 1)
	return bits


## Formats bits as "0100 0001".
static func bits_to_string(bits: Array) -> String:
	var s := ""
	for i in bits.size():
		if i == 4:
			s += " "
		s += str(bits[i])
	return s


## Printable ASCII character for a value, or a middle dot when not printable.
static func to_char(value: int) -> String:
	if value >= 32 and value < 127:
		return String.chr(value)
	return "·"
