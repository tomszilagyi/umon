#!/bin/sh

cd $(dirname $0)/..

PORT=3333
LISTEN=127.0.0.1
socat TCP4-LISTEN:${PORT},bind=${LISTEN},reuseaddr,fork EXEC:fcgi/umon_fcgi
