#!/bin/bash
set -euo pipefail
#
# Description: server inspection script
# Author: J1nH4ng<j1nh4ng@icloud.com>
# Date: 2025-04-27
# Version: V0.0.4.20250508_develop
# Copyright 2025 © Team 4r3al. All rights reserved.

function net_check() {
  # TODO: with self-defined backend server
  # like curl https://api.4r3al.team/net-check?token=xxx&ip=xxx
  :
}

function check_dependencies() {
  : << EOF
  - [x] lspci
  - [x] curl
  - [x] dmidecode
  - [x] bc
  - [x] mpstat
EOF

  declare -A pag_map_redhat=(
    ["lspci"]="pciutils"
    ["curl"]="curl"
    ["dmidecode"]="dmidecode"
    ["bc"]="bc"
    ["mpstat"]="sysstat"
  );

  local cmd=();

  cmd=("lspci" "curl" "dmidecode" "bc" "mpstat");

  for cmd in "${cmd[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      yum install "${pag_map_redhat[$cmd]}" -y
    fi
  done
}

function test_check_dependencies() {
  check_dependencies;
}

function get_os_info() {
  : << EOF
  - [x] 硬件型号
  - [x] CPU 架构
  - [x] CPU 型号
  - [x] CPU 内核数
  - [x] CPU 线程数
  - [x] 内存大小
  - [x] 磁盘信息
    - [x] 磁盘名称
    - [x] 磁盘大小
    - [x] 磁盘类型
  - [x] 网卡信息
    - [x] 网卡名称
    - [x] 网卡 MAC 地址
    - [x] 网卡 IP 地址
  - [x] 操作系统版本
  - [x] 内核版本
EOF

  # show system-product
  export SYSTEM_PRODUCT;
  SYSTEM_PRODUCT=$(dmidecode -s system-product-name);

  # show CPU architecture
  export CPU_ARCHITECTURE;
  CPU_ARCHITECTURE=$(uname -m);

  # show CPU name
  export CPU_NANE;
  CPU_NANE=$(awk -F ':[ \t]+' '/model name/ {print $2}' /proc/cpuinfo | uniq);

  # show physical CPU members
  export PHYSICAL_CPU_MEMBERS;
  PHYSICAL_CPU_MEMBERS=$(awk -F ':[ \t]+' '/physical id/ {print $2}' /proc/cpuinfo | sort | uniq | wc -l);

  local SIBILINGS;
  SIBILINGS=$(awk -F ':[ \t]+' '/siblings/ {print $2}' /proc/cpuinfo | uniq)

  # show CPU cores
  export SIGNAL_CPU_PHYSICAL_CORES;
  export CPU_LOGICAL_CORES;
  export CPU_PHYSICAL_CORES;
  SIGNAL_CPU_PHYSICAL_CORES=$(awk -F ':[ \t]+' '/cpu cores/ {print $2}' /proc/cpuinfo | uniq);
  CPU_LOGICAL_CORES=$((SIBILINGS*PHYSICAL_CPU_MEMBERS));
  CPU_PHYSICAL_CORES=$((SIGNAL_CPU_PHYSICAL_CORES*PHYSICAL_CPU_MEMBERS));

  export HYPER_THREADING_ENABLED;
  if [[ $((SIGNAL_CPU_PHYSICAL_CORES*PHYSICAL_CPU_MEMBERS)) -eq $CPU_LOGICAL_CORES ]]; then
    HYPER_THREADING_ENABLED="false";
  else
    HYPER_THREADING_ENABLED="true";
  fi
  # show PROCESSOR
  export PROCESSOR;
  PROCESSOR=$(awk -F ':[ \t]+' '/processor/ {print $2}' /proc/cpuinfo | uniq | wc -l);


  # show memory size
  export MEMORY_SIZE;
  # MEMORY_SIZE=$(awk -F ':[ \t]+' '/MemTotal/ {print $2}' /proc/meminfo | awk '{print int($1/1048576 + 0.999999999), "GB"}');
  MEMORY_SIZE=$(lsmem | awk -F ':[ \t]+' '/Total online memory/ {print $2}');

  # show os-release
  export OS_RELEASE;
  OS_RELEASE=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2);

  # show linux kernel version
  export LINUX_KERNEL_VERSION;
  LINUX_KERNEL_VERSION=$(uname -r);

  # show network interface name
  export NETWORK_INTERFACE_NAME;
  NETWORK_INTERFACE_NAME=$(lspci -k | grep "Ethernet controller" -m 1 -A 3 | awk -F ':[ \t]+' '/Ethernet controller/ {print $2}');

  # show network interface subsystem
  export NETWORK_INTERFACE_SUBSYSTEM;
  NETWORK_INTERFACE_SUBSYSTEM=$(lspci -k | grep "Ethernet controller" -m 1 -A 3 | awk -F ':[ \t]+' '/Subsystem/ {print $2}');

  # show network interface
  export NETWORK_INTERFACE_IP;
  NETWORK_INTERFACE_IP=$(hostname -I | awk '{print $1}')

  # show network interface MAC
  export NETWORK_INTERFACE_NICKNAME;
  export NETWORK_INTERFACE_MAC;
  NETWORK_INTERFACE_NICKNAME=$(ip -o addr show | grep "${NETWORK_INTERFACE_IP}" | awk '{print $2}')
  NETWORK_INTERFACE_MAC=$(ip link show "${NETWORK_INTERFACE_NICKNAME}" | awk '/link\/ether/ {print $2}')

  local DISK_INFO_ARRAY=();
  export DISK_INFO_ARRAY_WITH_TYPE=();
  local i;
  # chmod +x or bash
  mapfile -t DISK_INFO_ARRAY < <(lsblk -n -d -o NAME,SIZE,TYPE | grep "disk");
  for i in "${DISK_INFO_ARRAY[@]}"; do
    local DISK_NAME;
    local DISK_SIZE;
    local DISK_TYPE_CODE;
    local DISK_TYPE;
    DISK_NAME=$(echo "$i" | awk '{print $1}');
    DISK_SIZE=$(echo "$i" | awk '{print $2}');
    DISK_TYPE_CODE=$( < /sys/block/"${DISK_NAME}"/queue/rotational);
    if [ "$DISK_TYPE_CODE" -eq 0 ]; then
      DISK_TYPE="SSD";
    else
      DISK_TYPE="HDD";
    fi
    DISK_INFO_ARRAY_WITH_TYPE+=("${DISK_NAME} ${DISK_SIZE} ${DISK_TYPE}");
  done
}

