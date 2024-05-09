#!/bin/bash
CLUSTER='hadoop102'

# 如果是 root 用户, 直接退出
if [ $USER == "root" ]; then
  echo "当前用户是 root 用户, 请切换普通用户 bigdata 后执行脚本"
  exit 1
fi

IFS="," read -r -a Hosts <<<"$CLUSTER"

hive_start() {
  hdfs dfsadmin -safemode wait
  xcall -w "${Hosts[0]}" "nohup hive --service hiveserver2 1>/dev/null 2>&1 &"
  xcall -w "${Hosts[0]}" "nohup hive --service metastore 1>/dev/null 2>&1 &"
  while ! nc -z ${Hosts[0]} 10000; do sleep 1; done
}

hive_stop() {
  xcall -w "${Hosts[0]}" "ps -ef | grep -i hiveserver2 | grep -v grep | awk '{print \$2}' | xargs -n1 kill"
  xcall -w "${Hosts[0]}" "ps -ef | grep -i metastore | grep -v grep | awk '{print \$2}' | xargs -n1 kill"
}

case $1 in
start)
  hive_start
  ;;
stop)
  hive_stop
  ;;
restart)
  hive_stop
  sleep 3
  hive_start
  ;;
status)
  if nc -z ${Hosts[0]} 10000; then echo "hiveserver2正在运行"; else echo "hiveserver2未启动成功"; fi
  if nc -z ${Hosts[0]} 9083; then echo "metastore正在运行"; else echo "metastore未启动成功"; fi
  ;;
*) ;;
esac
