#!/usr/bin/env bash
# docs/scripts/capture_terminal.sh - Professional Terminal Mockup Generator
# Usage: ./capture_terminal.sh "<command>" "<title>" "<output_file>.html"

set -euo pipefail

COMMAND="${1:-distrobox list}"
TITLE="${2:-DbxSmith Terminal}"
OUTPUT_FILE="${3:-docs/static/capture_output.html}"

# 1. Execute and capture output
echo "Executing: $COMMAND"
RAW_OUTPUT=$($COMMAND 2>&1)

# 2. Escape HTML special characters
ESCAPED_OUTPUT=$(echo "$RAW_OUTPUT" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

# 3. Generate HTML Template
cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html>
<head>
<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono\&display=swap');
body { 
    background: #1a1a1a; 
    color: #d4d4d4; 
    font-family: 'JetBrains Mono', monospace; 
    padding: 40px; 
    display: flex; 
    justify-content: center; 
    align-items: center; 
    min-height: 80vh; 
}
.terminal { 
    background: #1e1e1e; 
    border: 1px solid #444; 
    border-radius: 8px; 
    box-shadow: 0 20px 50px rgba(0,0,0,0.4); 
    width: 100%; 
    max-width: 900px; 
    overflow: hidden; 
}
.header { 
    background: #2d2d2d; 
    padding: 10px 15px; 
    display: flex; 
    align-items: center; 
    gap: 8px; 
    border-bottom: 1px solid #333; 
}
.dot { width: 12px; height: 12px; border-radius: 50%; }
.red { background: #ff5f56; } 
.yellow { background: #ffbd2e; } 
.green { background: #27c93f; }
.title { 
    color: #999; 
    font-size: 12px; 
    margin-left: 10px; 
    flex-grow: 1; 
    text-align: center; 
    margin-right: 50px; 
}
.content { 
    padding: 20px; 
    white-space: pre-wrap; 
    font-size: 13px; 
    line-height: 1.6; 
    color: #fff; 
}
.prompt { color: #4ec9b0; }
.path { color: #569cd6; }
.cmd { color: #ce9178; }
</style>
</head>
<body>
<div class="terminal">
<div class="header">
    <div class="dot red"></div>
    <div class="dot yellow"></div>
    <div class="dot green"></div>
    <div class="title">$TITLE</div>
</div>
<div class="content"><span class="prompt">ubuntu@dbx-smith</span>:<span class="path">~/dbx-smith</span>$ <span class="cmd">$COMMAND</span>
$ESCAPED_OUTPUT
</div>
</div>
</body>
</html>
EOF

echo "Success! Mockup generated at: $OUTPUT_FILE"
echo "To capture as image, open in browser and take a screenshot."
