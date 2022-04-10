#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

inst=vmstat
state=./probes/vmstat/$inst.env
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
        DEF:total=${RRDFILE}:total_memory:AVERAGE \
        LINE2:total#${color1}:"total   " \
        GPRINT:total:MAX:"Max\:%6.2lf%sB" \
        GPRINT:total:AVERAGE:"Average\:%6.2lf%sB" \
        GPRINT:total:LAST:"Current\:%6.2lf%sB\n" \
        DEF:free=${RRDFILE}:free_memory:AVERAGE \
        CDEF:free_neg=free,-1,* \
        AREA:free_neg#${color2}40:STACK \
        LINE:0#${color2}:"free    ":STACK \
        GPRINT:free:MAX:"Max\:%6.2lf%sB" \
        GPRINT:free:AVERAGE:"Average\:%6.2lf%sB" \
        GPRINT:free:LAST:"Current\:%6.2lf%sB\n" \
        DEF:active=${RRDFILE}:active_memory:AVERAGE \
        AREA:active#${color3}40 \
        LINE:active#${color3}:"active  " \
        GPRINT:active:MAX:"Max\:%6.2lf%sB" \
        GPRINT:active:AVERAGE:"Average\:%6.2lf%sB" \
        GPRINT:active:LAST:"Current\:%6.2lf%sB\n" \
        DEF:inactive=${RRDFILE}:inactive_memory:AVERAGE \
        AREA:inactive#${color4}40:STACK \
        LINE:0#${color4}:"inactive":STACK \
        GPRINT:inactive:MAX:"Max\:%6.2lf%sB" \
        GPRINT:inactive:AVERAGE:"Average\:%6.2lf%sB" \
        GPRINT:inactive:LAST:"Current\:%6.2lf%sB\n"
