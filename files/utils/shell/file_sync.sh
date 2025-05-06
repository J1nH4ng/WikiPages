#!/bin/bash
set -euo pipefail
#
# Description: file sync script
# Author: J1nH4ng<j1nh4ng@icloud.com>
# Date: 2025-01-14
# Version: V1.0.2.20250506_release_security
# Copyright 2025 © Team 4r3al. All rights reserved.

function check_dependencies() {
  : << EOF
  - [x] md5sum
  - [x] rsync
EOF

  declare -A pag_map_redhat=(
    ["md5sum"]="coreutils"
    ["rsync"]="rsync"
  );

  local cmd=();

  cmd=("md5sum" "rsync");

  for cmd in "${cmd[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "Error: ${cmd} 未安装, ${pag_map_redhat[$cmd]} 将会被安装"
      yum install "${pag_map_redhat[$cmd]}" -y
    fi
  done
}


function check_remote_dir_hash() {
  local remote_user=${1:-root}
  local remote_host=${2:?need_remote_host}
  local remote_port=${3:-22}

  local rsync_dir=${4:?need_rsync_dir}

  local local_dir_hash
  local remote_dir_hash

  HAVE_SAME_HASH=0

  local_dir_hash=$(find "${rsync_dir}" -type f -exec md5sum {} \; | tr -d '\r' | md5sum | awk '{print $1}')
  remote_dir_hash=$(ssh -p "${remote_port}" "${remote_user}"@"${remote_host}" "find \"${rsync_dir}\" -type f -exec md5sum {} \; | tr -d '\r' | md5sum | awk '{print \$1}'" | awk '{print $1}')

  echo "Info: 本地目录的哈希值: ${local_dir_hash}"
  echo "Info: 远程目录的哈希值: ${remote_dir_hash}"

  if [ "${local_dir_hash}" == "${remote_dir_hash}" ]; then
    echo "Info: 本地和远程目录的哈希值相同，跳过同步"
    HAVE_SAME_HASH=0
  else
    echo "Error: 本地和远程目录的哈希值不同，同步服务将会开始运行"
    HAVE_SAME_HASH=1
  fi

  export HAVE_SAME_HASH
}

function sync_files() {
  local remote_user=${1:-root}
  local remote_host=${2:?need_remote_host}
  local remote_port=${3:-22}

  local rsync_dir=${4:?need_rsync_dir}

  rsync -avz -e "ssh -p ${remote_port}" --delete "${rsync_dir}" "${remote_user}"@"${remote_host}":"${rsync_dir}"
}

function main() {
  check_dependencies

  local remote_user
  local remote_host
  local remote_port
  local rsync_dir

  read -rp "请输入远程主机用户名: " remote_user
  read -rp "请输入远程主机地址: " remote_host
  read -rp "请输入远程主机端口(默认22): " remote_port
  read -rp "请输入需要同步的目录: " rsync_dir

  if [[ "${rsync_dir}" != */ ]]; then
    rsync_dir="${rsync_dir}/"
  fi

  check_remote_dir_hash "${remote_user}" "${remote_host}" "${remote_port}" "${rsync_dir}"

  if [ "$HAVE_SAME_HASH" -eq 1 ]; then
    sync_files "${remote_user}" "${remote_host}" "${remote_port}" "${rsync_dir}"
  else
    exit 0
  fi
}

main "$@"