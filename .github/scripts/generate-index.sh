#!/bin/bash
set -euo pipefail

# Configuration
TEMPLATE_FILE="${TEMPLATE_FILE:-docs-templates/index.html}"
OUTPUT_FILE="${OUTPUT_FILE:-index.html}"

# Functions
generate_version_list() {
    local version_list=""

    # Add latest if it exists
    if [[ -d "latest" ]]; then
        version_list+='                      <li><a href="latest/"><span class="version-label">Latest</span><span class="latest-badge">Current</span></a></li>'$'\n'
    fi

    # Add all version directories (sorted by version, newest first)
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            version=$(basename "$dir")
            version_list+="                      <li><a href=\"${version}/\">${version}</a></li>"$'\n'
        fi
    done < <(ls -d v*/ 2>/dev/null | sort -Vr || true)

    echo -n "$version_list"
}

# Validation
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file not found: $TEMPLATE_FILE" >&2
    exit 1
fi

# Generate version list
VERSION_LIST=$(generate_version_list)

# Replace placeholder in template
# Use a temporary file to avoid issues with special characters
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

if ! sed "s|{{VERSION_LIST}}|$VERSION_LIST|" "$TEMPLATE_FILE" > "$TEMP_FILE"; then
    echo "Error: Failed to process template" >&2
    exit 1
fi

# Move temp file to output
if ! mv "$TEMP_FILE" "$OUTPUT_FILE"; then
    echo "Error: Failed to write output file" >&2
    exit 1
fi

echo "Generated index.html successfully"
