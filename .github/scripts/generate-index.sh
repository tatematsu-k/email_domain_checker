#!/bin/bash
set -euo pipefail

# Generate version list
VERSION_LIST=""
[[ -d "latest" ]] && VERSION_LIST+='                      <li><a href="latest/"><span class="version-label">Latest</span><span class="latest-badge">Current</span></a></li>'$'\n'

for dir in $(ls -d v*/ 2>/dev/null | sort -Vr); do
    [[ -d "$dir" ]] && VERSION_LIST+="                      <li><a href=\"$(basename "$dir")/\">$(basename "$dir")</a></li>"$'\n'
done

# Replace placeholder in template
sed "s|{{VERSION_LIST}}|$VERSION_LIST|" docs-templates/index.html > index.html

echo "Generated index.html"
