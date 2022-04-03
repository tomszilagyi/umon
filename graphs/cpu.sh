#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

inst=cpu

state=./probes/cpu/$inst.env
if [ ! -f $state ]
then
    echo "state not found, expected: ${state}"
    echo "Has the probe run yet?"
    exit 1
fi

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}"
    echo "Has the probe run yet?"
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
          GPRINT:CPU$j:MAX:Max\:%5.2lf%s \
          GPRINT:CPU$j:AVERAGE:Average\:%5.2lf%s \
          GPRINT:CPU$j:LAST:Current\:%5.2lf%s\n \
         "
    j=$((j + 1))
done

IMAGE="${IMAGES}/cpu.png"

exec ${RRDTOOL} graph ${IMAGE} ${RRD_GRAPH_ARGS} \
        --title "CPU Usage" \
        --vertical-label "% Utilisation" \
        --watermark "${WATERMARK}" \
        --legend-direction=bottomup \
        ${SPEC}
