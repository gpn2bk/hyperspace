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
  
  # 后台运行 aios-cli start，并等待5秒
  aios-cli start &
  sleep 5
  
  # 查询显卡内存和剩余硬盘大小
  GPU_MEM=$(lspci | grep -i nvidia && nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits || echo 0)
  TOTAL_DISK=$(df / | tail -1 | awk '{print $4}')
  
  # 检查硬盘大小
  if [ "$TOTAL_DISK" -lt 1048576 ]; then
    echo "硬盘不足1G"
    exit 1
  elif [ "$TOTAL_DISK" -lt 4194304 ]; then
    aios-cli models add hf:afrideva/Tiny-Vicuna-1B-GGUF:tiny-vicuna-1b.q4_k_m.gguf
  else
    aios-cli models add hf:afrideva/Tiny-Vicuna-1B-GGUF:tiny-vicuna-1b.q4_k_m.gguf
    aios-cli models add hf:acon96/Home-3B-v3-GGUF:Home-3B-v3.q8_0.gguf
  fi
  aios-cli hive login
  
  # 选择适当的层级
  if [ "$GPU_MEM" -eq 0 ]; then
    num=5
  elif [ "$GPU_MEM" -lt 2048 ]; then
    num=5
  elif [ "$GPU_MEM" -lt 4096 ]; then
    num=4
  elif [ "$GPU_MEM" -lt 8192 ]; then
    num=3
  elif [ "$GPU_MEM" -lt 20480 ]; then
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
  echo "key.gem位于/root/.config/hyperspace"
}

# 查看积分函数
check_points() {
  aios-cli hive points
}

check_logs() {
  screen -r hyperspace
}

# 显示菜单
show_menu() {
  echo "请选择功能："
  echo "1. 安装节点"
  echo "2. 查看积分"
  echo "0. 退出"
}

while true; do
  show_menu
  read -p "输入你的选择: " choice
  case $choice in
    1)
      install_node
      ;;
    2)
      check_points
      ;;
    3)
      check_logs
      ;;
    0)
      echo "退出脚本"
      exit 0
      ;;
    *)
      echo "无效的选择，请重新输入"
      ;;
  esac
done
