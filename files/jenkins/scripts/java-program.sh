#!/bin/bash
set -euo pipefail
#
# Description: jenkins script 4 java program
# Author: J1nH4ng<j1nh4ng@icloud.com>
# Date: 2025-05-13
# Version: V0.0.1.20250513_dev
# Copyright 2025 © Team 4r3al. All rights reserved.


function define_variable() {
  : << EOF
  定义使用的变量：
  - [ ] serverIP：需要发布应用的服务器 IP
  - [ ] releasesPath：需要发布的应用路径
  - [ ] contentsPath：需要发布的应用内容路径
EOF
  export serverIP
  export releasesPath
  export contentsPath

  serverIP="192.168.50.2,192.168.50.3"
  releasesPath="/data/releases"
  contentsPath="/data/contents"

  echo "应用将会发布至如下服务器：${serverIP}"
  echo "旧版本应用将会存储至如下路径：${releasesPath}"
  echo "新版本应用将会发布至如下路径：${contentsPath}"
}

function create_path() {
  : << EOF
  创建上述定义的路径

  ${JOB_NAME} 与 ${MODULE_NAME} 为 Jenkins 任务名称与模块名称，由 Jenkins 生成。
EOF

  ansible "${serverIP}" -m file -a "path=${releasesPath}/${JOB_NAME}/${MODULE_NAME} state=directory"
  ansible "${serverIP}" -m file -a "path=${contentsPath}/${JOB_NAME} state=directory"
}

function main() {
  :
}

main "$@"