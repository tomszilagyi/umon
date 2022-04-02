#!/bin/sh

NAME=ping

test -n "$1" || exit 1
FUNC="$1"
shift

test -n "$1" || exit 1
HOST=$1

sample() {

if ! test -d "${RRDFILES}" ; then
    echo "ERROR: Directory for RRD files does not exist: ${RRDFILES}"
    exit 1
fi

RRDFILE="${RRDFILES}/${NAME}-${HOST}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    ${RRDTOOL} create ${RRDFILE} \
        --step ${COLLECT_STEP} \
        DS:ds0:GAUGE:600:U:U \
        DS:ds1:GAUGE:600:U:U \
        ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} N:0.123:44.7

}

graph() {

IMAGE="${IMAGES}/${NAME}-${HOST}.png"
RRDFILE="${RRDFILES}/${NAME}-${HOST}.rrd"
${RRDTOOL} graph ${IMAGE} ${RRD_GRAPH_ARGS} \
        --title "${HOST} - Ping" \
        --vertical-label "Roundtrip" \
        --watermark "${WATERMARK}" \
        DEF:CPU=${RRDFILE}:ds0:AVERAGE \
        AREA:CPU#FFCC0080 \
        LINE2:CPU#CC0033:"CPU" \
        GPRINT:CPU:MAX:"Max\:%5.1lf %s" \
        GPRINT:CPU:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:CPU:LAST:" Current\:%5.1lf %s"
}

cd $(dirname $0)
. ./common.sh
