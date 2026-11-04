## Pure helpers for the clock and shift register in Level 2. Unit tested.
extends RefCounted


## Shifts the register one place left and puts the new bit at the right end.
## Sending bits MSB first leaves the byte in reading order after 8 edges.
static func shift_in(reg: Array, bit: int) -> Array:
	var out := reg.slice(1)
	out.append(1 if bit else 0)
	return out


## Clock level at a phase measured in cycles: high for the first half of each cycle.
## A rising edge happens at every whole number of cycles.
static func is_high(phase: float) -> bool:
	return fposmod(phase, 1.0) < 0.5


## Bits that must be sent, in order, to load a value into an 8-bit register.
static func send_order(value: int) -> Array:
	var bits := []
	for i in 8:
		bits.append((value >> (7 - i)) & 1)
	return bits
