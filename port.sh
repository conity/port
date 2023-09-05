#!/bin/bash

read -p "请输入要转发的本地端口号： " local_port
read -p "请输入目标服务器的 IP 地址： " target_ip
read -p "请输入目标服务器的端口号： " target_port

# 更新防火墙规则
if [ -x "$(command -v firewall-cmd)" ]; then
  # CentOS 防火墙规则更新
  firewall-cmd --add-forward-port=port="$local_port":proto=tcp:toaddr="$target_ip":toport="$target_port"
elif [ -x "$(command -v ufw)" ]; then
  # Ubuntu 防火墙规则更新
  ufw allow "$local_port"/tcp
  iptables -t nat -A PREROUTING -p tcp --dport "$local_port" -j DNAT --to-destination "$target_ip":"$target_port"
else
  echo "无法确定系统类型或防火墙工具不存在"
  exit 1
fi

# 启用IP转发
echo "1" > /proc/sys/net/ipv4/ip_forward

# 配置端口转发
iptables -t nat -A PREROUTING -p tcp --dport "$local_port" -j DNAT --to-destination "$target_ip":"$target_port"
iptables -t nat -A POSTROUTING -j MASQUERADE

# 保存防火墙规则
if [ -x "$(command -v firewall-cmd)" ]; then
  # CentOS 保存防火墙规则
  firewall-cmd --runtime-to-permanent
elif [ -x "$(command -v ufw)" ]; then
  # Ubuntu 保存防火墙规则
  ufw reload
else
  echo "无法确定系统类型或防火墙工具不存在"
  exit 1
fi

echo "端口转发已经成功设置！"
