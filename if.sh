#!/bin/sh

NAME=if

test -n "$1" || exit 1
FUNC="$1"
shift

test -n "$1" || exit 1
HOST="$1"
shift

test -n "$1" || exit 1
INTERFACE="$1"

sample() {

if ! test -d "${RRDFILES}" ; then
    echo "ERROR: Directory for RRD files does not exist: ${RRDFILES}"
    exit 1
fi

RRDFILE="${RRDFILES}/${NAME}-${HOST}-${INTERFACE}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    ${RRDTOOL} create ${RRDFILE} \
        --step ${COLLECT_STEP} \
        DS:ds0:COUNTER:600:0:1250000000 \
        DS:ds1:COUNTER:600:0:1250000000 \
        ${RRA_CREATE_ARGS}
fi

IN=$(snmp get -v 2c -c ${COMMUNITY} ${HOST} ifHCInOctets.${INTERFACE} | cut -d: -f2 | tr -d ' ')
OUT=$(snmp get -v 2c -c ${COMMUNITY} ${HOST} ifHCOutOctets.${INTERFACE} | cut -d: -f2 | tr -d ' ')

${RRDTOOL} update ${RRDFILE} N:${IN}:${OUT}

}

graph() {

DESCR=$(snmp get -v 2c -c ${COMMUNITY} ${HOST} ifDescr.${INTERFACE} | cut -d: -f2 | tr -d ' ')

IMAGE="${IMAGES}/${NAME}-${HOST}-${INTERFACE}.png"
RRDFILE="${RRDFILES}/${NAME}-${HOST}-${INTERFACE}.rrd"
${RRDTOOL} graph ${IMAGE} ${RRD_GRAPH_ARGS} \
        --title "${HOST}: Transfer on ${DESCR}" \
        --vertical-label "Bits per Second" \
        --watermark "${WATERMARK}" \
        DEF:IN=${RRDFILE}:ds0:AVERAGE \
        DEF:OUT=${RRDFILE}:ds1:AVERAGE \
        CDEF:IN_CDEF="IN,8,*" \
        CDEF:IN_CDEFGR="IN,-8,*" \
        CDEF:OUT_CDEF="OUT,8,*" \
        LINE2:OUT_CDEF#00AA00:"Out (TX)" \
        AREA:OUT_CDEF#00AA0060 \
        GPRINT:OUT_CDEF:MAX:"Max\:%5.1lf %s" \
        GPRINT:OUT_CDEF:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:OUT_CDEF:LAST:" Current\:%5.1lf %s\n" \
        HRULE:0#808080 \
        LINE2:IN_CDEFGR#0000CC:" In (RX)" \
        AREA:IN_CDEFGR#0000CC60 \
        GPRINT:IN_CDEF:MAX:"Max\:%5.1lf %s" \
        GPRINT:IN_CDEF:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:IN_CDEF:LAST:" Current\:%5.1lf %s\n"
}

cd $(dirname $0)
. ./common.sh
