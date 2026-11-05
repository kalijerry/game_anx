## A toy 8-bit CPU for Levels 3+. Each instruction is one byte: high 4 bits opcode, low 4 bits operand.
## Unit tested.
extends RefCounted

enum Op { DATA = 0, LDA = 1, LDB = 2, ADD = 3, JMP = 4, HALT = 15 }

## Level 3 program. Addresses 3-5 hold data that the JMP at address 2 skips over.
const PROGRAM := [
	0x13,  # 0: LDA 3
	0x25,  # 1: LDB 5
	0x46,  # 2: JMP 6
	0x00,  # 3: data
	0x41,  # 4: data ('A')
	0x4E,  # 5: data ('N')
	0x30,  # 6: ADD
	0xF0,  # 7: HALT
	0, 0, 0, 0, 0, 0, 0, 0,
]


static func opcode(byte: int) -> int:
	return (byte >> 4) & 0xF


static func operand(byte: int) -> int:
	return byte & 0xF


## Assembly text for a byte at an address the program treats as code.
static func mnemonic(byte: int) -> String:
	match opcode(byte):
		Op.LDA:
			return "LDA %d" % operand(byte)
		Op.LDB:
			return "LDB %d" % operand(byte)
		Op.ADD:
			return "ADD"
		Op.JMP:
			return "JMP %d" % operand(byte)
		Op.HALT:
			return "HALT"
	return ""


## Address of the next instruction after fetching `byte` from `pc`.
static func next_pc(pc: int, byte: int) -> int:
	if opcode(byte) == Op.JMP:
		return operand(byte)
	return (pc + 1) % 16


static func is_halt(byte: int) -> bool:
	return opcode(byte) == Op.HALT


## Addresses fetched from 0 until HALT, inclusive.
static func fetch_order(program: Array) -> Array:
	var order := []
	var pc := 0
	for _i in 64:
		order.append(pc)
		if is_halt(program[pc]):
			break
		pc = next_pc(pc, program[pc])
	return order


static func addr_bits(addr: int) -> String:
	var s := ""
	for i in 4:
		s += str((addr >> (3 - i)) & 1)
	return s
