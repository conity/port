#!/bin/bash

# 检测操作系统类型
if [[ -e /etc/lsb-release ]]; then
    OS="ubuntu"
elif [[ -e /etc/redhat-release ]]; then
    OS="centos"
else
    echo "不支持的操作系统"
    exit 1
fi

# 安装fail2ban
if [ "$OS" == "ubuntu" ]; then
    sudo apt-get update
    sudo apt-get install -y fail2ban
elif [ "$OS" == "centos" ]; then
    sudo yum install -y epel-release
    sudo yum install -y fail2ban
fi

# 创建SSH配置文件备份
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 交互式更改SSH端口
read -p "请输入新的SSH端口号（默认为22）: " SSH_PORT
if [ -z "$SSH_PORT" ]; then
    SSH_PORT=22
fi

# 更新SSH配置文件
sudo sed -i "s/^Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config

# 开放新的SSH端口
if [ "$OS" == "ubuntu" ]; then
    sudo ufw allow $SSH_PORT/tcp
    sudo ufw reload
elif [ "$OS" == "centos" ]; then
    sudo firewall-cmd --zone=public --add-port=$SSH_PORT/tcp --permanent
    sudo firewall-cmd --reload
fi

# 创建SSH配置文件
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# 修改SSH配置
sudo sed -i '/^\[sshd\]/a enabled = true' /etc/fail2ban/jail.local

# 创建自定义filter文件
sudo tee /etc/fail2ban/filter.d/sshd_custom.conf > /dev/null <<EOL
[Definition]
failregex = ^%(__prefix_line)s(?:error: PAM: )?Authentication failure for .* from <HOST> port \d+.*$
ignoreregex =
EOL

# 重新启动SSH和fail2ban服务
if [ "$OS" == "ubuntu" ]; then
    sudo service ssh restart
    sudo service fail2ban restart
elif [ "$OS" == "centos" ]; then
    sudo systemctl restart sshd
    sudo systemctl restart fail2ban
fi

echo "成功配置fail2ban来防止SSH暴力破解，并更改SSH端口为 $SSH_PORT"
