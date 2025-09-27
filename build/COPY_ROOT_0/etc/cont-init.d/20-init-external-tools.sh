#!/bin/bash
#
# Generate and save a UUID to a path that is persistent to container restarts,
# but not to re-creations.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

source /opt/ai-dock/etc/environment.sh

IDEA_CONFIG_DIR=${HOME}/.config/JetBrains/IntelliJIdea${IDEA_VERSION:0:6}

if [ ! -d "${IDEA_CONFIG_DIR}" ] || [ -z "${EXTERNAL_TOOLS_JSON}" ]; then
  exit 0
fi

CONFIG_FILE="${IDEA_CONFIG_DIR}/tools/External Tools.xml"

# Ensure directory exists
mkdir -p "$(dirname "$CONFIG_FILE")"

# Create basic structure
cat > "$CONFIG_FILE" << EOF
<toolSet name="External Tools">
</toolSet>
EOF

# Escape XML special characters
escape_xml() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# Add single tool
add_single_tool() {
    local name="$1"
    local description="$2"
    local command="$3"
    local parameters="$4"

    # Escape XML special characters
    name=$(escape_xml "$name")
    description=$(escape_xml "$description")
    command=$(escape_xml "$command")
    parameters=$(escape_xml "$parameters")

    # Create temporary file
    local temp_file=$(mktemp)

    # Use awk to insert new tool before </toolSet>
    awk -v name="$name" \
        -v description="$description" \
        -v command="$command" \
        -v parameters="$parameters" '
    /<\/toolSet>/ {
        print "  <tool name=\"" name "\" description=\"" description "\" showInMainMenu=\"false\" showInEditor=\"false\" showInProject=\"false\" showInSearchPopup=\"false\" disabled=\"false\" useConsole=\"false\" showConsoleOnStdOut=\"false\" showConsoleOnStdErr=\"false\" synchronizeAfterRun=\"true\">"
        print "    <exec>"
        print "      <option name=\"COMMAND\" value=\"" command "\" />"
        print "      <option name=\"PARAMETERS\" value=\"" parameters "\" />"
        print "      <option name=\"WORKING_DIRECTORY\" value=\"$ProjectFileDir$\" />"
        print "    </exec>"
        print "  </tool>"
        print ""
    }
    { print }
    ' "$CONFIG_FILE" > "$temp_file"

    # Replace original file
    if mv "$temp_file" "$CONFIG_FILE" 2>/dev/null; then
        echo "Successfully added tool: $1"
        return 0
    else
        echo "Failed to add tool: $1"
        return 1
    fi
}

# Parse JSON configuration
parse_json_config() {
    local json_config="$1"

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Please install jq tool to parse JSON configuration: sudo apt-get install jq"
        return 1
    fi

    # Parse JSON
    local tool_count=$(echo "$json_config" | jq length)

    for ((i=0; i<tool_count; i++)); do
        local name=$(echo "$json_config" | jq -r ".[$i].name")
        local description=$(echo "$json_config" | jq -r ".[$i].description")
        local command=$(echo "$json_config" | jq -r ".[$i].command")
        local parameters=$(echo "$json_config" | jq -r ".[$i].parameters")

        if [ "$name" != "null" ] && [ "$description" != "null" ] && [ "$command" != "null" ]; then
            add_single_tool "$name" "$description" "$command" "$parameters"
        else
            echo "JSON configuration format error: index $i"
        fi
    done
}

parse_json_config "${EXTERNAL_TOOLS_JSON}"

# vim:ft=sh:ts=4:sw=4:et:sts=4