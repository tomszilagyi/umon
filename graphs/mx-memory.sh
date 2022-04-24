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
# The rest are displayed by smtpd-levels.sh
fields="mem_q_env mem_q_msg"

SPEC=
j=0
for fld in ${fields}; do
    color_idx=$((j % N_STACK_COLORS + 1))
    color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})
    label=$(getlabel ${fld})
    SPEC="${SPEC} \
          DEF:${fld}=${RRDFILE}:${fld}:AVERAGE \
          AREA:${fld}#${color}40 \
          LINE:${fld}#${color}:${label}\t \
          GPRINT:${fld}:MAX:%6.2lf%SB \
          GPRINT:${fld}:AVERAGE:%6.2lf%SB \
          GPRINT:${fld}:LAST:%6.2lf%SB\n \
         "
    j=$((j + 1))
done

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "MX memory usage" \
        --vertical-label "Memory (bytes)" \
        --watermark "${WATERMARK}" \
        --base 1024 --lower-limit 0 \
        --tabwidth 120 \
        COMMENT:"\t   Maximum    Average   Current\n" \
        ${SPEC}