function test_get_os_info() {
  get_os_info

  local i;

  echo "服务器制造商：      ${SYSTEM_PRODUCT}";
  echo "CPU 型号：          ${CPU_NANE}";
  echo "CPU 架构：          ${CPU_ARCHITECTURE}";
  echo "CPU 物理插槽数：    ${PHYSICAL_CPU_MEMBERS}";
  echo "单 CPU 物理核心数： ${SIGNAL_CPU_PHYSICAL_CORES}";
  echo "CPU 物理核心数：    ${CPU_PHYSICAL_CORES}";
  echo "CPU 逻辑核心数：    ${CPU_LOGICAL_CORES}";
  echo "CPU 线程数：        ${PROCESSOR}";
  echo "是否开启超线程：    ${HYPER_THREADING_ENABLED}";
  echo "内存大小：          ${MEMORY_SIZE}";
  echo "操作系统版本：      ${OS_RELEASE}";
  echo "内核版本：          ${LINUX_KERNEL_VERSION}";
  echo "网卡制造商：        ${NETWORK_INTERFACE_SUBSYSTEM}";
  echo "网卡型号：          ${NETWORK_INTERFACE_NAME}";
  echo "网卡名称：          ${NETWORK_INTERFACE_NICKNAME}";
  echo "网卡 MAC 地址：     ${NETWORK_INTERFACE_MAC}";
  echo "网卡 IP 地址：      ${NETWORK_INTERFACE_IP}";
  for i in "${DISK_INFO_ARRAY_WITH_TYPE[@]}"; do
    echo "磁盘名称：          $(echo "$i" | awk '{print $1}')";
    echo "磁盘大小：          $(echo "$i" | awk '{print $2}')";
    echo "磁盘类型：          $(echo "$i" | awk '{print $3}')";
  done
}

function security_check() {
  : << EOF
  - [ ] 防火墙状态
  - [ ] SSH 限制登录检测
EOF
}

function kernel_config_info() {
  : << EOF
  - [ ] 最大文件句柄数
  - [ ] TIME_WAI 超时
  - [ ] 内存交换倾向
  - [ ] SYN 重试次数
  - [ ] 最大连接数
  - [ ] TCP 快速回收
EOF
}

