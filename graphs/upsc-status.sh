#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

if [ -z $1 ]
then
    echo "$0: error: missing ups name" >&2
    exit
fi

ups=$1
shift

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: ups=${ups} TIMESPAN=${TIMESPAN} >&2

inst=upsc-${ups}
RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

color1=$(echo ${STACK_COLORS} | cut -d: -f1)
color3=$(echo ${STACK_COLORS} | cut -d: -f3)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "UPS ${ups}: Power source" \
        --watermark "${WATERMARK}" \
        --lower-limit 0 --upper-limit 1 --rigid \
        --y-grid 1:1 --units-length 5 \
        --tabwidth 60 \
        DEF:on_battery=${RRDFILE}:on_battery:AVERAGE \
        CDEF:battery=on_battery,UN,0,on_battery,IF,0.5,LT,0,1,IF \
        CDEF:line=on_battery,0.5,LT,1,0,IF \
        LINE:line#${color3}:"Line\n" \
        AREA:line#${color3}50 \
        LINE:battery#${color1}:"Battery" \
        AREA:battery#${color1}50
