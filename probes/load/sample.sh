#!/bin/sh

inst=$1
shift

echo $0: inst=$inst
. ./umon.conf

# N.B: take care, this must work alike on all supported platforms:
load=$(uptime | grep -o average.\* | cut -d: -f 2- | tr -d ',')

avg1=$(echo ${load} | cut -d' ' -f1)
avg5=$(echo ${load} | cut -d' ' -f2)
avg15=$(echo ${load} | cut -d' ' -f3)

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    ${RRDTOOL} create ${RRDFILE} \
        --step ${RRD_COLLECT_STEP} \
        DS:avg1:GAUGE:${RRD_HEARTBEAT}:U:U \
        DS:avg5:GAUGE:${RRD_HEARTBEAT}:U:U \
        DS:avg15:GAUGE:${RRD_HEARTBEAT}:U:U \
        ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} N:${avg1}:${avg5}:${avg15}
