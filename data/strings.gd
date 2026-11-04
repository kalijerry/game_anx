## All player-facing text, Chinese and English side by side.
## Keep both languages in sync: every key needs "zh" and "en".
extends RefCounted

const STRINGS := {
	"game_title": {"zh": "艾尼斯：计算机里的世界", "en": "ANX: Inside the Computer"},
	"menu_subtitle": {
		"zh": "从一个比特出发，看懂真正的计算机",
		"en": "Start as a single bit and learn how computers really work",
	},
	"start": {"zh": "开始游戏", "en": "Start"},
	"menu_hint": {"zh": "← → 切换语言，回车开始", "en": "← → to switch language, Enter to start"},
	"menu": {"zh": "菜单", "en": "Menu"},
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
		"zh": "拼出字母 {letter}！查查 ASCII 表，它的编号是 {value}。",
		"en": "Make the letter {letter}! The ASCII table says its code is {value}.",
	},
	"controls": {
		"zh": "← → 移动，空格翻转比特，Tab 打开 ASCII 表；也可以直接点击。",
		"en": "← → to move, Space to flip a bit, Tab for the ASCII table, or just tap.",
	},
	"ascii_button": {"zh": "ASCII 表", "en": "ASCII"},
	"ascii_title": {"zh": "ASCII 表 · 大写字母", "en": "ASCII Table · Capital Letters"},
	"ascii_note": {
		"zh": "大写字母从 65（A）开始，每往后一个字母编号加 1。黄色是目标，青色是你现在拼出的字母。",
		"en": "Capitals start at 65 (A) and go up by 1 per letter. Yellow is your goal, teal is what you have now.",
	},
	"close": {"zh": "关闭", "en": "Close"},
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
