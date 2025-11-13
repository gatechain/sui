#!/bin/bash
# DEX Hybrid 完整演示脚本
# 功能：发布合约、创建池子、铸造代币、下单、查询

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 等待用户确认
wait_for_user() {
    if [ "$AUTO_MODE" != "true" ]; then
        read -p "按 Enter 继续..."
    else
        sleep 2
    fi
}

# 提取 JSON 字段
extract_json_field() {
    local json=$1
    local field=$2
    echo "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*"\([^"]*\)".*/\1/' | head -1
}

# 提取创建的对象 ID
extract_created_object() {
    local output=$1
    local type_filter=$2
    echo "$output" | grep -A 10 "\"objectType\"" | grep -B 5 "$type_filter" | grep "\"objectId\"" | head -1 | sed 's/.*"\([^"]*\)".*/\1/'
}

# ============================================
# 步骤 1: 发布合约
# ============================================
publish_package() {
    log_info "开始发布 DEX 合约包..."
    
    cd "$(dirname "$0")/.."
    
    # 先编译检查
    log_info "编译合约..."
    sui move build
    
    if [ $? -ne 0 ]; then
        log_error "合约编译失败！"
        exit 1
    fi
    
    log_success "编译成功！"
    log_info "正在发布合约..."
    
    # 发布合约
    PUBLISH_OUTPUT=$(sui client publish --gas-budget 100000000 --json 2>&1)
    
    # 提取 Package ID
    PACKAGE_ID=$(echo "$PUBLISH_OUTPUT" | grep -o "\"packageId\"[[:space:]]*:[[:space:]]*\"0x[^\"]*\"" | sed 's/.*"\(0x[^"]*\)".*/\1/' | head -1)
    
    if [ -z "$PACKAGE_ID" ]; then
        log_error "无法提取 Package ID！"
        echo "$PUBLISH_OUTPUT"
        exit 1
    fi
    
    log_success "合约发布成功！"
    log_info "Package ID: $PACKAGE_ID"
    
    # 提取 Treasury Cap IDs
    log_info "正在提取 Treasury Cap（等待区块确认）..."
    
    sleep 5  # 等待对象创建和区块确认
    
    # 查询所有对象（JSON 格式）
    log_info "正在查询所有对象..."
    OBJECTS=$(sui client objects --json 2>/dev/null)
    
    # 保存到临时文件便于调试
    echo "$OBJECTS" > /tmp/sui_objects.json
    
    # 提取 TOKEN_A Treasury（更精确的匹配）
    TOKEN_A_TREASURY=$(echo "$OBJECTS" | grep -o "\"objectId\"[[:space:]]*:[[:space:]]*\"0x[a-f0-9]*\"" | grep -B 50 "token_a::TOKEN_A" | grep "TreasuryCap" -A 5 | grep "objectId" | head -1 | sed 's/.*"\(0x[^"]*\)".*/\1/')
    
    # 如果第一种方法失败，尝试第二种方法
    if [ -z "$TOKEN_A_TREASURY" ]; then
        TOKEN_A_TREASURY=$(echo "$OBJECTS" | jq -r '.[] | select(.data.type | contains("TreasuryCap") and contains("token_a::TOKEN_A")) | .data.objectId' 2>/dev/null | head -1)
    fi
    
    # 提取 TOKEN_B Treasury
    TOKEN_B_TREASURY=$(echo "$OBJECTS" | grep -o "\"objectId\"[[:space:]]*:[[:space:]]*\"0x[a-f0-9]*\"" | grep -B 50 "token_b::TOKEN_B" | grep "TreasuryCap" -A 5 | grep "objectId" | head -1 | sed 's/.*"\(0x[^"]*\)".*/\1/')
    
    # 如果第一种方法失败，尝试第二种方法
    if [ -z "$TOKEN_B_TREASURY" ]; then
        TOKEN_B_TREASURY=$(echo "$OBJECTS" | jq -r '.[] | select(.data.type | contains("TreasuryCap") and contains("token_b::TOKEN_B")) | .data.objectId' 2>/dev/null | head -1)
    fi
    
    # 如果还是找不到，使用交互式输入
    if [ -z "$TOKEN_A_TREASURY" ] || [ -z "$TOKEN_B_TREASURY" ]; then
        log_warning "无法自动提取 Treasury Caps"
        log_info "请手动查找并输入..."
        
        echo ""
        log_info "运行此命令查看所有对象:"
        echo "  sui client objects --json | grep -A 20 TreasuryCap"
        echo ""
        
        if [ -z "$TOKEN_A_TREASURY" ]; then
            read -p "请输入 TOKEN_A Treasury Cap ID: " TOKEN_A_TREASURY
        fi
        
        if [ -z "$TOKEN_B_TREASURY" ]; then
            read -p "请输入 TOKEN_B Treasury Cap ID: " TOKEN_B_TREASURY
        fi
        
        if [ -z "$TOKEN_A_TREASURY" ] || [ -z "$TOKEN_B_TREASURY" ]; then
            log_error "Treasury Cap ID 不能为空！"
            exit 1
        fi
    fi
    
    log_success "找到 Treasury Caps:"
    log_info "TOKEN_A Treasury: $TOKEN_A_TREASURY"
    log_info "TOKEN_B Treasury: $TOKEN_B_TREASURY"
    
    # 保存到配置文件
    cat > dex_config.env << EOF
PACKAGE_ID=$PACKAGE_ID
TOKEN_A_TREASURY=$TOKEN_A_TREASURY
TOKEN_B_TREASURY=$TOKEN_B_TREASURY
YOUR_ADDRESS=$(sui client active-address)
EOF
    
    log_success "配置已保存到 dex_config.env"
}

# ============================================
# 步骤 2: 创建交易池
# ============================================
create_pool() {
    log_info "创建交易池..."
    
    POOL_OUTPUT=$(sui client call \
        --package "$PACKAGE_ID" \
        --module dex_hybrid_example \
        --function create_test_pool \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "创建交易池失败！"
        echo "$POOL_OUTPUT"
        exit 1
    fi
    
    # 保存输出到临时文件便于调试
    echo "$POOL_OUTPUT" > /tmp/pool_creation.json
    
    # 方法 1: 从交易输出的 created objects 中提取 Pool ID
    POOL_ID=$(echo "$POOL_OUTPUT" | jq -r '.objectChanges[]? | select(.objectType | contains("dex_hybrid::Pool")) | .objectId' 2>/dev/null | head -1)
    
    # 方法 2: 如果方法 1 失败，尝试从 effects 中提取
    if [ -z "$POOL_ID" ]; then
        POOL_ID=$(echo "$POOL_OUTPUT" | jq -r '.effects.created[]? | select(.owner.Shared) | .reference.objectId' 2>/dev/null | head -1)
    fi
    
    # 方法 3: 如果还是失败，等待并从所有对象中查询
    if [ -z "$POOL_ID" ]; then
        log_info "等待区块确认..."
        sleep 5
        
        OBJECTS=$(sui client objects --json 2>/dev/null)
        
        # 尝试用 jq 提取
        POOL_ID=$(echo "$OBJECTS" | jq -r ".[] | select(.data.type | contains(\"$PACKAGE_ID\") and contains(\"dex_hybrid::Pool\")) | .data.objectId" 2>/dev/null | head -1)
        
        # 如果 jq 失败，尝试 grep
        if [ -z "$POOL_ID" ]; then
            POOL_ID=$(echo "$OBJECTS" | grep -A 10 "dex_hybrid::Pool" | grep "objectId" | head -1 | sed 's/.*"\(0x[^"]*\)".*/\1/')
        fi
    fi
    
    # 方法 4: 如果所有自动方法都失败，手动输入
    if [ -z "$POOL_ID" ]; then
        log_warning "无法自动提取 Pool ID"
        log_info "交易输出已保存到: /tmp/pool_creation.json"
        log_info "请查看交易输出或运行以下命令:"
        echo ""
        echo ""
        read -p "请输入 Pool ID: " POOL_ID
        
        if [ -z "$POOL_ID" ]; then
            log_error "Pool ID 不能为空！"
            exit 1
        fi
    fi
    
    log_success "交易池创建成功！"
    log_info "Pool ID: $POOL_ID"
    
    # 更新配置文件
    echo "POOL_ID=$POOL_ID" >> dex_config.env
}

# ============================================
# 步骤 3: 铸造代币
# ============================================
mint_tokens() {
    log_info "铸造 TOKEN_A (1000 个)..."
    
    MINT_A_OUTPUT=$(sui client call \
        --package "$PACKAGE_ID" \
        --module dex_hybrid_example \
        --function mint_token_a \
        --args "$TOKEN_A_TREASURY" 1000000000000 "$YOUR_ADDRESS" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "铸造 TOKEN_A 失败！"
        echo "$MINT_A_OUTPUT"
        exit 1
    fi
    
    # 从交易输出中提取 TOKEN_A Coin ID
    TOKEN_A_COIN=$(echo "$MINT_A_OUTPUT" | jq -r '.objectChanges[]? | select(.objectType | contains("token_a::TOKEN_A")) | .objectId' 2>/dev/null | head -1)
    
    if [ -z "$TOKEN_A_COIN" ]; then
        # 备用方法：从 effects 中提取
        TOKEN_A_COIN=$(echo "$MINT_A_OUTPUT" | jq -r '.effects.created[]? | select(.owner.AddressOwner) | .reference.objectId' 2>/dev/null | head -1)
    fi
    
    log_success "TOKEN_A 铸造成功！"
    log_info "TOKEN_A Coin ID: $TOKEN_A_COIN"
    
    sleep 2
    
    log_info "铸造 TOKEN_B (1000 个)..."
    
    MINT_B_OUTPUT=$(sui client call \
        --package "$PACKAGE_ID" \
        --module dex_hybrid_example \
        --function mint_token_b \
        --args "$TOKEN_B_TREASURY" 1000000000000 "$YOUR_ADDRESS" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "铸造 TOKEN_B 失败！"
        echo "$MINT_B_OUTPUT"
        exit 1
    fi
    
    # 从交易输出中提取 TOKEN_B Coin ID
    TOKEN_B_COIN=$(echo "$MINT_B_OUTPUT" | jq -r '.objectChanges[]? | select(.objectType | contains("token_b::TOKEN_B")) | .objectId' 2>/dev/null | head -1)
    
    if [ -z "$TOKEN_B_COIN" ]; then
        # 备用方法：从 effects 中提取
        TOKEN_B_COIN=$(echo "$MINT_B_OUTPUT" | jq -r '.effects.created[]? | select(.owner.AddressOwner) | .reference.objectId' 2>/dev/null | head -1)
    fi
    
    log_success "TOKEN_B 铸造成功！"
    log_info "TOKEN_B Coin ID: $TOKEN_B_COIN"
    
    # 如果仍然无法提取，尝试查询所有对象
    if [ -z "$TOKEN_A_COIN" ] || [ -z "$TOKEN_B_COIN" ]; then
        log_info "等待区块确认并查询所有对象..."
        sleep 3
        
        OBJECTS=$(sui client objects --json 2>/dev/null)
        
        if [ -z "$TOKEN_A_COIN" ]; then
            TOKEN_A_COIN=$(echo "$OBJECTS" | jq -r ".[] | select(.data.type | contains(\"token_a::TOKEN_A\") and contains(\"Coin\")) | .data.objectId" 2>/dev/null | head -1)
        fi
        
        if [ -z "$TOKEN_B_COIN" ]; then
            TOKEN_B_COIN=$(echo "$OBJECTS" | jq -r ".[] | select(.data.type | contains(\"token_b::TOKEN_B\") and contains(\"Coin\")) | .data.objectId" 2>/dev/null | head -1)
        fi
    fi
    
    # 验证是否成功获取
    if [ -z "$TOKEN_A_COIN" ] || [ -z "$TOKEN_B_COIN" ]; then
        log_error "无法提取代币 Coin ID！"
        log_info "请手动查询: sui client objects | grep -A 5 'Coin'"
        
        if [ -z "$TOKEN_A_COIN" ]; then
            read -p "请输入 TOKEN_A Coin ID: " TOKEN_A_COIN
        fi
        
        if [ -z "$TOKEN_B_COIN" ]; then
            read -p "请输入 TOKEN_B Coin ID: " TOKEN_B_COIN
        fi
    fi
    
    log_success "代币铸造完成！"
    log_info "TOKEN_A Coin: $TOKEN_A_COIN"
    log_info "TOKEN_B Coin: $TOKEN_B_COIN"
    
    # 更新配置
    echo "TOKEN_A_COIN=$TOKEN_A_COIN" >> dex_config.env
    echo "TOKEN_B_COIN=$TOKEN_B_COIN" >> dex_config.env
}

# ============================================
# 步骤 4: 下买单
# ============================================
place_buy_order() {
    log_info "下买单: 用 15 TOKEN_B 购买 10 TOKEN_A (价格 1.5)..."
    
    if [ -z "$TOKEN_B_COIN" ]; then
        log_error "TOKEN_B_COIN 未设置！"
        exit 1
    fi
    
    BUY_OUTPUT=$(sui client call \
        --package "$PACKAGE_ID" \
        --module dex_hybrid_example \
        --function place_buy_order \
        --args "$POOL_ID" 1500000000 10000000000 "$TOKEN_B_COIN" \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "下买单失败！"
        echo "$BUY_OUTPUT"
        exit 1
    fi
    
    log_success "买单创建成功！价格: 1.5 TOKEN_B, 数量: 10 TOKEN_A"
}

# ============================================
# 步骤 5: 下卖单
# ============================================
place_sell_order() {
    log_info "下卖单: 卖出 10 TOKEN_A，要求 1.8 TOKEN_B (价格 1.8)..."
    
    SELL_OUTPUT=$(sui client call \
        --package "$PACKAGE_ID" \
        --module dex_hybrid_example \
        --function place_sell_order \
        --args "$POOL_ID" 1800000000 10000000000 \
        --gas-budget 10000000 \
        --json 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "下卖单失败！"
        echo "$SELL_OUTPUT"
        exit 1
    fi
    
    log_success "卖单创建成功！价格: 1.8 TOKEN_B, 数量: 10 TOKEN_A"
}

# ============================================
# 步骤 6: 查询订单簿
# ============================================
query_orderbook() {
    log_info "查询订单簿状态..."
    
    # 查询 Pool 对象
    log_info "Pool ID: $POOL_ID"
    
    POOL_DATA=$(sui client object "$POOL_ID" --json 2>&1)
    
    if [ $? -ne 0 ]; then
        log_error "查询订单簿失败！"
        echo "$POOL_DATA"
        exit 1
    fi
    
    log_success "订单簿查询成功！"
    echo ""
    log_info "订单簿详情:"
    echo "$POOL_DATA" | grep -A 30 "fields"
    
    echo ""
    log_info "查询最佳价格..."
    
    # 查询最佳买价和卖价（如果函数支持）
    SPREAD_OUTPUT=$(sui client call \
        --package "$PACKAGE_ID" \
        --module dex_hybrid_example \
        --function get_spread \
        --args "$POOL_ID" \
        --gas-budget 10000000 \
        2>&1)
    
    if [ $? -eq 0 ]; then
        log_success "价格查询成功！"
        echo "$SPREAD_OUTPUT" | grep -A 5 "returnValues"
    else
        log_warning "无法查询价格，可能函数不可用"
    fi
}

# ============================================
# 显示配置信息
# ============================================
show_config() {
    log_info "当前配置:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Package ID:       $PACKAGE_ID"
    echo "Pool ID:          $POOL_ID"
    echo "TOKEN_A Treasury: $TOKEN_A_TREASURY"
    echo "TOKEN_B Treasury: $TOKEN_B_TREASURY"
    echo "TOKEN_A Coin:     $TOKEN_A_COIN"
    echo "TOKEN_B Coin:     $TOKEN_B_COIN"
    echo "Your Address:     $YOUR_ADDRESS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================
# 主菜单
# ============================================
show_menu() {
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║       DEX Hybrid 演示脚本                 ║"
    echo "╚═══════════════════════════════════════════╝"
    echo ""
    echo "1. 🚀 发布合约包"
    echo "2. 🏊 创建交易池"
    echo "3. 💰 铸造代币 (TOKEN_A & TOKEN_B)"
    echo "4. 📈 下买单 (Buy Order)"
    echo "5. 📉 下卖单 (Sell Order)"
    echo "6. 📊 查询订单簿"
    echo "7. ⚡ 运行完整流程 (1-6)"
    echo "8. 🔧 显示配置"
    echo "9. 🔄 加载配置文件"
    echo "0. 退出"
    echo ""
}

# ============================================
# 运行完整流程
# ============================================
run_full_flow() {
    log_info "开始运行完整流程..."
    echo ""
    
    publish_package
    wait_for_user
    
    create_pool
    wait_for_user
    
    mint_tokens
    wait_for_user
    
    place_buy_order
    wait_for_user
    
    place_sell_order
    wait_for_user
    
    query_orderbook
    
    log_success "完整流程执行完毕！"
    show_config
}

# ============================================
# 加载配置文件
# ============================================
load_config() {
    if [ -f "dex_config.env" ]; then
        source dex_config.env
        log_success "配置文件加载成功！"
        show_config
    else
        log_warning "配置文件不存在！请先执行步骤 1 发布合约"
    fi
}

# ============================================
# 主程序
# ============================================
main() {
    # 检查是否在正确的目录
    if [ ! -f "Move.toml" ]; then
        log_error "请在 dex_test 目录下运行此脚本！"
        exit 1
    fi
    
    # 检查 sui 命令
    if ! command -v sui &> /dev/null; then
        log_error "sui 命令未找到！请先安装 Sui CLI"
        exit 1
    fi
    
    # 尝试加载已有配置
    if [ -f "dex_config.env" ]; then
        source dex_config.env
        log_info "已加载现有配置"
    fi
    
    # 如果有命令行参数，直接运行
    if [ "$1" == "auto" ]; then
        AUTO_MODE=true
        run_full_flow
        exit 0
    fi
    
    # 交互式菜单
    while true; do
        show_menu
        read -p "请选择操作 [0-9]: " choice
        
        case $choice in
            1)
                publish_package
                ;;
            2)
                create_pool
                ;;
            3)
                mint_tokens
                ;;
            4)
                place_buy_order
                ;;
            5)
                place_sell_order
                ;;
            6)
                query_orderbook
                ;;
            7)
                run_full_flow
                ;;
            8)
                show_config
                ;;
            9)
                load_config
                ;;
            0)
                log_info "退出程序"
                exit 0
                ;;
            *)
                log_error "无效的选择！"
                ;;
        esac
        
        echo ""
        read -p "按 Enter 返回菜单..."
    done
}

# 运行主程序
main "$@"

