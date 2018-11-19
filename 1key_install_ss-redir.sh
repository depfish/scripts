#!/usr/bin/env bash
##
## Linux init settings ##
source /root/.profile
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
#命令行安装，不要显示对话框。所有问题都默认。
export DEBIAN_FRONTEND=noninteractive
set -x

    if [ "$USER" != "root" ]; then
        echo 'Please run as root :) '
        exit 1
    fi
## Ubuntu 14/16 ##
DISTRIB_ID=$(cat /etc/lsb-release|grep DISTRIB_ID|tr -d 'DISTRIB_ID=' )
RELEASE_NUM=$(cat /etc/lsb-release|grep DISTRIB_RELEASE|tr -d "DISTRIB_RELEASE="|cut -d '.' -f1)

local_ip=$(/sbin/ifconfig |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|grep -v 127.0.0.1  |grep -v 172.*.*.*|grep -v 255|grep -v 0.0.0.0)
cp -p /etc/hosts /etc/hosts_bak
echo $local_ip `hostname` >> /etc/hosts

cp -p /etc/resolv.conf /etc/resolv.conf_bak_$(date +%Y-%m-%d-%s)
cat >/etc/resolv.conf<<EOF
nameserver 119.29.29.29
nameserver 8.8.4.4
EOF

#调整时区
update_time(){
mv /etc/localtime /etc/localtime_bak
ln -s  /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate cn.pool.ntp.org
(crontab -l 2>/dev/null; echo "0 4 * * * /usr/sbin/ntpdate cn.pool.ntp.org") | crontab -

}

## 设置语言 locale ##
set_Locale_Lang(){
    update-locale LANG="en_US.UTF-8" LANGUAGE="en_US:en"
    dpkg-reconfigure locales
cat >>/etc/profile<<EOF
##       added          ##
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
##########################
EOF
}

## 设置Linux系统参数及  ##
function linux_sys_config(){
cp -p /etc/sysctl.conf /etc/sysctl.conf_bak_$(date +%Y-%m-%d-%s)
cat >/etc/sysctl.conf<<EOF
fs.file-max = 9999999
net.ipv4.ip_forward = 1
## 优化参数#
#表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1
#表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_recycle = 0
#修改系統默认的 TIMEOUT 时间。
net.ipv4.tcp_fin_timeout = 30
#表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为20分钟。
net.ipv4.tcp_keepalive_time = 1200
#表示用于向外连接的端口范围。缺省情况下很小：32768到61000，改为10000到65000。（注意：这里不要将最低值设的太低，否则可能会占用掉正常的端口！）
net.ipv4.ip_local_port_range = 10000 65000
#表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数。
net.ipv4.tcp_max_syn_backlog = 8192

#表示系统同时保持TIME_WAIT的最大数量，如果超过这个数字，TIME_WAIT将立刻被清除并打印警告信息。
net.ipv4.tcp_max_tw_buckets = 5000
#额外的，对于内核版本新于**3.7.1**的，我们可以开启tcp_fastopen：
net.ipv4.tcp_fastopen = 3

# increase TCP max buffer size settable using setsockopt()
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
# increase Linux autotuning TCP buffer limit
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
# increase the length of the processor input queue
net.core.netdev_max_backlog = 250000
# recommended for hosts with jumbo frames enabled
net.ipv4.tcp_mtu_probing=1
EOF

sysctl -p

cp -p /etc/security/limits.conf /etc/security/limits.conf_bak_$(date +%Y-%m-%d-%s)
cat >>/etc/security/limits.conf<<EOF
* hard nofile 64000
* soft nofile 64000
root hard nofile 64000
root soft nofile 64000
* hard nproc 64000
* soft nproc 64000
root hard nproc 64000
root soft nproc 64000
* hard stack 1024
* soft stack 1024
root hard stack 1024
root soft stack 1024
EOF

cat >>/etc/profile<<EOF
ulimit -HSn 64000
EOF

cp -p /etc/security/limits.d/90-nproc.conf /etc/security/limits.d/90-nproc.conf_bak_$(date +%Y-%m-%d-%s) 2>/dev/null
cat >/etc/security/limits.d/90-nproc.conf<<EOF
* hard nproc 64000
* soft nproc 64000
root hard nproc 64000
root hard nproc 64000
EOF
}


## 切换更新源到阿里 ##
update_source(){
    echo -e "######################start update source################\n\n"
    cp -p /etc/apt/sources.list /etc/apt/sources.list_bak
    cp -p /etc/apt/sources.list /etc/apt/sources.list_bak_$(date +%Y-%m-%d-%s)
if [[ "$DISTRIB_ID" == "Ubuntu" ]];then
 if [[ "$RELEASE_NUM" == "14" ]];then
cat >/etc/apt/sources.list<<EOF
## Ubuntu 14 阿里源 ##
deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
EOF
 fi
 if [[ "$RELEASE_NUM" == "16" ]];then
cat >/etc/apt/sources.list<<EOF
## Ubuntu 16 阿里源 ##
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse

EOF
 fi
fi
    apt-get update -y
    apt-get -y install apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D || \
    apt-key adv --keyserver hkp://keys.gnupg.net --recv-keys 58118E89F3A912897C070ADBF76221572C52609D || \
    apt-key adv --keyserver hkp://pgp.mit.edu --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

}



