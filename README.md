# Persona Manager

一个用于 OpenClaw 的人设管理技能，支持单人设、多人设组合、自动进化等功能。

## 功能特性

### 基础功能
- 📝 创建和管理多个人设
- 🔄 快速切换人设
- 🔗 组合多个人设（如：创业者+极简主义者）
- 📋 列出和查看现有人设

### 自动进化（Auto-Evolution）
- 🧠 **信号检测**：实时分析对话中的反馈信号
- ⏰ **心跳任务**：定期分析最近的对话
- ✏️ **自动更新**：根据信号自动更新人设描述
- 📈 **累积学习**：保守策略，3次以上信号才触发更新

### AI 辅助功能
- 🎯 分析用户行为并建议人设
- 🔍 检测当前对话匹配哪个预设人设
- 💡 从对话历史自动创建人设

## 预设人设（12个）

| 人设 | 特点 |
|------|------|
| **技术极客** | 要精确技术细节、实现原理、性能数据。讨厌过度简化。 |
| **商务精英** | 时间宝贵，只要结果和行动项，不需要解释。 |
| **创意人** | 注重视觉美感，喜欢非常规思路，对颜色字体敏感。 |
| **学习者** | 喜欢由浅入深、有例子、有耐心解释。 |
| **极简主义者** | 极度厌恶冗余，只想要最核心的答案。 |
| **幽默玩家** | 喜欢轻松氛围，期待回答中有幽默和梗。 |
| **严谨专家** | 要求绝对精确，需要引用来源和边界条件。 |
| **创业者** | 关心技术+商业+产品，喜欢MVP思维，要实战。 |
| **导师型** | 希望对方学到东西，愿意打比方解释原理。 |
| **怀疑论者** | 需要看到证据和风险分析，喜欢追问有什么坑。 |
| **穷鬼** | 优先免费/开源/自托管/DIY。讨厌一上来就推荐付费。 |
| **老板** | 关注大局、战略方向、投入产出比。要高屋建瓴的建议。 |

## 安装

```bash
# 克隆到 OpenClaw skills 目录
cd ~/.openclaw/workspace/skills
git clone https://github.com/yang1394920/persona-manager.git

# 初始化预设人设
./persona-manager/init-templates.sh
```

## 使用方法

### 基础命令

```bash
# 创建人设
./persona.sh set 王力 "一个直接的人，讨厌废话，喜欢中英双语"

# 切换人设
./persona.sh use 王力

# 查看当前人设
./persona.sh show

# 列出所有人设
./persona.sh list

# 组合人设
./persona.sh combine 创业者,极简主义者 as 极简创业者
./persona.sh use 极简创业者

# 删除人设
./persona.sh delete 王力
```

### 自动进化

```bash
# 启用自动进化
./scripts/heartbeat-evolver.sh enable

# 查看进化状态
./scripts/heartbeat-evolver.sh status

# 手动运行进化分析
./scripts/heartbeat-evolver.sh run

# 查看进化日志
./scripts/heartbeat-evolver.sh log

# 调整触发阈值（默认3个信号）
./scripts/heartbeat-evolver.sh config threshold 5
```

### 信号检测（可集成到对话流程）

```bash
# 检测文本中的信号
./scripts/signal-detector.sh detect "太长了，直接给结论"

# 处理消息并加入信号队列
./scripts/signal-detector.sh process "太长了，直接给结论" 王力

# 查看24小时内的信号汇总
./scripts/signal-detector.sh summary

# 检查是否达到更新阈值
./scripts/signal-detector.sh check
```

### 自动更新

```bash
# 根据信号更新人设
./scripts/auto-updater.sh update 王力 too_long 3

# 批量更新（从信号汇总文件）
./scripts/signal-detector.sh summary > /tmp/signals.json
./scripts/auto-updater.sh batch 王力 /tmp/signals.json
```

## 信号检测规则

系统会自动检测以下类型的信号：

| 信号类型 | 触发词 | 含义 |
|----------|--------|------|
| `too_long` | 太长了、太啰嗦、废话 | 偏好简短回答 |
| `need_detail` | 详细点、展开说、解释一下 | 有时需要详细解释 |
| `direct` | 直接说、别废话、给结论 | 想要直接回答 |
| `cost` | 便宜、免费、开源、省钱 | 成本敏感 |
| `aesthetic` | 好看、优雅、丑、设计感 | 重视视觉美感 |
| `humor` | 哈哈、有意思、幽默 | 喜欢轻松氛围 |
| `technical` | 底层、原理、技术细节 | 想要技术深度 |
| `speed` | 快、急、马上、效率 | 优先速度 |

## 集成到 OpenClaw 心跳

在 `HEARTBEAT.md` 中添加：

```markdown
## Persona Auto-Evolution

检查并运行人设自动进化：
- Run: `~/.openclaw/workspace/skills/persona-manager/scripts/heartbeat-evolver.sh run`
- Frequency: Every 30 minutes
```

## 工作原理

1. **对话监测**：`signal-detector.sh` 监听用户消息，检测反馈信号
2. **信号累积**：信号被加入队列，累积权重
3. **定期分析**：`heartbeat-evolver.sh` 分析最近对话（默认24小时）
4. **阈值判断**：达到阈值（默认权重≥3）时触发更新
5. **自动写入**：`auto-updater.sh` 更新 persona JSON 文件
6. **进化记录**：更新被记录在 `evolutionLog` 中

## 文件结构

```
persona-manager/
├── SKILL.md                  # 技能说明文档
├── persona.sh                # 主脚本：人设管理
├── init-templates.sh         # 初始化预设人设
├── README.md                 # 本文件
├── scripts/
│   ├── heartbeat-evolver.sh  # 心跳任务：定期分析
│   ├── signal-detector.sh    # 信号检测：实时识别
│   └── auto-updater.sh       # 自动写入：更新JSON
├── config/
│   └── evolution-patterns.json # 信号模式配置
└── personas/                 # 人设存储目录
    ├── .active               # 当前激活的人设
    ├── .evolution.log        # 进化日志
    ├── .evolution-state.json   # 进化状态
    ├── .signal-queue.json    # 信号队列
    └── [persona].json        # 人设文件
```

## 人设文件格式

```json
{
  "name": "创业者",
  "description": "全能型选手，同时关心技术、商业、产品...",
  "tags": ["pragmatic", "fast", "versatile"],
  "created": "2026-04-08T13:00:00Z",
  "updated": "2026-04-08T14:30:00Z",
  "autoEvolve": true,
  "evolutionLog": [
    {
      "time": "2026-04-08T14:30:00Z",
      "signal_type": "direct",
      "change": "Added: wants direct answers without pleasantries"
    }
  ]
}
```

## 配置

在 `~/.openclaw/workspace/TOOLS.md` 中配置：

```markdown
## Persona Auto-Evolution

Enabled: Yes
Threshold: 3  # 触发更新所需信号数
MaxAge: 24h   # 分析多少小时内的对话
```

## 贡献

欢迎提交 PR 来：
- 添加新的预设人设
- 改进信号检测规则
- 优化自动进化算法
- 修复 bug

## License

MIT License - 自由使用、修改和分发
