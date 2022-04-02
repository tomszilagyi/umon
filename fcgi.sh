#!/bin/sh

# To understand what is going on here, read this:
# https://fastcgi-archives.github.io/FastCGI_Specification.html

# N.B.: We do not care about the request. We know what it is.

cd $(dirname $0)
. ./params.sh

# Generate the graphs and the index page (our dashboard).
./graph.sh 2>&1 >/dev/null

# {FCGI_STDOUT, 1, "Content-type: text/html\r\n\r\n"}
printf '\x01\x06\x00\x01\x00\x1b\x00\x00'
printf 'Content-type: text/html\r\n\r\n'

# {FCGI_STDOUT, 1, <<file content>>}
FILE=${IMAGES}/index.html
SIZE=$(stat -f %z ${FILE})
SH=$(printf "%04x\n" ${SIZE} | cut -c -2)
SL=$(printf "%04x\n" ${SIZE} | cut -c 3-)
printf "\x01\x06\x00\x01\x${SH}\x${SL}\x00\x00"
cat ${FILE}

# {FCGI_STDOUT, 1, ""}
printf '\x01\x06\x00\x01\x00\x00\x00\x00'

# {FCGI_EndRequest, 1, {0, FCGI_REQUEST_COMPLETE}}
printf '\x01\x03\x00\x01\x00\x08\x00\x00'
printf '\x00\x00\x00\x00\x00\x00\x00\x00'
