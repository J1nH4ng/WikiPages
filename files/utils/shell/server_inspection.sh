#!/bin/bash
#
# Description: server inspection script
# Author: J1nH4ng<j1nh4ng@icloud.com>
# Date: 2025-04-27
# Version: V0.0.1.20250427_develop
# Copyright 2025 © Team 4r3al. All rights reserved.

function check_dependencies() {
  : << EOF
  - [ ] lspci
EOF
}

function get_os_info() {
  : << EOF
  - [x] 硬件型号
  - [x] CPU 架构
  - [x] CPU 型号
  - [x] CPU 内核数
  - [x] CPU 线程数
  - [x] 内存大小
  - [ ] 磁盘信息
  - [x] 网卡信息
  - [x] 操作系统版本
  - [ ] 内核版本
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

  # show network interface name
  local NETWORK_INTERFACE_NAME;
  NETWORK_INTERFACE_NAME=$(lspci -k | grep "Ethernet controller" -m 1 -A 3 | awk -F: '/Ethernet controller/ {print $3}');

  # show network interface subsystem
  local NETWORK_INTERFACE_SUBSYSTEM;
  NETWORK_INTERFACE_SUBSYSTEM=$(lspci -k | grep "Ethernet controller" -m 1 -A 3 | awk -F: '/Subsystem/ {print $2}');
}

function test_get_os_info() {
  get_os_info
}

function main() {
  export LANG="en_US.UTF-8";
  # unit test
  test_get_os_info
}

main "$@"