#!/bin/bash

# 默认不列出正在生效的规则
list_rules=false

# 解析命令行参数
while getopts "l" opt; do
    case $opt in
        l)
            list_rules=true
            ;;
        \?)
            echo "未知参数: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# 检查并安装 socat 工具
install_socat() {
    if [[ -n $(command -v socat) ]]; then
        echo "socat 工具已安装"
        return
    fi

    if [[ -n $(command -v apt-get) ]]; then
        echo "正在安装 socat 工具 (使用 apt-get)..."
        sudo apt-get update
        sudo apt-get install -y socat
    elif [[ -n $(command -v yum) ]]; then
        echo "正在安装 socat 工具 (使用 yum)..."
        sudo yum install -y socat
    else
        echo "无法安装 socat 工具，请手动安装 socat 后再运行此脚本。"
        exit 1
    fi
}

# 列出正在生效的 socat 规则
list_active_rules() {
    echo "正在生效的 socat 规则:"
    ps aux | grep "socat"
}

# 如果使用 -l 参数，则列出正在生效的 socat 规则并退出
if $list_rules; then
    list_active_rules
    exit 0
fi

# 检查并安装 socat
install_socat

# 获取用户输入
echo "请输入本地监听端口:"
read local_port

echo "请输入目标主机:"
read remote_host

echo "请输入目标主机端口:"
read remote_port

# 开始端口转发
echo "开始端口转发: 本地端口 $local_port -> $remote_host:$remote_port"
socat TCP-LISTEN:$local_port,fork,reuseaddr TCP:$remote_host:$remote_port
