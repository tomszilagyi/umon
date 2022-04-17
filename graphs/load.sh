#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

inst=load

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

color1=$(echo ${STACK_COLORS} | cut -d: -f1)
color2=$(echo ${STACK_COLORS} | cut -d: -f2)
color3=$(echo ${STACK_COLORS} | cut -d: -f3)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Load averages" \
        --vertical-label "Load average" \
        --watermark "${WATERMARK}" \
        --lower-limit 0 \
        --tabwidth 60 \
        COMMENT:"\t Maximum  Average Current\n" \
        DEF:AVG1=${RRDFILE}:avg1:AVERAGE \
        DEF:AVG5=${RRDFILE}:avg5:AVERAGE \
        DEF:AVG15=${RRDFILE}:avg15:AVERAGE \
        LINE3:AVG15#${color3}:"15m\t" \
        AREA:AVG15#ffff8020 \
        GPRINT:AVG15:MAX:"%6.1lf" \
        GPRINT:AVG15:AVERAGE:"%6.1lf" \
        GPRINT:AVG15:LAST:"%6.1lf\n" \
        LINE2:AVG5#${color2}:" 5m\t" \
        AREA:AVG5#ffff8020 \
        GPRINT:AVG5:MAX:"%6.1lf" \
        GPRINT:AVG5:AVERAGE:"%6.1lf" \
        GPRINT:AVG5:LAST:"%6.1lf\n" \
        LINE:AVG1#${color1}:" 1m\t" \
        AREA:AVG1#ffff8020 \
        GPRINT:AVG1:MAX:"%6.1lf" \
        GPRINT:AVG1:AVERAGE:"%6.1lf" \
        GPRINT:AVG1:LAST:"%6.1lf\n"
