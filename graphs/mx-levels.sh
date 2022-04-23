#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

inst=mx
state=./probes/mx.env
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

getlabel() {
    label=$(eval "echo \$label_$1")
    if [ -z ${label} ]
    then
        echo $1
    else
        echo ${label}
    fi
}

# This is a subset of ${gauges}
# The rest are displayed by mx-memory.sh
fields="evpcache_size bounce_env sched_env smtp_sess"

SPEC=
j=0
for fld in ${fields}; do
    color_idx=$((j % ${N_STACK_COLORS} + 1))
    color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})
    label=$(getlabel ${fld})
    SPEC="${SPEC} \
          DEF:${fld}=${RRDFILE}:${fld}:AVERAGE \
          LINE:${fld}#${color}:${label}\t \
          GPRINT:${fld}:MAX:%10.1lf \
          GPRINT:${fld}:AVERAGE:%10.1lf \
          GPRINT:${fld}:LAST:%10.1lf\n \
         "
    j=$((j + 1))
done

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "MX levels" \
        --vertical-label "Count" \
        --watermark "${WATERMARK}" \
        --tabwidth 140 \
        COMMENT:"\t      Maximum     Average     Current\n" \
        ${SPEC}
