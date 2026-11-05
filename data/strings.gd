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
	"next_level": {"zh": "下一关", "en": "Next level"},
	"main_menu": {"zh": "主菜单", "en": "Main menu"},
	"level_1_short": {"zh": "第 1 关", "en": "Level 1"},
	"level_2_short": {"zh": "第 2 关", "en": "Level 2"},
	# ------------------------------------------------------------ Level 3
	"level3_title": {"zh": "第 3 关 · 取指", "en": "Level 3 · Fetch"},
	"memory": {"zh": "内存：16 个格子，每格 1 字节，上方是地址", "en": "Memory: 16 cells of 1 byte, address on top"},
	"pc_label": {"zh": "PC 程序计数器：下一条指令的地址", "en": "PC (program counter): next address"},
	"ir_label": {"zh": "IR 指令寄存器：刚取到的指令", "en": "IR (instruction register): fetched"},
	"fetched_count": {"zh": "已取指 {n} / {total}", "en": "Fetched {n} / {total}"},
	"data": {"zh": "数据", "en": "data"},
	"l3_intro": {
		"zh": "我是取指员！看 PC 里的地址，去那个格子把指令取回 IR。",
		"en": "I'm the fetcher! Read the address in PC, then fetch that cell into IR.",
	},
	"l3_fetched": {
		"zh": "取到 {mn}！PC 加 1，下一条在地址 {addr}（{dec}）。",
		"en": "Got {mn}! PC goes up by 1: next is address {addr} ({dec}).",
	},
	"l3_jump": {
		"zh": "是 JMP 跳转！PC 被直接改成 {addr}（{dec}），中间的数据跳过不执行。",
		"en": "A JMP! PC is set straight to {addr} ({dec}), skipping the data in between.",
	},
	"l3_wrong": {
		"zh": "不是这个格子。PC 里写的是 {addr}，也就是地址 {dec}。",
		"en": "Not this cell. PC says {addr}, which is address {dec}.",
	},
	"l3_complete": {
		"zh": "取到 HALT，程序结束！下一关我们来真正执行这些指令。",
		"en": "HALT fetched, the program ends! Next level we really execute them.",
	},
	"l3_controls": {
		"zh": "方向键移动，空格取指；也可以直接点击格子。",
		"en": "Arrow keys to move, Space to fetch, or just tap a cell.",
	},
	"card3_title": {"zh": "知识卡 · 程序计数器与取指", "en": "Knowledge Card · Program Counter and Fetch"},
	"card3_1": {
		"zh": "程序和数据都以数字存在内存里，每个格子都有自己的地址。",
		"en": "Programs and data both live in memory as numbers; every cell has an address.",
	},
	"card3_2": {
		"zh": "PC 记着下一条指令的地址，每取一条通常就加 1。",
		"en": "The PC holds the next instruction's address and usually adds 1 after each fetch.",
	},
	"card3_3": {
		"zh": "跳转指令直接改写 PC，所以程序可以跳过或重复某些指令。",
		"en": "Jumps rewrite the PC, so programs can skip or repeat instructions.",
	},
	# ------------------------------------------------------------ Developer console
	"console_help": {
		"zh": "命令：test 选关 · menu 主菜单 · lang zh / lang en 切换语言 · help 帮助。按 ` 或 Esc 关闭。",
		"en": "Commands: test (level select) · menu · lang zh / lang en · help. Press ` or Esc to close.",
	},
	"console_unknown": {"zh": "未知命令：{cmd}。输入 help 查看命令。", "en": "Unknown command: {cmd}. Type help."},
	"level_select": {"zh": "选关：点击要进入的关卡", "en": "Level select: pick a level"},
	# ------------------------------------------------------------ Level 2
	"level2_title": {"zh": "第 2 关 · 时钟节拍", "en": "Level 2 · The Clock Ticks"},
	"clock": {"zh": "时钟 CLK", "en": "Clock CLK"},
	"rising_edge": {"zh": "上升沿", "en": "Rising edge"},
	"input_d": {"zh": "输入 D", "en": "Input D"},
	"register": {"zh": "寄存器：8 个触发器", "en": "Register: 8 flip-flops"},
	"value": {"zh": "数值", "en": "Value"},
	"l2_intro": {
		"zh": "CPU 里的一切都跟着时钟走：只有在上升沿，寄存器才会记住输入 D。",
		"en": "Everything in a CPU follows the clock: registers only capture D on a rising edge.",
	},
	"l2_hint": {
		"zh": "把 {letter} = {bits} 送进寄存器：每个上升沿前设好 D，从左边第一位开始。",
		"en": "Load {letter} = {bits}: set D before each rising edge, leftmost bit first.",
	},
	"l2_hint_fast": {
		"zh": "时钟变快了！把 {letter} = {bits} 送进寄存器。",
		"en": "The clock got faster! Load {letter} = {bits}.",
	},
	"l2_success": {
		"zh": "寄存器里现在是 {bits}，正是 {letter}！",
		"en": "The register now holds {bits}: that's {letter}!",
	},
	"l2_complete": {
		"zh": "G、O，出发！你刚刚像 CPU 一样跟着时钟节拍工作。",
		"en": "G, O: let's go! You just worked to a clock beat, like a CPU.",
	},
	"l2_controls": {
		"zh": "空格切换 D 的 0 和 1，也可以直接点击 D 开关。",
		"en": "Space toggles D between 0 and 1, or tap the D switch.",
	},
	"card2_title": {"zh": "知识卡 · 时钟与触发器", "en": "Knowledge Card · Clock and Flip-flops"},
	"card2_1": {
		"zh": "时钟是一串不停的高低脉冲，一高一低叫一个周期。",
		"en": "The clock is a steady train of pulses; one high and one low make a cycle.",
	},
	"card2_2": {
		"zh": "触发器只在上升沿记住输入，其余时间保持不变，所以能存 1 个比特。",
		"en": "A flip-flop captures input only on a rising edge, so it can hold 1 bit.",
	},
	"card2_3": {
		"zh": "3 GHz 的 CPU，每秒有 30 亿个上升沿。",
		"en": "A 3 GHz CPU sees 3 billion rising edges every second.",
	},
}