function get_usage_info() {
  : << EOF
  - [x] 启动时间
  - [x] 运行时间
  - [x] CPU 使用率
  - [x] 系统负载
    - [x] 1 分钟负载
    - [x] 5 分钟负载
    - [x] 15 分钟负载
  - [x] 内存使用率
  - [x] 磁盘使用率
    - [x] 磁盘总容量
    - [x] 磁盘剩余容量
    - [x] 磁盘使用率
  - [x] inode 使用率
EOF
  export START_TIME;
  START_TIME=$(uptime -s);

  export RUNNING_TIME;
  RUNNING_TIME=$(uptime -p);

  export CPU_USAGE_INFO;
  CPU_USAGE_INFO=$(mpstat 1 1 | awk '/Average:/ {print 100 - $NF "%"}');


  export MEM_USAGE_INFO;
  export FREE_MEM_INFO;
  export TOTAL_MEM_INFO;
  FREE_MEM_INFO=$(awk '/MemAvailable/ {printf "%.1f GB\n", $2/1048576}' /proc/meminfo);
  TOTAL_MEM_INFO=$(awk '/MemTotal/ {printf "%.1f GB\n", $2/1048576}' /proc/meminfo);
  MEM_USAGE_INFO=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf "%.1f%%\n", (total-avail)/total*100}' /proc/meminfo);

  export SWAP_MEM_INFO;
  export FREE_SWAP_INFO;
  export TOTAL_SWAP_INFO;
  FREE_SWAP_INFO=$(awk '/SwapFree/ {printf "%.1f GB\n", $2/1048576}' /proc/meminfo);
  TOTAL_SWAP_INFO=$(awk '/SwapTotal/ {printf "%.1f GB\n", $2/1048576}' /proc/meminfo);
  SWAP_MEM_INFO=$(awk '/SwapTotal/ {total=$2} /SwapFree/ {avail=$2} END {printf "%.1f%%\n", (total-avail)/total*100}' /proc/meminfo);

  export SYS_LOAD_IN_1_MIN;
  export SYS_LOAD_IN_5_MIN;
  export SYS_LOAD_IN_15_MIN;
  SYS_LOAD_IN_1_MIN=$(awk '{print $1}' /proc/loadavg);
  SYS_LOAD_IN_5_MIN=$(awk '{print $2}' /proc/loadavg);
  SYS_LOAD_IN_15_MIN=$(awk '{print $3}' /proc/loadavg);

#  local point;
#  export DISK_TOTAL_INFO;
#  export DISK_FREE_INFO;
#  export DISK_USAGE_INFO;
#  export DISK_PERCENT_INFO;
#
#  export INODE_TOTAL_INFO;
#  export INODE_FREE_INFO;
#  export INODE_USAGE_INFO;
#  export INODE_PERCENT_INFO;
#
#  for point in "${MOUNT_POINT_ARRAY[@]}"; do
#    if [[ "$point" != "none" ]]; then
#      DISK_TOTAL_INFO=$(df -h "${point}" | awk 'NR==2 {print $2}');
#      DISK_FREE_INFO=$(df -h "${point}" | awk 'NR==2 {print $4}');
#      DISK_USAGE_INFO=$(df -h "${point}" | awk 'NR==2 {print $3}');
#      DISK_PERCENT_INFO=$(df -h "${point}" | awk 'NR==2 {print $5}');
#      INODE_TOTAL_INFO=$(df -i "${point}" | awk 'NR==2 {print $2}');
#      INODE_FREE_INFO=$(df -i "${point}" | awk 'NR==2 {print $4}');
#      INODE_USAGE_INFO=$(df -i "${point}" | awk 'NR==2 {print $3}');
#      INODE_PERCENT_INFO=$(df -i "${point}" | awk 'NR==2 {print $5}');
#      echo "挂载点 ${point} 的总量为： ${DISK_TOTAL_INFO}";
#      echo "挂载点 ${point} 的剩余量为： ${DISK_FREE_INFO}";
#      echo "挂载点 ${point} 的使用量为： ${DISK_USAGE_INFO}";
#      echo "挂载点 ${point} 的使用率为： ${DISK_PERCENT_INFO}";
#      echo "挂载点 ${point} 的 inode 总量为： ${INODE_TOTAL_INFO}";
#      echo "挂载点 ${point} 的 inode 剩余量为： ${INODE_FREE_INFO}";
#      echo "挂载点 ${point} 的 inode 使用量为： ${INODE_USAGE_INFO}";
#      echo "挂载点 ${point} 的 inode 使用率为： ${INODE_PERCENT_INFO}";
#    fi
#  done
}

