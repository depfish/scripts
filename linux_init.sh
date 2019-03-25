#!/bin/bash
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
(crontab -l 2>/dev/null; echo "0 4 * * * ntpdate cn.pool.ntp.org") | crontab -

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

## 设置Linux系统参数及 sudo无密码 ##
function linux_sys_config(){
cp -p /etc/sysctl.conf /etc/sysctl.conf_bak_$(date +%Y-%m-%d-%s)
cat >/etc/sysctl.conf<<EOF
fs.file-max = 9999999
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

    cp -p /etc/sudoers /etc/sudoers_bak
    cp -p /etc/sudoers /etc/sudoers_bak_$(date +%Y-%m-%d-%s)
    sed -i '20,30s/.*\%admin.*/\%admin\ ALL=\(ALL\)\ NOPASSWD\:\ ALL/g' /etc/sudoers
    groupadd admin
    usermod -G admin $(last -w|head -1|awk '{print $1}')

}

## 添加jumpserver key ##
add_jumpserver_key(){
mkdir -p /root/.ssh
cat >>/root/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYllvMxL1XqWgeNg9QttsguCmG+QCToN3sAneCBoqk6t2Gkr7fjxDlhUvK8qzcX4tp33clRr9oSv54yHK+A9/RpiwPTRhJd72q/P033q1f88cSe4cz5B5e+2rgff1/UNaqvpCsTWqkrmQHHy97ItEVfZUQHacL14f+ix7EUQhDzgaS+QzIaZSsoltUmUdW9ZNtWGve7UJS2DQnADOyRDxyzFQTcg6j4hNcNUttkQ//FsElKF5gyTQ6Uzzjdia0sIsq/CyGj7B57aA7qkNznxgdkkt++q3NBaLQ/dqp7bXHHd8pLV3DbZ+Hi6d5JFXUEumePVGw9VAe85UMOGXjWR1R jumpserver@a01.master.jumpserver.ops.v.bj.mydreamplus.com
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBbEaTaxJAWYoba7Xe1PCCK5TxhcxKGz5T4A544G0IC7kLaKHe0QUwkwkwtfeJYDJYaHLQKTO2p4aLdn0s61xyOfhMHWs6aFCHMmc9M+7v+uTJK8aEsnEdrLKSAYF/y57cLswGLGQbvj98wwTmagaOc1yHHqKM0bAXtHvPJ/vabfT4LjL3y/VeJXwGvjhHi+jnn3NDoYimOkoY0IJaAEHdH18SXCF7sy0+BgJbfYhERKErTatxsIG+IXNw8+XNlO/rwL7zbl1XmUYXEn41MkMLryKe2sxMMg2jIpAYmVuVqhJh5GQ2h1R7t3n1vjP5AKyXVcmLdI9AokNXC3oIWupX jumpserver
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBOdD5rNWgwP9X9KDdTCmGMvqPNbnGc6fsE2fhyUqwa66qIjH6NThXB/Znv/cEzRpc66P+luCbKkY+7lY4IZYfhWXk7AMXUR7NI1tXEz3BuLcDWJ2Ng9+M5zS1L/+k4pp6/ZTLOBaVZZrt6aG4buugHZ89Hhq6i4/N+ruCLzzHw67mtAHOa2qg2iQrgHBUaVvFwN1thqxt5CGF2t6n0yue+ynkJTsb5lJVuYDy3tgdrTwkSKOYMwPy2ubiGXu96X38qPTkF9EA7B9t++ShCO/cqtahgzxMvNEZMzB6zNvygVcIHb39qZ7yaqpTQea/1x0yz4SkmdDwZ5RZueZ/SRh/ ggmm@ggmm-K42Jc
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC539a7fnIvI1YbMJh8vqC3p5jcBRy4zo0DAeG0gm7GuRlej8uvhbBWo5gTZFcUQ0EzQuIh2YChe2/y0Xy0KJ2R7/ZymlYpn2cw5G+iHp268YZ9v0Maa8MCQBYjZjYHvdTLNQhLX5s/SBErGILVov6+c1HReQ6vFUXePCgYICq1AvbSeckOXZ6M8LBnpHLY8V4/f/jCPfRgHOmLK+WBURoCuQB7zgPkTJDJuYnfAoNtone/mwKbekrgdXxh+/JlpEM8V1dt6U6o0ja7yz+fp6iYUlDZvmA68C/JlkpdXnFNIYLNtSdbFxI+Sh3Ohol6lTyHZLys7fzW7cuo7Ii7VWFd zhangyu@cainiao
EOF
chmod 600 /root/.ssh/authorized_keys
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

#安装dokcer
install_docker(){
echo -e "####################### start install docker ################################################\n\n"
apt-get -y install curl

curl https://get.docker.com > /tmp/docker_install.sh
sed -i '20,60s/DOWNLOAD_URL=.*/DOWNLOAD_URL=\"https:\/\/mirrors.aliyun.com\/docker-ce\"/g' /tmp/docker_install.sh

/bin/bash /tmp/docker_install.sh

}

docker_config(){
cp -p /etc/default/docker /etc/default/docker_bak_$(date +%Y-%m-%d-%s)
cat >>/etc/default/docker<<EOF
DOCKER_OPTS="-H unix://var/run/docker.sock -H tcp://0.0.0.0:4243 --bip=172.17.0.1/24 --registry-mirror=https://registry.docker-cn.com  --insecure-registry registry.aws.mxj.io --insecure-registry registry.cd.mxj.io --insecure-registry registryaws.mxj360.com --insecure-registry registry.cd.mxj360.com --log-opt max-size=100m --log-opt max-file=5"
EOF

service docker restart

### 不添加hosts docker login 会失败##
#cat >>/etc/hosts<<EOF
#10.28.3.131  registry.cd.mxj.io
#EOF

export DOCKER_USER=admin
export DOCKER_PASS=li.yun@mydreamplus.com

for DOCKER_HOST in registryaws.mxj360.com registrycd.mxj360.com
do
docker login --username=$DOCKER_USER --password=$DOCKER_PASS $DOCKER_HOST
done

}

docker_gc(){
cd /opt/
PWD=/opt
git clone https://github.com/spotify/docker-gc.git

cat >/opt/docker-gc/gc-cron.sh<<EOF
#!/bin/bash -ex
export FORCE_IMAGE_REMOVAL=1
/opt/docker-gc/docker-gc
EOF

chmod +x /opt/docker-gc/gc-cron.sh /opt/docker-gc/docker-gc
(crontab -l 2>/dev/null; echo "30 4 * * * /opt/docker-gc/gc-cron.sh >> /var/log/docker-gc.log 2>&1") | crontab -
}

install_build-essential(){
    apt-get install -y build-essential git curl wget mlocate bzip2 unzip lrzsz docker-compose make
}




set_Locale_Lang
update_time
update_source
install_build-essential
linux_sys_config
add_jumpserver_key
install_docker
docker_config




