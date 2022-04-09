#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

inst=cpu

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

state=./probes/cpu/$inst.env
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
while [ $j -lt ${nCores} ]; do
    color_idx=$(((j + 1) % ${N_STACK_COLORS}))
    color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})
    SPEC="${SPEC} \
          DEF:CPU$j=${RRDFILE}:cpu$j:AVERAGE \
          AREA:CPU$j#${color}40:STACK \
          LINE:0#${color}:CPU$j:STACK \
          GPRINT:CPU$j:MAX:Max\:%6.2lf \
          GPRINT:CPU$j:AVERAGE:Average\:%6.2lf \
          GPRINT:CPU$j:LAST:Current\:%6.2lf\n \
         "
    j=$((j + 1))
done

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "CPU Usage" \
        --vertical-label "% Utilisation" \
        --watermark "${WATERMARK}" \
        --legend-direction=bottomup \
        ${SPEC}
