#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

if [ -z $1 ]
then
    echo "$0: error: missing interface name" >&2
    exit
fi

interface=$1
shift

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: interface=${interface} TIMESPAN=${TIMESPAN} >&2

inst=if-${interface}
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
        --title "Packets on ${interface}" \
        --vertical-label "Packets per Second" \
        --watermark "${WATERMARK}" \
        --tabwidth 60 \
        COMMENT:"\t  Maximum  Average  Current\n" \
        DEF:IN=${RRDFILE}:rxpkts:AVERAGE \
        DEF:OUT=${RRDFILE}:txpkts:AVERAGE \
        CDEF:IN_NEG="IN,-1,*" \
        LINE:OUT#${color3}:"Out (TX)\t" \
        AREA:OUT#${color3}50 \
        GPRINT:OUT:MAX:"%6.1lf%s" \
        GPRINT:OUT:AVERAGE:"%6.1lf%s" \
        GPRINT:OUT:LAST:"%6.1lf%s\n" \
        HRULE:0#808080 \
        LINE:IN_NEG#${color4}:" In (RX)\t" \
        AREA:IN_NEG#${color4}50 \
        GPRINT:IN:MAX:"%6.1lf%s" \
        GPRINT:IN:AVERAGE:"%6.1lf%s" \
        GPRINT:IN:LAST:"%6.1lf%s\n"
