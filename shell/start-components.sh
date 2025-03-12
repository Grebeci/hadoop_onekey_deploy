#!/usr/bin/env bash

# 如果是root用户，切换到bigdata用户
if [ "$(whoami)" = "root" ]; then
  echo "请用bigdata用户执行该脚本"
  exit;
fi

case $1 in
   hadoop)
     case $2 in
      start)
          xcall -w "hadoop102" "start-dfs.sh"
          xcall -w "hadoop103" "start-yarn.sh"
        ;;
      stop)
          xcall -w "hadoop102" "stop-dfs.sh"
          xcall -w "hadoop103" "stop-yarn.sh"
        ;;
      *)
        echo "Usage: $0 {hadoop|zookeeper|hive} {start|stop}"
        exit 1
        ;;
    esac
    ;;

  zookeeper)
    case $2 in
      start)
        xcall -w "hadoop102" "/home/bigdata/bin/zks.sh start"
        ;;
      stop)
        xcall -w "hadoop102" "/home/bigdata/bin/zks.sh stop"
        ;;
      restart)
        xcall -w "hadoop102" "/home/bigdata/bin/zks.sh stop"
        ;;
      *)
        echo "Usage: $0 {hadoop|zookeeper|hive} {start|stop}"
        exit 1
        ;;
    esac
    ;;
  hive)
    case $2 in
      start)
          xcall -w "hadoop102" "/home/bigdata/bin/hive_services.sh start"
        ;;
      stop)
          xcall -w "hadoop102" "/home/bigdata/bin/hive_services.sh stop"
        ;;
      restart)
           xcall -w "hadoop102" "/home/bigdata/bin/hive_services.sh restart"
        ;;
      *)
          echo "Usage: $0 {hadoop|zookeeper|hive} {start|stop}"
        ;;
    esac
    ;;
  *)
    echo "Usage: $0 {hadoop|zookeeper|hive} {start|stop}"
    exit 1
    ;;
esac
