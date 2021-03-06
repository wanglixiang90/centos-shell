#!/bin/bash
#
# rsync file
# example: bash rsync-file.sh 本机账号 本机路径 目标账号 目标路径 目标IP 目标端口

# 解决相对路径问题
cd `dirname $0`

# 定义变量
LOCAL_ACCOUNT=$1
LOCAL_FILE_PATH=$2
TAGER_ACCOUNT=$3
TAGER_FILE_PATH=$5
TAGER_IP=$6
TAGET_PORT=$7
# 判断变量
if [[ ! -n ${LOCAL_ACCOUNT} ]]; then
  echo "请输入本机账号"
  exit 1
fi
if [[ ! -n ${LOCAL_FILE_PATH} ]]; then
  echo "请输入本地路径"
  exit 1
fi
if [[ ! -n ${TAGER_ACCOUNT} ]]; then
  echo "请输入目标账号"
  exit 1
fi
if [[ ! -n ${TAGER_FILE_PATH} ]]; then
  echo "请输入目标路径"
  exit 1
fi
if [[ ! -n ${TAGER_IP} ]]; then
  echo "请输入目标IP"
  exit 1
fi
if [[ ! -n ${TAGET_PORT} ]]; then
  echo "请输入目标端口"
  exit 1
fi

# 执行
sudo -u ${LOCAL_ACCOUNT} rsync -avh  -e 'ssh -p ${TAGET_PORT}' ${LOCAL_FILE_PATH} ${TAGER_ACCOUNT}@${TAGER_IP}:${TAGER_FILE_PATH}