#!/bin/bash
# 查找已铸造的 Coin 对象

echo "🔍 正在查找代币 Coins..."
echo ""

# 从配置文件读取 Package ID
PACKAGE_ID=$(cat dex_config.env 2>/dev/null | grep PACKAGE_ID | cut -d'=' -f2)

if [ -z "$PACKAGE_ID" ]; then
    echo "❌ 找不到 Package ID，请先运行步骤 1"
    exit 1
fi

echo "📦 Package ID: $PACKAGE_ID"
echo ""

# 获取所有对象
OBJECTS=$(sui client objects --json 2>/dev/null)

# 查找 TOKEN_A Coins
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🪙 TOKEN_A Coins:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOKEN_A_COINS=$(echo "$OBJECTS" | jq -r ".[] | select(.data.type | contains(\"$PACKAGE_ID\") and contains(\"token_a::TOKEN_A\") and contains(\"Coin\")) | \"\(.data.objectId) (balance: \(.data.content.fields.balance))\"" 2>/dev/null)

if [ ! -z "$TOKEN_A_COINS" ]; then
    echo "$TOKEN_A_COINS"
    TOKEN_A_COIN=$(echo "$TOKEN_A_COINS" | head -1 | awk '{print $1}')
else
    echo "❌ 未找到 TOKEN_A Coins"
    TOKEN_A_COIN=""
fi

echo ""

# 查找 TOKEN_B Coins
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🪙 TOKEN_B Coins:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOKEN_B_COINS=$(echo "$OBJECTS" | jq -r ".[] | select(.data.type | contains(\"$PACKAGE_ID\") and contains(\"token_b::TOKEN_B\") and contains(\"Coin\")) | \"\(.data.objectId) (balance: \(.data.content.fields.balance))\"" 2>/dev/null)

if [ ! -z "$TOKEN_B_COINS" ]; then
    echo "$TOKEN_B_COINS"
    TOKEN_B_COIN=$(echo "$TOKEN_B_COINS" | head -1 | awk '{print $1}')
else
    echo "❌ 未找到 TOKEN_B Coins"
    TOKEN_B_COIN=""
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 生成更新命令
if [ ! -z "$TOKEN_A_COIN" ] && [ ! -z "$TOKEN_B_COIN" ]; then
    echo ""
    echo "✅ 找到所有 Coins！"
    echo ""
    echo "📝 更新配置文件命令："
    echo ""
    echo "echo \"TOKEN_A_COIN=$TOKEN_A_COIN\" >> dex_config.env"
    echo "echo \"TOKEN_B_COIN=$TOKEN_B_COIN\" >> dex_config.env"
    echo ""
    echo "或者直接运行："
    echo ""
    echo "cat >> dex_config.env << EOF"
    echo "TOKEN_A_COIN=$TOKEN_A_COIN"
    echo "TOKEN_B_COIN=$TOKEN_B_COIN"
    echo "EOF"
    echo ""
    
    # 询问是否自动更新
    read -p "是否自动更新配置文件? (y/n): " AUTO_UPDATE
    if [ "$AUTO_UPDATE" = "y" ] || [ "$AUTO_UPDATE" = "Y" ]; then
        # 检查是否已经存在
        if grep -q "TOKEN_A_COIN" dex_config.env 2>/dev/null; then
            echo "⚠️  配置文件中已存在 TOKEN_A_COIN，删除旧的..."
            sed -i.bak '/TOKEN_A_COIN/d' dex_config.env
        fi
        
        if grep -q "TOKEN_B_COIN" dex_config.env 2>/dev/null; then
            echo "⚠️  配置文件中已存在 TOKEN_B_COIN，删除旧的..."
            sed -i.bak '/TOKEN_B_COIN/d' dex_config.env
        fi
        
        echo "TOKEN_A_COIN=$TOKEN_A_COIN" >> dex_config.env
        echo "TOKEN_B_COIN=$TOKEN_B_COIN" >> dex_config.env
        
        echo "✅ 配置文件已更新！"
        echo ""
        cat dex_config.env
    fi
else
    echo ""
    echo "⚠️  未找到所有 Coins，请确保已经完成步骤 3 (铸造代币)"
    echo ""
    echo "运行以下命令查看所有对象:"
    echo "  sui client objects --json | jq '.[] | select(.data.type | contains(\"Coin\"))'"
fi

