#!/bin/sh

cd $(dirname $0)/..
exec fcgi/umon_fcgi 2>/dev/null
