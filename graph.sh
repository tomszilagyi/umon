#!/bin/sh

cd $(dirname $0)
. ./params.sh

./load.sh graph localhost
./cpu.sh graph localhost
./if.sh graph localhost 1
./if.sh graph localhost 3

(cat <<EOF
<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<title>$(hostname) | uMon</title>
</head>

<body bgcolor="#e0f0e7">
<center>
<h2>$(hostname)</h2>
<h4>$(uname -mrsv)</h4>
<h4>$(sysctl hw.model | cut -d= -f2)</h4>
<h4>$(uptime | cut -d' ' -f 2-)</h4>
<p>$(date "+%Y-%m-%d %H:%M:%S %Z")</p>
<p><img src="load-localhost.png"></p>
<p><img src="cpu-localhost.png"></p>
<p><img src="if-localhost-1.png"></p>
<p><img src="if-localhost-3.png"></p>
</center>
</body>
</html>
EOF
) > ${IMAGES}/index.html
