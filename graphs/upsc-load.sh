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

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "UPS ${ups}: Load percentage" \
        --vertical-label "% Capacity" \
        --watermark "${WATERMARK}" \
        --y-grid 1:1 \
        --tabwidth 60 \
        COMMENT:"\t  Maximum  Average  Current\n" \
        DEF:load=${RRDFILE}:ups_load:AVERAGE \
        LINE:load#${color1}:"Load\t" \
        AREA:load#${color1}50 \
        GPRINT:load:MAX:"%6.1lf%s" \
        GPRINT:load:AVERAGE:"%6.1lf%s" \
        GPRINT:load:LAST:"%6.1lf%s\n"
