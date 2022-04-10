#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

inst=vmstat
state=./probes/vmstat/$inst.env
if [ ! -f $state ]
then
    echo "state not found, expected: ${state}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

. ${state}

SPEC=
j=0
for cnt in ${counters}; do
    color_idx=$((j % ${N_STACK_COLORS} + 1))
    color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})
    SPEC="${SPEC} \
          DEF:${cnt}=${RRDFILE}:${cnt}:AVERAGE \
          LINE:${cnt}#${color}:${cnt}\t \
          GPRINT:${cnt}:MAX:Max\:%8.2lf \
          GPRINT:${cnt}:AVERAGE:Average\:%8.2lf \
          GPRINT:${cnt}:LAST:Current\:%8.2lf\n \
         "
    j=$((j + 1))
done

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "vmstat events" \
        --vertical-label "Events per second" \
        --watermark "${WATERMARK}" \
        --logarithmic --units=si \
        ${SPEC}
