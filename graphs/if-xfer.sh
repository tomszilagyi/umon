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

IMAGE="${IMAGES}/if-xfer-${interface}.png"
exec ${RRDTOOL} graph ${IMAGE} ${RRD_GRAPH_ARGS} \
        --title "Transfer on ${interface}" \
        --vertical-label "Bits per Second" \
        --watermark "${WATERMARK}" \
        DEF:IN=${RRDFILE}:rxbytes:AVERAGE \
        DEF:OUT=${RRDFILE}:txbytes:AVERAGE \
        CDEF:IN_CDEF="IN,8,*" \
        CDEF:IN_CDEFGR="IN,-8,*" \
        CDEF:OUT_CDEF="OUT,8,*" \
        LINE2:OUT_CDEF#00AA00:"Out (TX)" \
        AREA:OUT_CDEF#00AA0040 \
        GPRINT:OUT_CDEF:MAX:"Max\:%5.1lf %s" \
        GPRINT:OUT_CDEF:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:OUT_CDEF:LAST:" Current\:%5.1lf %s\n" \
        HRULE:0#808080 \
        LINE2:IN_CDEFGR#0000CC:" In (RX)" \
        AREA:IN_CDEFGR#0000CC40 \
        GPRINT:IN_CDEF:MAX:"Max\:%5.1lf %s" \
        GPRINT:IN_CDEF:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:IN_CDEF:LAST:" Current\:%5.1lf %s\n"