install_ops-essential(){
    apt-get install -y build-essential vim git curl wget mlocate bzip2 unzip lrzsz iptables-persistent supervisor ipset
}


# For Ubuntu 14.04 and 16.04 users, please install from PPA
install_shadowsocks-libev(){
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
sudo apt-get update
sudo apt install -y  shadowsocks-libev ipset
}


config_ss-redir(){
#修改配置，确保他自己不运行，不过这个版本似乎有bug,他自己总是运行。
echo "START=no" >> /etc/default/shadowsocks-libev
#写入一个配置文件，ssredir用
cat >/etc/shadowsocks-libev/config_to_ha_redir.json <<EOF
{

    "server":"x.x.x.x",
    "server_port":18391,
    "local_address": "0.0.0.0",
    "local_port":12345,
    "password":"j2mn9a",
    "timeout":300,
    "method":"chacha20",
    "fast_open": true
}
EOF

}


config_iptables(){
#1. 生成国内IP地址的ipset
curl -sL http://f.ip.cn/rt/chnroutes.txt | egrep -v '^$|^#' > cidr_cn
sudo ipset -N cidr_cn hash:net
for i in `cat cidr_cn`; do echo ipset -A cidr_cn $i >> ipset.sh; done
chmod +x ipset.sh && sudo ./ipset.sh
rm -f ipset.cidr_cn.rules
sudo ipset -S > ipset.cidr_cn.rules
sudo cp ./ipset.cidr_cn.rules /etc/ipset.cidr_cn.rules

#2. 配置iptables
iptables -t nat -N shadowsocks
# 保留地址、私有地址、回环地址 不走代理
iptables -t nat -A shadowsocks -d 0/8 -j RETURN
iptables -t nat -A shadowsocks -d 127/8 -j RETURN
iptables -t nat -A shadowsocks -d 10/8 -j RETURN
iptables -t nat -A shadowsocks -d 169.254/16 -j RETURN
iptables -t nat -A shadowsocks -d 172.16/12 -j RETURN
iptables -t nat -A shadowsocks -d 192.168/16 -j RETURN
iptables -t nat -A shadowsocks -d 224/4 -j RETURN
iptables -t nat -A shadowsocks -d 240/4 -j RETURN
# 以下IP为局域网内不走代理的设备IP
##iptables -t nat -A shadowsocks -s 192.168.2.10 -j RETURN
# 发往shadowsocks服务器的数据不走代理，否则陷入死循环
# 替换x.x.x.x为你的ss服务器ip/域名
iptables -t nat -A shadowsocks -d  x.x.x.x -j RETURN

# 大陆地址不走代理，因为这毫无意义，绕一大圈很费劲的
iptables -t nat -A shadowsocks -m set --match-set cidr_cn dst -j RETURN
# 其余的全部重定向至ss-redir监听端口1080(端口号随意,统一就行)
iptables -t nat -A shadowsocks ! -p icmp -j REDIRECT --to-ports 12345
# OUTPUT链添加一条规则，重定向至shadowsocks链
iptables -t nat -A OUTPUT ! -p icmp -j shadowsocks
iptables -t nat -A PREROUTING ! -p icmp -j shadowsocks

## 保存iptalbes 规则
sudo netfilter-persistent save

}

config_supervisor(){
cat > /etc/supervisor/conf.d/ss-redir.conf <<EOF
[program:ss-redir]
command=/usr/bin/ss-redir -c /etc/shadowsocks-libev/config_to_ha_redir.json -u -v
autostart=true
autorestart=true
startretries=10
redirect_stderr=true
user=nobody
stderr_logfile=syslog
stdout_logfile=syslog
EOF

## 设置ulimit
sed -i '12a minfds=64000' /etc/supervisor/supervisord.conf
#杀掉系统自己跑的ss进程
/etc/init.d/shadowsocks-libev stop # do not run from its own script
##kill $(ps -ef |grep ss-redir|grep -v "grep"|awk '{print $2}')
pkill ss-redir

/etc/init.d/supervisor restart

}



set_Locale_Lang
update_time
update_source
install_ops-essential
linux_sys_config
install_shadowsocks-libev
config_ss-redir
config_iptables
# 设置 用翻|墙DNS
echo "nameserver 192.168.89.3" > /etc/resolv.conf
config_supervisor

sed -i '12a /sbin/ipset restore -f /etc/ipset.cidr_cn.rules' /etc/rc.local
sed -i '13a sudo netfilter-persistent start' /etc/rc.local

