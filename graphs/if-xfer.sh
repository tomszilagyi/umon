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

inst=if-$interface
RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Transfer on ${interface}" \
        --vertical-label "Bits per Second" \
        --watermark "${WATERMARK}" \
        DEF:IN=${RRDFILE}:rxbytes:AVERAGE \
        DEF:OUT=${RRDFILE}:txbytes:AVERAGE \
        CDEF:IN_CDEF="IN,8,*" \
        CDEF:IN_CDEFGR="IN,-8,*" \
        CDEF:OUT_CDEF="OUT,8,*" \
        LINE:OUT_CDEF#00A000:"Out (TX)" \
        AREA:OUT_CDEF#00A00050 \
        GPRINT:OUT_CDEF:MAX:"Max\:%6.1lf%s" \
        GPRINT:OUT_CDEF:AVERAGE:"Average\:%6.1lf%s" \
        GPRINT:OUT_CDEF:LAST:" Current\:%6.1lf%s\n" \
        HRULE:0#808080 \
        LINE:IN_CDEFGR#0000C0:" In (RX)" \
        AREA:IN_CDEFGR#0000C050 \
        GPRINT:IN_CDEF:MAX:"Max\:%6.1lf%s" \
        GPRINT:IN_CDEF:AVERAGE:"Average\:%6.1lf%s" \
        GPRINT:IN_CDEF:LAST:" Current\:%6.1lf%s\n"
