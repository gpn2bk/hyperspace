#!/bin/bash

install_node() {
  
  # 检查机器是否可用
  if ! lscpu | grep -E "sse4_2|avx|avx2" > /dev/null; then
    echo "机器不可用"
    exit 1
  fi
  
  # 安装节点
  curl https://download.hyper.space/api/install | bash
  source /root/.bashrc
  
  # 后台运行 aios-cli start
  aios-cli start &
  
  # 查询显存和硬盘大小
  TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  TOTAL_DISK=$(df / | tail -1 | awk '{print $4}')
  
  # 检查硬盘大小
  if [ "$TOTAL_DISK" -lt 1048576 ]; then
    echo "硬盘不足1G"
    exit 1
  elif [ "$TOTAL_DISK" -lt 2097152 ]; then
    aios-cli models add hf:afrideva/Tiny-Vicuna-1B-GGUF:tiny-vicuna-1b.q4_k_m.gguf
  else
    aios-cli models add hf:afrideva/Tiny-Vicuna-1B-GGUF:tiny-vicuna-1b.q4_k_m.gguf
    aios-cli models add hf:acon96/Home-3B-v3-GGUF:Home-3B-v3.q8_0.gguf
  fi
  aios-cli hive login
  
  # 选择适当的层级
  if [ "$TOTAL_MEM" -lt 2097152 ]; then
    num=5
  elif [ "$TOTAL_MEM" -lt 4194304 ]; then
    num=4
  elif [ "$TOTAL_MEM" -lt 8388608 ]; then
    num=3
  elif [ "$TOTAL_MEM" -lt 20971520 ]; then
    num=2
  else
    num=1
  fi
  
  aios-cli hive select-tier $num --verbose
  
  # 结束当前的 aios-cli 进程，开一个新的 screen 会话
  aios-cli kill
  screen -dmS hyperspace
  screen -S hyperspace -X stuff "aios-cli start --connect\n"
  
  echo "安装完成"
}

# 查看积分函数
check_points() {
  aios-cli hive points
}
