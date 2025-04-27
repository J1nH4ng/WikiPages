#!/bin/bash
#
# Description: server inspection script
# Author: J1nH4ng<j1nh4ng@icloud.com>
# Date: 2025-04-27
# Version: V0.0.2.20250427_develop
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
  - [x] lshw
EOF

  local pag_map_redhat;

  declare -A pag_map_redhat=(
    ["lspci"]="pciutils"
    ["curl"]="curl"
    ["dmidecode"]="dmidecode"
    ["bc"]="bc"
  );

  local cmd;

  for cmd in "${!pag_map_redhat[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      yum install "${pag_map_redhat[$cmd]}" -y
    fi
  done
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
  local SYSTEM_PRODUCT;
  SYSTEM_PRODUCT=$(dmidecode -s system-product-name);

  # show CPU architecture
  local CPU_ARCHITECTURE;
  CPU_ARCHITECTURE=$(uname -m);

  # show CPU name
  local CPU_NANE;
  CPU_NANE=$(awk -F: '/model name/ {print $2}' /proc/cpuinfo | uniq);

  # show physical CPU members
  local PHYSICAL_CPU_MEMBERS;
  PHYSICAL_CPU_MEMBERS=$(awk -F: '/physical id/ {print $2}' /proc/cpuinfo | sort | uniq | wc -l);

  # show CPU cores
  local CPU_CORES;
  CPU_CORES=$(awk -F: '/cpu cores/ {print $2}' /proc/cpuinfo | uniq);

  # show PROCESSOR
  local PROCESSOR;
  PROCESSOR=$(awk -F: '/processor/ {print $2}' /proc/cpuinfo | uniq | wc -l);

  # show memory size
  local MEMORY_SIZE;
  MEMORY_SIZE=$(awk -F: '/MemTotal/ {print $2}' /proc/meminfo | awk '{print int($1/1048576 + 0.999999999), "GB"}');

  # show os-release
  local OS_RELEASE;
  OS_RELEASE=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2);

  # show linux kernel version
  local LINUX_KERNEL_VERSION;
  LINUX_KERNEL_VERSION=$(uname -r);

  # show network interface name
  local NETWORK_INTERFACE_NAME;
  NETWORK_INTERFACE_NAME=$(lspci -k | grep "Ethernet controller" -m 1 -A 3 | awk -F: '/Ethernet controller/ {print $3}');

  # show network interface subsystem
  local NETWORK_INTERFACE_SUBSYSTEM;
  NETWORK_INTERFACE_SUBSYSTEM=$(lspci -k | grep "Ethernet controller" -m 1 -A 3 | awk -F: '/Subsystem/ {print $2}');

  # show network interface
  local NETWORK_INTERFACE_IP;
  NETWORK_INTERFACE_IP=$(hostname -i)

  # show network interface MAC
  local NETWORK_INTERFACE_NICKNAME;
  local NETWORK_INTERFACE_MAC;
  NETWORK_INTERFACE_NICKNAME=$(ip -o addr show | grep "${NETWORK_INTERFACE_IP}" | awk 'print $2')
  NETWORK_INTERFACE_MAC=$(ip link show "${NETWORK_INTERFACE_NAME}" | awk '/link\/ether/ {print $2}')

  local DISK_INFO_ARRAY=();
  local DISK_INFO_ARRAY_WITH_TYPE=();
  local i;
  # chmod +x or bash
  mapfile -t DISK_INFO_ARRAY < <(lsblk -n -d -o NAME,SIZE,TYPE | grep "disk");
  for i in "${DISK_INFO_ARRAY[@]}"; do
    local DISK_NAME
    local DISK_SIZE
    local DISK_TYPE_CODE
    local DISK_TYPE
    DISK_NAME=$(echo "$i" | awk '{print $1}');
    DISK_SIZE=$(echo "$i" | awk '{print $2}');
    DISK_TYPE_CODE=$( < /sys/block/"${DISK_NAME}"/queue/rotational)
    if [ "$DISK_TYPE_CODE" -eq 0 ]; then
      DISK_TYPE="SSD";
    else
      DISK_TYPE="HDD";
    fi
    DISK_INFO_ARRAY_WITH_TYPE+=("${DISK_NAME} ${DISK_SIZE} ${DISK_TYPE}");
  done

  # export variables
  export SYSTEM_PRODUCT
  export CPU_ARCHITECTURE
  export CPU_NANE
  export PHYSICAL_CPU_MEMBERS
  export CPU_CORES
  export PROCESSOR
  export MEMORY_SIZE
  export OS_RELEASE
  export LINUX_KERNEL_VERSION
  export NETWORK_INTERFACE_NAME
  export NETWORK_INTERFACE_SUBSYSTEM
  export NETWORK_INTERFACE_IP
  export NETWORK_INTERFACE_NICKNAME
  export NETWORK_INTERFACE_MAC
  export DISK_INFO_ARRAY_WITH_TYPE;
}

function test_get_os_info() {
  get_os_info

  local i

  echo "服务器制造商： ${SYSTEM_PRODUCT}"
  echo "CPU架构： ${CPU_ARCHITECTURE}"
  echo "CPU型号： ${CPU_NANE}"
  echo "CPU 物理核心数： ${PHYSICAL_CPU_MEMBERS}"
  echo "CPU 逻辑核心数： ${CPU_CORES}"
  echo "CPU 线程数： ${PROCESSOR}"
  echo "内存大小： ${MEMORY_SIZE}"
  echo "操作系统版本： ${OS_RELEASE}"
  echo "内核版本： ${LINUX_KERNEL_VERSION}"
  echo "网卡制造商： ${NETWORK_INTERFACE_SUBSYSTEM}"
  echo "网卡型号： ${NETWORK_INTERFACE_NAME}"
  echo "网卡名称： ${NETWORK_INTERFACE_NICKNAME}"
  echo "网卡MAC地址： ${NETWORK_INTERFACE_MAC}"
  echo "网卡IP地址： ${NETWORK_INTERFACE_IP}"
  for i in "${DISK_INFO_ARRAY_WITH_TYPE[@]}"; do
    echo "磁盘名称： $(echo "$i" | awk '{print $1}')"
    echo "磁盘大小： $(echo "$i" | awk '{print $2}')"
    echo "磁盘类型： $(echo "$i" | awk '{print $3}')"
  done
}

function get_usage_info() {
  :
}

function main() {
  export LANG="en_US.UTF-8";
  local timestamp;
  timestamp=$(date +"%Y-%m-%d%H:%M:%S");

  # unit test
  test_get_os_info;
}

main "$@"