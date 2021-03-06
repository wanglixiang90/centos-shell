#!/bin/bash
#
# init centos 6

# 引入外部文件
source ../common/util.sh

# 检查root
util::check_root

# 安装前置依赖
# 安装常用软件
yum install -y wget git curl traceroute zlib 
yum install -y zlib-devel openssl openssl-devel pcre pcre-devel 
yum install -y gcc gcc-c++ make cmake autoconf 
yum install -y automake libtool pam-devel libtool libxml2 
yum install -y libxml2-devel libxslt libxslt-devel json-c json-c-devel 
yum install -y cmake gmp gmp-devel mpfr mpfr-devel 
yum install -y boost-devel pcre-devel lrzsz ntp ntpdate 
yum install -y sysstat vim bison-devel ncurses-devel net-snmp 
yum install -y sysstat dstat iotop flex byacc 
yum install -y libpcap libpcap-devel nfs-utils zip unzip 
yum install -y xz lsof bison openssh-clients lftp
yum install -y htop telnet tcpdump sshpass
yum -y groupinstall "Development Tools" "Server Platform Development"

# 配置阿里云源
## 备份
cp /etc/yum.repos.d/CentOS-Base.repo{,.bak'_'`date +%Y%m%d_%H%M%S`}
## 下载
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
## 生效测试
yum clean all
yum makecache

# 配置epel源
yum install -y epel-release
yum install -y wget
## 备份(如有配置其他epel源)
cp /etc/yum.repos.d/epel.rep{,.bak'_'`date +%Y%m%d_%H%M%S`}
cp /etc/yum.repos.d/epel-testing.repo{,.bak'_'`date +%Y%m%d_%H%M%S`}
## 下载新repo 到/etc/yum.repos.d/
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo

# 关闭selinux，清空iptables
## 关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
## 清空iptables
## 清理防火墙规则
iptables -F
## 清空所有自定义规则
iptables -X
## 所有计数器归0
iptables -Z
## 清理nat转发规则
iptables -F -t nat
iptables -Z -t nat
iptables -X -t nat
## 保存防火墙配置信息
/etc/init.d/iptables save

# 开启路由转发功能
sed -i '/net.ipv4.ip_forward/s/0/1/' /etc/sysctl.conf
sysctl -p

# 定时自动更新服务器时间
## 编辑时间配置文件，CST，本地时间，设置为false，硬件时钟不与UTC时间一致
cat <<EOF > /etc/sysconfig/clock
ZONE="Asia/Shanghai"
UTC=false
ARC=false
EOF
## linux的时区设置为上海时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai    /etc/localtime
## 对准时间
ntpdate cn.pool.ntp.org &> /dev/null
## 设置硬件时间和系统时间一致并校准    
/sbin/hwclock --systohc
## 再次更新时间并且写入BOIS
ntpdate cn.pool.ntp.org && hwclock -w && hwclock --systohc#
# 写入定时任务定时更新时间
if [[ `grep -c "cn.pool.ntp.org" /etc/crontab` = 0 ]]; then
    echo '*/5 * * * * /usr/sbin/ntpdate cn.pool.ntp.org &>/dev/null' >> /etc/crontab
fi

# 调整文件描述符大小
cat << EOF > /etc/security/limits.conf
*    soft    nofile  65535
*    hard    nofile  65535
*    soft    nproc 65535
*    hard    nproc 65535
EOF
sed -i 's/65535/1024000/g' /etc/security/limits.d/90-nproc.conf

# 调整字符集，使其支持中文
yum -y groupinstall chinese-support &> /dev/null
sed -i s/"^LANG=.*$"/"LANG=zh_CN.UTF-8"/ /etc/sysconfig/i18n
echo 'SUPPORTED="zh_CN:zh:en_US.UTF-8:en_US:en:zh_CN.GB18030"' >> /etc/sysconfig/i18n
source /etc/sysconfig/i18n

# 去除系统及内核版本登录前的屏幕显示
## 备份
cp /etc/redhat-release{,.bak'_'`date +%Y%m%d_%H%M%S`}
cp /etc/issue{,.bak'_'`date +%Y%m%d_%H%M%S`}
## 修改
echo "" >/etc/redhat-release
echo "" >/etc/issue

# 不锁定文件，避免往后维护困难($CHATTR -i可以恢复)
# chattr +i /etc/passwd
# chattr +i /etc/inittab
# chattr +i /etc/group
# chattr +i /etc/shadow
# chattr +i /etc/gshadow
# chattr +i /etc/resolv.conf
# chattr +i /etc/hosts
# chattr +i /etc/fstab
# mv /usr/bin/chattr /usr/bin/rttahc

# 系统审计和故障排查
mkdir -p /usr/etc/.history
chmod -R 777 /usr/etc/.history
cat >> /etc/profile << "EOF"
# 内容审计
HISTDIR=/usr/etc/.history
USER_IP=`who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'`
if [ -z ${USER_IP} ]; then
    USER_IP=`hostname`
fi
if [ ! -d ${HISTDIR} ]; then
    mkdir -p ${HISTDIR}
    chmod 777 ${HISTDIR}
fi
if [ ! -d ${HISTDIR}/${LOGNAME} ]; then
    mkdir -p ${HISTDIR}/${LOGNAME}
    chmod 300 ${HISTDIR}/${LOGNAME}
fi
export HISTSIZE=2000
DT=`date +%Y%m%d_%H%M%S`
export HISTFILE="${HISTDIR}/${LOGNAME}/${USER_IP}.history.$DT"
export HISTTIMEFORMAT="[%Y.%m.%d %H:%M:%S] "
chmod 600 ${HISTDIR}/${LOGNAME}/*.history* 2>/dev/null
EOF
## 更新环境变量
. /etc/profile

# 关闭重启ctl-alt-delete组合键
sed -i 's/exec \/sbin\/shutdown -r now \"Control-Alt-Delete pressed\"/#exec \/sbin\/shutdown -r now \"Control-Alt-Delete pressed\"/g' /etc/init/control-alt-delete.conf

# 替换rm命令
## 创建文件夹
mkdir -p /data/.trash/tmp
chmod -R 777 /data/.trash/tmp
chmod -R 777 /data/.trash
## 创建删除文件命令
cat <<"EOF" > /data/.trash/remove.sh
TRASH_DIR="/data/.trash/tmp"
for i in $*; do  
    STAMP=`date +%s`  
    fileName=`basename $i`  
    mv $i $TRASH_DIR/$fileName.$STAMP  
done  
EOF
## 赋予权限
chmod +x /data/.trash/remove.sh
## 替换rm命令
cat <<EOF > /etc/profile.d/remove.sh
alias rm="sh /data/.trash/remove.sh"
EOF
sed -i 's/alias rm/alias rmd/g' ~/.bashrc
## 生效
. /etc/profile
## 配置定时删除
if [[ `grep -c "trash" /etc/crontab` = 0 ]]; then
    echo '0 0 0 0 1/1 rm -rf /data/.trash/tmp/* &>/dev/null' >> /etc/crontab
fi

# 替换关机/重启命令(shutdown/poweroff/reboot)
cat <<EOF > /etc/profile.d/init.sh
alias reboot='echo "Prohibition of use!"'
alias shutdown='echo "Prohibition of use!"'
alias poweroff='echo "Prohibition of use!"'
EOF