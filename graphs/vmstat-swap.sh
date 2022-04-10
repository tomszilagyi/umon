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
color2=$(echo ${STACK_COLORS} | cut -d: -f3)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Swap usage" \
        --vertical-label "Swap (bytes)" \
        --watermark "${WATERMARK}" \
        --base 1024 --lower-limit 0 \
        DEF:total=${RRDFILE}:total_swap:AVERAGE \
        LINE2:total#${color1}:"total" \
        GPRINT:total:MAX:"Max\:%6.2lf%sB" \
        GPRINT:total:AVERAGE:"Average\:%6.2lf%sB" \
        GPRINT:total:LAST:"Current\:%6.2lf%sB\n" \
        DEF:used=${RRDFILE}:used_swap:AVERAGE \
        AREA:used#${color2}40 \
        LINE:used#${color2}:"used " \
        GPRINT:used:MAX:"Max\:%6.2lf%sB" \
        GPRINT:used:AVERAGE:"Average\:%6.2lf%sB" \
        GPRINT:used:LAST:"Current\:%6.2lf%sB\n"
