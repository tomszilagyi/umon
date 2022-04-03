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

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Load averages" \
        --vertical-label "Load average" \
        --watermark "${WATERMARK}" \
        DEF:AVG1=${RRDFILE}:avg1:AVERAGE \
        DEF:AVG5=${RRDFILE}:avg5:AVERAGE \
        DEF:AVG15=${RRDFILE}:avg15:AVERAGE \
        LINE3:AVG15#0000ff:"15m" \
        AREA:AVG15#ffff8020 \
        GPRINT:AVG15:MAX:"Max\:%5.1lf %s" \
        GPRINT:AVG15:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:AVG15:LAST:" Current\:%5.1lf %s\n" \
        LINE2:AVG5#aa00cc:" 5m" \
        AREA:AVG5#ffff8020 \
        GPRINT:AVG5:MAX:"Max\:%5.1lf %s" \
        GPRINT:AVG5:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:AVG5:LAST:" Current\:%5.1lf %s\n" \
        LINE:AVG1#ff0000:" 1m" \
        AREA:AVG1#ffff8020 \
        GPRINT:AVG1:MAX:"Max\:%5.1lf %s" \
        GPRINT:AVG1:AVERAGE:"Average\:%5.1lf %s" \
        GPRINT:AVG1:LAST:" Current\:%5.1lf %s\n"
