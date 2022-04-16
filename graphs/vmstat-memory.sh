#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

inst=vmstat
state=./probes/vmstat.env
if [ ! -f $state ]
then
    echo "state not found, expected: ${state}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

. ${state}

color1=$(echo ${STACK_COLORS} | cut -d: -f1)
color2=$(echo ${STACK_COLORS} | cut -d: -f2)
color3=$(echo ${STACK_COLORS} | cut -d: -f3)
color4=$(echo ${STACK_COLORS} | cut -d: -f4)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Memory usage" \
        --vertical-label "Memory (bytes)" \
        --watermark "${WATERMARK}" \
        --base 1024 --lower-limit 0 \
        --tabwidth 60 \
        COMMENT:"\t   Maximum    Average   Current\n" \
        DEF:total=${RRDFILE}:total_memory:AVERAGE \
        LINE2:total#${color1}:"total\t" \
        GPRINT:total:MAX:"%6.2lf%SB" \
        GPRINT:total:AVERAGE:"%6.2lf%SB" \
        GPRINT:total:LAST:"%6.2lf%SB\n" \
        DEF:free=${RRDFILE}:free_memory:AVERAGE \
        CDEF:free_neg=free,-1,* \
        AREA:free_neg#${color2}40:STACK \
        LINE:0#${color2}:"free\t":STACK \
        GPRINT:free:MAX:"%6.2lf%SB" \
        GPRINT:free:AVERAGE:"%6.2lf%SB" \
        GPRINT:free:LAST:"%6.2lf%SB\n" \
        DEF:active=${RRDFILE}:active_memory:AVERAGE \
        AREA:active#${color3}40 \
        LINE:active#${color3}:"active\t" \
        GPRINT:active:MAX:"%6.2lf%SB" \
        GPRINT:active:AVERAGE:"%6.2lf%SB" \
        GPRINT:active:LAST:"%6.2lf%SB\n" \
        DEF:inactive=${RRDFILE}:inactive_memory:AVERAGE \
        AREA:inactive#${color4}40:STACK \
        LINE:0#${color4}:"inactive\t":STACK \
        GPRINT:inactive:MAX:"%6.2lf%SB" \
        GPRINT:inactive:AVERAGE:"%6.2lf%SB" \
        GPRINT:inactive:LAST:"%6.2lf%SB\n"
