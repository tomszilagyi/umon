#!/bin/sh

cat <<EOF
<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<title>$(hostname) | uMon</title>
</head>

<body bgcolor="#e0f0e7">
<center>
<h2>$(hostname)</h2>
<h4>$(uname -mrsv)</h4>
<h4>$(uptime | cut -d' ' -f 2-)</h4>
<p>$(date "+%Y-%m-%d %H:%M:%S %Z")</p>
<p><img src="/graph/load"></p>
<p><img src="/graph/cpu"></p>
<p><img src="/graph/if-pkts/ens3"></p>
<p><img src="/graph/if-xfer/ens3"></p>
<p><img src="/graph/if-pkts/lo"></p>
<p><img src="/graph/if-xfer/lo"></p>
</center>
</body>
</html>
EOF
