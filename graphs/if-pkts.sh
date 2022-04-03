#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

if [ -z $1 ]
then
    echo "$0: error: missing interface name"
    exit
fi

interface=$1
shift

echo $0: interface=$interface

inst=if-$interface
RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}"
    echo "Has the probe run yet?"
    exit 1
fi

IMAGE="${IMAGES}/if-pkts-${interface}.png"
exec ${RRDTOOL} graph ${IMAGE} ${RRD_GRAPH_ARGS} \
        --title "Packets on ${interface}" \
        --vertical-label "Packets per Second" \
        --watermark "${WATERMARK}" \
        DEF:IN=${RRDFILE}:rxpkts:AVERAGE \
        DEF:OUT=${RRDFILE}:txpkts:AVERAGE \
        CDEF:IN_NEG="IN,-1,*" \
        LINE2:OUT#00AA00:"Out (TX)" \
        AREA:OUT#00AA0040 \
        GPRINT:OUT:MAX:"Max\:%5.1lf %s" \
        GPRINT:OUT:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:OUT:LAST:" Current\:%5.1lf %s\n" \
        HRULE:0#808080 \
        LINE2:IN_NEG#0000CC:" In (RX)" \
        AREA:IN_NEG#0000CC40 \
        GPRINT:IN:MAX:"Max\:%5.1lf %s" \
        GPRINT:IN:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:IN:LAST:" Current\:%5.1lf %s\n"
