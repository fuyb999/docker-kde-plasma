#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

IDEA_CONFIG_DIR=${HOME}/.config/JetBrains/IntelliJIdea${IDEA_VERSION:0:6}

#if [ ! -d "${IDEA_CONFIG_DIR}" ] || [ -z "${EXTERNAL_TOOLS_JSON}" ]; then
#  exit 0
#fi

CONFIG_FILE="${IDEA_CONFIG_DIR}/tools/External Tools.xml"

# 确保目录存在
mkdir -p "$(dirname "$CONFIG_FILE")"

# 创建基础结构
cat > "$CONFIG_FILE" << EOF
<toolSet name="External Tools">
</toolSet>
EOF

# 转义 XML 特殊字符
escape_xml() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# 添加单个 tool
add_single_tool() {
    local name="$1"
    local description="$2"
    local command="$3"
    local parameters="$4"

    # 转义 XML 特殊字符
    name=$(escape_xml "$name")
    description=$(escape_xml "$description")
    command=$(escape_xml "$command")
    parameters=$(escape_xml "$parameters")

    # 创建临时文件
    local temp_file=$(mktemp)

    # 使用 awk 在 </toolSet> 前插入新的 tool
    awk -v name="$name" \
        -v description="$description" \
        -v command="$command" \
        -v parameters="$parameters" '
    /<\/toolSet>/ {
        print "  <tool name=\"" name "\" description=\"" description "\" showInMainMenu=\"false\" showInEditor=\"false\" showInProject=\"false\" showInSearchPopup=\"false\" disabled=\"false\" useConsole=\"false\" showConsoleOnStdOut=\"false\" showConsoleOnStdErr=\"false\" synchronizeAfterRun=\"true\">"
        print "    <exec>"
        print "      <option name=\"COMMAND\" value=\"" command "\" />"
        print "      <option name=\"PARAMETERS\" value=\"" parameters "\" />"
        print "      <option name=\"WORKING_DIRECTORY\" value=\"\$ProjectFileDir\$\" />"
        print "    </exec>"
        print "  </tool>"
        print ""
    }
    { print }
    ' "$CONFIG_FILE" > "$temp_file"

    # 替换原文件
    if mv "$temp_file" "$CONFIG_FILE" 2>/dev/null; then
        echo "成功添加工具: $1"
        return 0
    else
        echo "添加工具失败: $1"
        return 1
    fi
}

# 解析 JSON 格式的配置
parse_json_config() {
    local json_config="$1"

    # 检查是否安装了 jq
    if ! command -v jq &> /dev/null; then
        log_error "请安装 jq 工具来解析 JSON 配置: sudo apt-get install jq"
        return 1
    fi

    # 解析 JSON
    local tool_count=$(echo "$json_config" | jq length)

    for ((i=0; i<tool_count; i++)); do
        local name=$(echo "$json_config" | jq -r ".[$i].name")
        local description=$(echo "$json_config" | jq -r ".[$i].description")
        local command=$(echo "$json_config" | jq -r ".[$i].command")
        local parameters=$(echo "$json_config" | jq -r ".[$i].parameters")

        if [ "$name" != "null" ] && [ "$description" != "null" ] && [ "$command" != "null" ]; then
            add_single_tool "$name" "$description" "$command" "$parameters"
        else
            log_error "JSON 配置格式错误: 索引 $i"
        fi
    done
}

parse_json_config "${EXTERNAL_TOOLS_JSON}"

sleep 100

# vim:ft=sh:ts=4:sw=4:et:sts=4