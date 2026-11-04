## All player-facing text, Chinese and English side by side.
## Keep both languages in sync: every key needs "zh" and "en".
extends RefCounted

const STRINGS := {
	"level_title": {"zh": "第 1 关 · 比特诞生", "en": "Level 1 · A Bit Is Born"},
	"goal": {"zh": "目标", "en": "Goal"},
	"binary": {"zh": "二进制", "en": "Binary"},
	"decimal": {"zh": "十进制", "en": "Decimal"},
	"char": {"zh": "字符", "en": "Char"},
	"weight": {"zh": "权重", "en": "Weight"},
	"speaker": {"zh": "艾尼斯", "en": "ANX"},
	"intro": {
		"zh": "我是艾尼斯，一个刚诞生的比特！8 个比特排成一排，就是一个字节。",
		"en": "I'm ANX, a newborn bit! Eight bits in a row make one byte.",
	},
	"hint": {
		"zh": "拼出字母 {letter}，它的编号是 {value}。把亮起的权重加起来试试！",
		"en": "Make the letter {letter}. Its code is {value}. Add up the lit weights!",
	},
	"controls": {
		"zh": "← → 移动，空格翻转比特；也可以直接点击开关。",
		"en": "← → to move, Space to flip a bit, or just tap a switch.",
	},
	"success": {
		"zh": "成功！{value} 就是字母 {letter}。",
		"en": "Yes! {value} is the letter {letter}.",
	},
	"complete": {
		"zh": "A、N、X，这就是我的名字！计算机里的文字，其实都是一个个数字。",
		"en": "A, N, X: that's my name! Text inside a computer is just numbers.",
	},
	"card_title": {"zh": "知识卡 · 比特与字节", "en": "Knowledge Card · Bits and Bytes"},
	"card_1": {
		"zh": "比特只有 0 和 1 两种状态，对应电路里的低电平和高电平。",
		"en": "A bit has only two states, 0 and 1: low and high voltage in a circuit.",
	},
	"card_2": {
		"zh": "8 个比特组成 1 个字节，可以表示 0 到 255 共 256 个数。",
		"en": "8 bits make 1 byte, which can hold 256 values, from 0 to 255.",
	},
	"card_3": {
		"zh": "ASCII 编码用一个字节表示一个字符，例如 65 = A。",
		"en": "ASCII uses one byte per character, for example 65 = A.",
	},
	"replay": {"zh": "再玩一次", "en": "Play again"},
}
