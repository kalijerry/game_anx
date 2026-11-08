# ANX 开发须知（给 AI 和人）

Godot 4.3 + GDScript 的计算机科普游戏。目标玩家是**零基础初学者**，中英文同步（`data/strings.gd` 每个 key 都要有 `zh` 和 `en`）。作者每周只有约 5 小时，改动保持小而清楚。

本地没有 `godot` 时：从 https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip 下载，放到 PATH 上，然后先跑一次 `godot --headless --path . --import`。

## 自迭代流程：改完关卡必须走一遍

任何改动关卡、文字或界面的工作，都按下面的循环做，直到报告干净、自查清单全部通过，才算完成：

1. **跑测试**
   ```sh
   godot --headless --path . -s tests/test_bit_logic.gd   # 纯逻辑和文字/字体检查
   for t in tests/test_level_*.gd; do godot --headless --path . -s "$t"; done
   tools/playtest.sh                                      # AI 玩家通关 + 乱按 + 界面检查（约 10 秒）
   ```
2. **看报告和截图**
   - `build/playtest/report.md`：每关是否通关、动作数、错误操作次数、要读多少字，以及问题列表（`error` 必须修，`warning` 要判断）。
   - `tools/playtest.sh --shots`（xvfb 下真实渲染，约 1 分钟）会把每句对白出现时的画面存到 `build/playtest/shots/`。逐张看。
3. **用初学者的眼睛自查**（对照报告里「What the player reads, in order」和截图）：
   - 每句话里的术语，前面是否解释过？没解释就先解释或换成白话。
   - 每一步都清楚告诉玩家「现在该点哪里 / 按什么」吗？
   - 正在讲的东西在画面上有高亮或箭头吗？
   - 一句话是否太长（中文超过约 70 字就拆开）？英文是否同样清楚？
   - 玩家做错时，提示是否说明了为什么错、正确该怎么做？
   - 有没有文字被挡住、超出框、或者和别的东西重叠（截图里看）？
4. **修改**，回到第 1 步。
5. 在 PR 描述里写上：报告结果（PASS / 错误数）、自查发现了什么、改了什么。

## 加新关卡时

- 场景放 `scenes/level_NN.tscn`，在 `scripts/levels.gd` 里登记。
- **必须**给 AI 玩家写一个大脑：`tests/playtest/brains/level_NN.gd`（文件名和场景同名），实现 `act(bot, lvl)` 和 `leave(bot, lvl)`。没有大脑的关卡会让 playtest 失败。
- 大脑只能像玩家一样操作：`bot.key(KEY_...)`、`bot.click(pos)`、`bot.click_label(Loc.text("..."))`。可以读画面上显示的状态（目标、PC 值等）来做决定，但不能直接调用关卡的内部函数。
- 关卡需要有 `done`、`msg_key`、`msg_args` 三个变量（AI 玩家靠它们判断通关和记录对白）。
- 按钮用 `flat_canvas.gd` 的 `button()`、文字用 `text()` / `text_c()` / `text_wrap()` 画，这样 AI 玩家才「看得见」，界面检查也才查得到。

## 其他约定

- 新增文字后如果字体测试失败，按 README 的「字体」一节重新生成字体子集。
- 截图辅助参数：`-- --demo=complete` 等，见 README。
- 每个 PR 上 CI 会并行跑单元测试、AI playtest 和 Web 导出；合并到 main 自动发布到 https://game.kalijerry.uk 。
