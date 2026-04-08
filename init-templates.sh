#!/usr/bin/env bash
# 一键初始化常见人设模板

PERSONA_DIR="${1:-${SKILL_ROOT:-.}/personas}"
mkdir -p "$PERSONA_DIR"

echo "创建 10 个预设人设..."

# 1. 技术极客
jq -n \
    --arg name "技术极客" \
    --arg desc "资深技术从业者，对代码、架构、系统底层有深入理解。讨厌『简单解释』和『打个比方』，想要精确的技术细节、实现原理、性能数据和最佳实践。能阅读英文文档，偏好官方资料而非二手博客。讨厌过度简化的回答。" \
    --argjson tags '["technical", "detailed", "professional"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/技术极客.json"

# 2. 商务精英  
jq -n \
    --arg name "商务精英" \
    --arg desc "时间极度宝贵的商务人士。只关心结果、成本、ROI、时间线。讨厌铺垫和客套话，要直接给结论和行动项。能接受『这样做可以，这样做不行』的二元答案。不需要解释原理，只需要知道『怎么做最快达成目标』。" \
    --argjson tags '["business", "efficient", "direct"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/商务精英.json"

# 3. 创意人
jq -n \
    --arg name "创意人" \
    --arg desc "设计师/艺术家/创意工作者。注重视觉美感、用户体验、情感共鸣。讨厌千篇一律的模板化方案，想要有创意、有温度、有独特性的回答。可以接受非常规思路，甚至鼓励『疯狂的想法』。对颜色、排版、字体敏感。" \
    --argjson tags '["creative", "visual", "artistic"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/创意人.json"

# 4. 学习者
jq -n \
    --arg name "学习者" \
    --arg desc "正在学习新领域的初学者或进阶学习者。希望回答有系统性、由浅入深、有例子。不介意详细解释，反而欢迎。希望知道『为什么』而不只是『怎么做』。可以接受推荐学习资源和练习建议。有耐心，不怕长答案。" \
    --argjson tags '["learning", "patient", "curious"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/学习者.json"

# 5. 极简主义者
jq -n \
    --arg name "极简主义者" \
    --arg desc "极度厌恶冗余信息。只想要最核心的答案，最好是一句话或一个命令。不需要背景介绍、不需要礼貌用语、不需要选项分析。给最推荐的方案即可，其他都视为噪音。" \
    --argjson tags '["minimal", "concise", "efficient"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/极简主义者.json"

# 6. 幽默玩家
jq -n \
    --arg name "幽默玩家" \
    --arg desc "喜欢轻松氛围，可以接受甚至期待回答中有幽默、梗、轻松的语气。讨厌过于严肃和板着脸的回答。可以在技术内容中穿插玩笑，能让学习/工作过程不那么无聊。不是不专业，只是不喜欢无趣。" \
    --argjson tags '["humor", "casual", "relaxed"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/幽默玩家.json"

# 7. 严谨专家
jq -n \
    --arg name "严谨专家" \
    --arg desc "学术/法律/医疗等严谨领域从业者。要求绝对精确，不能容忍模糊表述。需要引用来源、数据支持、边界条件说明。讨厌『大概』『可能』『一般来说』。希望看到完整的逻辑链条和风险提示。" \
    --argjson tags '["precise", "formal", "academic"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/严谨专家.json"

# 8. 创业者
jq -n \
    --arg desc "全能型选手，同时关心技术、商业、产品、运营。时间碎片化，需要快速抓住重点。喜欢 MVP 思维，关注『最小成本验证』。可以接受不完美但快速的方案。讨厌纯理论，要实战建议。" \
    --arg name "创业者" \
    --argjson tags '["pragmatic", "fast", "versatile"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/创业者.json"

# 9. 导师型
jq -n \
    --arg name "导师型" \
    --arg desc "喜欢教导他人，希望回答不仅能解决问题，还能让对方学到东西。会解释原理、提供背景知识、指出常见误区。有耐心，愿意打比方帮助理解。希望培养对方的独立思考能力，而不是直接给答案。" \
    --argjson tags '["teaching", "patient", "guiding"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/导师型.json"

# 10. 怀疑论者
jq -n \
    --arg name "怀疑论者" \
    --arg desc "对任何说法都保持怀疑，需要看到证据、对比数据、潜在风险分析。讨厌『公认』『显然』『众所周知』。希望看到正反两面的论证，了解什么情况下方案会失败。喜欢追问『有什么坑』『有什么替代方案』。" \
    --argjson tags '["critical", "analytical", "cautious"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/怀疑论者.json"

jq -n \
    --arg name "穷鬼" \
    --arg desc "每一分钱都要花在刀刃上。任何方案必须优先考虑成本、免费替代品、开源方案。讨厌一上来就推荐付费服务、企业级方案、豪华配置。喜欢白嫖、开源、自托管、二手、DIY。能自己折腾的绝不花钱。对价格敏感，喜欢性价比比较。" \
    --argjson tags '["frugal", "cost-conscious", "diy"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/穷鬼.json"

# 12. 老板
jq -n \
    --arg name "老板" \
    --arg desc "企业掌舵人，关注大局、战略方向、团队管理。不在意技术细节，在意结果、风险和投入产出比。时间比钱贵，需要高屋建瓴的建议。讨厌被问『要不要这样做』，要听『这样做的好处/风险是什么』。喜欢听反直觉的洞察和跨行业经验。" \
    --argjson tags '["strategic", "high-level", "executive"]' \
    '{name: $name, description: $desc, tags: $tags}' \
    > "$PERSONA_DIR/老板.json"

echo ""
echo "✓ 已创建 12 个人设:"
ls -1 "$PERSONA_DIR"/*.json | xargs -I{} basename {} .json
echo ""
echo "使用示例:"
echo "  ~/.openclaw/workspace/skills/persona-manager/persona.sh use 技术极客"
echo "  ~/.openclaw/workspace/skills/persona-manager/persona.sh combine 创业者,创意人 as 创艺型"
echo ""
