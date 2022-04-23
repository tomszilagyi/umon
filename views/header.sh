#!/bin/sh

cat <<EOF
<h1>$(hostname)</h1>
<h3>
$(uname -mrsv)</br>
$(uptime | cut -d' ' -f 3-)
</h3>
<p>$(date "+%Y-%m-%d %H:%M:%S %Z")</p>

<div id="graphs">
EOF
