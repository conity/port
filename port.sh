#!/bin/bash

# 交互式输入本地端口
read -p "请输入本地监听端口号: " LOCAL_PORT

# 交互式输入目标 IP
read -p "请输入目标 IP 地址: " DEST_IP

# 交互式输入目标端口
read -p "请输入目标端口号: " DEST_PORT

# 清除所有已经存在的转发规则
iptables -F

# 启用内核 IP 转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 设置转发规则，将外部请求的 LOCAL_PORT 端口转发到内部的 DEST_IP 的 DEST_PORT 端口
iptables -t nat -A PREROUTING -p tcp --dport $LOCAL_PORT -j DNAT --to-destination $DEST_IP:$DEST_PORT
iptables -t nat -A POSTROUTING -j MASQUERADE

# 保存规则
iptables-save > /etc/iptables/rules.v4

# 打开防火墙端口
ufw allow $LOCAL_PORT

# 启用防火墙
ufw enable

echo "端口转发已设置完成！"
