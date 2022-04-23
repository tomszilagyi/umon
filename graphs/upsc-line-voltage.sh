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
color4=$(echo ${STACK_COLORS} | cut -d: -f4)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "UPS ${ups}: Line voltage" \
        --vertical-label "Volts" \
        --watermark "${WATERMARK}" \
        --lower-limit 230 --upper-limit 240 --rigid \
        --tabwidth 60 \
        COMMENT:"\t  Maximum  Average  Current\n" \
        DEF:IN=${RRDFILE}:input_voltage:AVERAGE \
        DEF:OUT=${RRDFILE}:output_voltage:AVERAGE \
        LINE2:IN#${color3}:" Input\t" \
        GPRINT:IN:MAX:"%6.1lf%s" \
        GPRINT:IN:AVERAGE:"%6.1lf%s" \
        GPRINT:IN:LAST:"%6.1lf%s\n" \
        LINE:OUT#${color4}:"Output\t" \
        GPRINT:OUT:MAX:"%6.1lf%s" \
        GPRINT:OUT:AVERAGE:"%6.1lf%s" \
        GPRINT:OUT:LAST:"%6.1lf%s\n"
