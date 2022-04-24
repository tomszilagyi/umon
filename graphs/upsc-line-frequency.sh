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

color3=$(echo ${STACK_COLORS} | cut -d: -f3)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "UPS ${ups}: Line frequency" \
        --vertical-label "Hertz" \
        --watermark "${WATERMARK}" \
        --lower-limit 49.5 --upper-limit 50.5 --rigid \
        --left-axis-format "%4.1lf" --units-length 3 \
        --tabwidth 60 \
        COMMENT:"\t  Maximum  Average  Current\n" \
        DEF:IN=${RRDFILE}:input_frequency:AVERAGE \
        LINE2:IN#${color3}:"Input\t" \
        GPRINT:IN:MAX:"%6.1lf%s" \
        GPRINT:IN:AVERAGE:"%6.1lf%s" \
        GPRINT:IN:LAST:"%6.1lf%s\n"
