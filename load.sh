#!/bin/sh

NAME=load

test -n "$1" || exit 1
FUNC="$1"
shift

test -n "$1" || exit 1
HOST="$1"

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
        DS:ds2:GAUGE:600:U:U \
        ${RRA_CREATE_ARGS}
fi

# TODO FIXME we do not get this from SNMP, so ${HOST} does not take effect!

LOAD=$(sysctl vm.loadavg | cut -d= -f2)
LA1=$(echo ${LOAD} | cut -d' ' -f1)
LA5=$(echo ${LOAD} | cut -d' ' -f2)
LA15=$(echo ${LOAD} | cut -d' ' -f3)

${RRDTOOL} update ${RRDFILE} N:${LA1}:${LA5}:${LA15}

}

graph() {

IMAGE="${IMAGES}/load-${HOST}.png"
RRDFILE="${RRDFILES}/${NAME}-${HOST}.rrd"
${RRDTOOL} graph ${IMAGE} ${RRD_GRAPH_ARGS} \
        --title "${HOST} - load" \
        --vertical-label "Load average" \
        --watermark "${WATERMARK}" \
        DEF:LA1=${RRDFILE}:ds0:AVERAGE \
        DEF:LA5=${RRDFILE}:ds1:AVERAGE \
        DEF:LA15=${RRDFILE}:ds2:AVERAGE \
        LINE2:LA1#7EB26D:" 1m" \
        GPRINT:LA1:MAX:"Max\:%5.1lf %s" \
        GPRINT:LA1:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:LA1:LAST:" Current\:%5.1lf %s\n" \
        LINE2:LA5#EAB839:" 5m" \
        GPRINT:LA5:MAX:"Max\:%5.1lf %s" \
        GPRINT:LA5:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:LA5:LAST:" Current\:%5.1lf %s\n" \
        LINE2:LA15#6ED0E0:"15m" \
        GPRINT:LA15:MAX:"Max\:%5.1lf %s" \
        GPRINT:LA15:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:LA15:LAST:" Current\:%5.1lf %s\n"
}

cd $(dirname $0)
. ./common.sh
