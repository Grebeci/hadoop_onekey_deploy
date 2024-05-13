#!/usr/bin/env bash

################################################################################################
# 本脚本用于初始化三台阿里云服务器, 自动化一些 Prerequisites
# 约定3台服务器名称为  hadoop102 hadoop103 hadoop104
# 1. 新建用户（bigdata),并配置集群间免密访问
# 2. 配置所有节点相互免密登录, root用户和一般用户都需要
#####  配置思路是先用 root 用户登录, 配置好 hadoop102 访问 hadoop103 和 hadoop104 的免密登录，然后同步 ssh 目录，让 一般用户（bigdata）和root ssh 配置相同。

# 检查是否为root用户
if [ ! "$(whoami)" = "root" ]; then
  echo "Please run this script as root"
  exit;
fi

# hadoop102 安装必要的依赖
ssh root@hadoop102 "yum install -y epel-release; yum install -y psmisc nc net-tools rsync vim lrzsz ntp libzstd openssl-static tree iotop git libaio pdsh unzip python3 python3-pip; pip3 install requests"

# root 用户免密操作
ssh-keygen -t rsa  -f ~/.ssh/id_rsa -N "" -q
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

echo "手动复制以下内容到 hadoop103 和 hadoop104 的 ~/.ssh/authorized_keys 文件中"
cat ~/.ssh/id_rsa.pub
# 等待用户复制完成
read -p "Press any key to continue... " -n1 -s

# 避免首次登录的主机密钥确认
ssh-keyscan -H hadoop102 >> ~/.ssh/known_hosts
ssh-keyscan -H hadoop103 >> ~/.ssh/known_hosts
ssh-keyscan -H hadoop104 >> ~/.ssh/known_hosts


# 同步 ssh 目录
rsync -avz ~/.ssh hadoop103:~/
rsync -avz ~/.ssh hadoop104:~/

# 同步 /etc/hosts
rsync -avz /etc/hosts hadoop103:/etc/
rsync -avz /etc/hosts hadoop104:/etc/

# 新建用户
useradd bigdata
# 为该用户配置超级管理员权限
echo "bigdata ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# 配置 bigdata 用户间免密登录 (bigdata  和 root 共享一套  ssh  密钥)
# 在 hadoop101 上配置, 然后同步到 hadoop102 和 hadoop103
rsync -avz /root/.ssh hadoop102:/home/bigdata/
chown -R bigdata:bigdata /home/bigdata/.ssh

# hadoop103 和 hadoop104 一套ssh密钥
ssh root@hadoop103  "useradd bigdata; echo 'bigdata ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
rsync -avz /home/bigdata/.ssh hadoop103:/home/bigdata/

ssh root@hadoop104  "useradd bigdata; echo 'bigdata ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
rsync -avz /home/bigdata/.ssh hadoop104:/home/bigdata/

# 安装包准备
ssh bigdata@hadoop102 "sudo mkdir -p  /opt/software"
ssh bigdata@hadoop103 "sudo mkdir -p  /opt/software"
ssh bigdata@hadoop104 "sudo mkdir -p  /opt/software"

# oss 下载文件
sudo -v ; curl https://gosspublic.alicdn.com/ossutil/install.sh | sudo bash
ossutil config

ossutil cp -r oss://hadoop3-oss-cn /opt/software/ --include "*"
rsync -avz /opt/software hadoop103:/opt/
rsync -avz /opt/software hadoop104:/opt/

# 关闭防火墙
ssh root@hadoop102 "systemctl stop firewalld; systemctl disable firewalld"
ssh root@hadoop103 "systemctl stop firewalld; systemctl disable firewalld"
ssh root@hadoop104 "systemctl stop firewalld; systemctl disable firewalld"

# 安装必要依赖
ssh root@hadoop103 "yum install -y epel-release; yum install -y psmisc nc net-tools rsync vim lrzsz ntp libzstd openssl-static tree iotop git libaio pdsh unzip python3 python3-pip; pip3 install requests"
ssh root@hadoop104 "yum install -y epel-release; yum install -y psmisc nc net-tools rsync vim lrzsz ntp libzstd openssl-static tree iotop git libaio pdsh unzip python3 python3-pip; pip3 install requests"

cd ~
cp -r hadoop_onekey_deploy /home/bigdata
