#!/bin/bash
# 辅助脚本：查找 Treasury Cap 对象

echo "🔍 正在查找 Treasury Caps..."
echo ""

# 获取最新发布的 Package ID
PACKAGE_ID=$(cat dex_config.env 2>/dev/null | grep PACKAGE_ID | cut -d'=' -f2)

if [ ! -z "$PACKAGE_ID" ]; then
    echo "📦 Package ID: $PACKAGE_ID"
    echo ""
fi

# 方法 1: 使用 JSON 格式
echo "方法 1: JSON 格式查询"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OBJECTS=$(sui client objects --json 2>/dev/null)

# 查找 TOKEN_A Treasury
echo "查找 TOKEN_A Treasury Cap..."
TOKEN_A=$(echo "$OBJECTS" | jq -r '.[] | select(.data.type | contains("TreasuryCap") and contains("token_a::TOKEN_A")) | "\(.data.objectId) (version: \(.data.version))"' 2>/dev/null)

if [ ! -z "$TOKEN_A" ]; then
    echo "✅ 找到 TOKEN_A Treasury:"
    echo "   $TOKEN_A"
else
    echo "❌ 未找到 TOKEN_A Treasury"
fi

echo ""

# 查找 TOKEN_B Treasury
echo "查找 TOKEN_B Treasury Cap..."
TOKEN_B=$(echo "$OBJECTS" | jq -r '.[] | select(.data.type | contains("TreasuryCap") and contains("token_b::TOKEN_B")) | "\(.data.objectId) (version: \(.data.version))"' 2>/dev/null)

if [ ! -z "$TOKEN_B" ]; then
    echo "✅ 找到 TOKEN_B Treasury:"
    echo "   $TOKEN_B"
else
    echo "❌ 未找到 TOKEN_B Treasury"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 方法 2: 显示所有 TreasuryCap 对象
echo "方法 2: 所有 TreasuryCap 对象"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sui client objects 2>/dev/null | grep -B 3 -A 3 "TreasuryCap"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 方法 3: 完整 JSON 输出（保存到文件）
echo "方法 3: 完整 JSON 已保存到 /tmp/all_treasuries.json"
echo "$OBJECTS" | jq '[.[] | select(.data.type | contains("TreasuryCap"))]' > /tmp/all_treasuries.json 2>/dev/null
echo "运行命令查看: cat /tmp/all_treasuries.json | jq"
echo ""

# 提取并显示格式化的信息
echo "📋 汇总信息"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOKEN_A_ID=$(echo "$TOKEN_A" | awk '{print $1}')
TOKEN_B_ID=$(echo "$TOKEN_B" | awk '{print $1}')

if [ ! -z "$TOKEN_A_ID" ] && [ ! -z "$TOKEN_B_ID" ]; then
    echo "✅ 成功找到所有 Treasury Caps！"
    echo ""
    echo "复制以下命令设置环境变量："
    echo ""
    echo "export TOKEN_A_TREASURY=$TOKEN_A_ID"
    echo "export TOKEN_B_TREASURY=$TOKEN_B_ID"
    echo ""
    echo "或者手动更新 dex_config.env 文件："
    echo ""
    echo "echo \"TOKEN_A_TREASURY=$TOKEN_A_ID\" >> dex_config.env"
    echo "echo \"TOKEN_B_TREASURY=$TOKEN_B_ID\" >> dex_config.env"
else
    echo "⚠️  无法自动找到所有 Treasury Caps"
    echo ""
    echo "请手动查找："
    echo "1. 运行: sui client objects --json | jq '.[] | select(.data.type | contains(\"TreasuryCap\"))'"
    echo "2. 查找包含 token_a::TOKEN_A 和 token_b::TOKEN_B 的对象"
    echo "3. 复制对应的 objectId"
fi