function get_mount_point_info() {
  export MOUNT_POINT_ARRAY=();
  local MOUNT_POINT;
  local line;

  while read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    MOUNT_POINT=$(echo "$line" | awk '{print $2}')

    if [[ -n "$MOUNT_POINT" ]]; then
      MOUNT_POINT_ARRAY+=("${MOUNT_POINT}")
    fi
  done < /etc/fstab
}

function test_get_usage_info() {
  get_mount_point_info;
  get_usage_info;

  local point;
  local DISK_TOTAL_INFO;
  local DISK_FREE_INFO;
  local DISK_USAGE_INFO;
  local DISK_PERCENT_INFO;

  local INODE_TOTAL_INFO;
  local INODE_FREE_INFO;
  local INODE_USAGE_INFO;
  local INODE_PERCENT_INFO;

  echo "启动时间：${START_TIME}";
  echo "运行时间：${RUNNING_TIME}";
  echo "系统负载（1 分钟）：${SYS_LOAD_IN_1_MIN}";
  echo "系统负载（5 分钟）：${SYS_LOAD_IN_5_MIN}";
  echo "系统负载（15 分钟）：${SYS_LOAD_IN_15_MIN}";
  echo "CPU 使用率：${CPU_USAGE_INFO}";
  echo "总内存大小：${TOTAL_MEM_INFO}";
  echo "空闲内存大小：${FREE_MEM_INFO}";
  echo "内存使用率：${MEM_USAGE_INFO}";
  echo "交换内存大小：${TOTAL_SWAP_INFO}";
  echo "空闲交换内存大小：${FREE_SWAP_INFO}";
  echo "交换内存使用率：${SWAP_MEM_INFO}";
  for point in "${MOUNT_POINT_ARRAY[@]}"; do
    if [[ "$point" != "none" ]]; then
      DISK_TOTAL_INFO=$(df -h "${point}" | awk 'NR==2 {print $2}');
      DISK_FREE_INFO=$(df -h "${point}" | awk 'NR==2 {print $4}');
      DISK_USAGE_INFO=$(df -h "${point}" | awk 'NR==2 {print $3}');
      DISK_PERCENT_INFO=$(df -h "${point}" | awk 'NR==2 {print $5}');
      INODE_TOTAL_INFO=$(df -i "${point}" | awk 'NR==2 {print $2}');
      INODE_FREE_INFO=$(df -i "${point}" | awk 'NR==2 {print $4}');
      INODE_USAGE_INFO=$(df -i "${point}" | awk 'NR==2 {print $3}');
      INODE_PERCENT_INFO=$(df -i "${point}" | awk 'NR==2 {print $5}');
      echo "挂载点 ${point} 的总量为： ${DISK_TOTAL_INFO}";
      echo "挂载点 ${point} 的剩余量为： ${DISK_FREE_INFO}";
      echo "挂载点 ${point} 的使用量为： ${DISK_USAGE_INFO}";
      echo "挂载点 ${point} 的使用率为： ${DISK_PERCENT_INFO}";
      echo "挂载点 ${point} 的 inode 总量为： ${INODE_TOTAL_INFO}";
      echo "挂载点 ${point} 的 inode 剩余量为： ${INODE_FREE_INFO}";
      echo "挂载点 ${point} 的 inode 使用量为： ${INODE_USAGE_INFO}";
      echo "挂载点 ${point} 的 inode 使用率为： ${INODE_PERCENT_INFO}";
    fi
  done
}

function get_service_info() {
  : << EOF
  - [ ] CPU 占用前 10 进程
  - [ ] 内存占用前 10 进程
  - [ ] 定时任务列表
  - [ ] Systemd 服务列表
EOF
}

function server_port_info() {
  : << EOF
  - [ ] 端口占用情况
  - [ ] TCP 连接状态
EOF
}


function main() {
  export LANG="en_US.UTF-8";
  local timestamp;
  timestamp=$(date +"%Y-%m-%d%H:%M:%S");

  check_dependencies;

  # unit test
  # Succeed:
  #  - test_get_os_info
  #  - test_check_dependencies
  #  - test_get_usage_info


  # test_get_os_info;
  # test_check_dependencies;
  # test_get_usage_info;
}

main "$@"