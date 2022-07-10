#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

inst=cpu

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

state=./probes/cpu.env
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
legendRows=$(( (${nCores} + 3) / 4))
if [ ${nCores} -lt 10 ]
then
    # Simple left-to-right layout in 4 columns:
    #  cpu0  cpu1  cpu2  cpu3
    #  cpu4  cpu5 ...
    j=0
    while [ $j -lt ${nCores} ]
    do
        color_idx=$((j % N_STACK_COLORS + 1))
        color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})
        SPEC="${SPEC} \
              DEF:CPU$j=${RRDFILE}:cpu$j:AVERAGE \
              AREA:CPU$j#${color}40:STACK \
              LINE:0#${color}:cpu$j\t:STACK \
              GPRINT:CPU$j:MAX:%3.0lf%s\g \
              GPRINT:CPU$j:AVERAGE:%3.0lf%s\g \
              GPRINT:CPU$j:LAST:%3.0lf"
        if [ $((j % 4)) -eq 3 ]
        then
            SPEC="${SPEC}\n"
        fi
        j=$((j + 1))
    done
else
    # Column-based layout in 4 columns:
    #  cpu0  cpu3  cpu6  cpu9
    #  cpu1  cpu4  cpu7  ...
    #  cpu2  cpu5  cpu8
    j=0
    n=0
    row=0
    while [ $n -lt ${nCores} ]
    do
        color_idx=$((j % N_STACK_COLORS + 1))
        color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})
        SPEC="${SPEC} \
              DEF:CPU$j=${RRDFILE}:cpu$j:AVERAGE \
              AREA:CPU$j#${color}40:STACK \
              LINE:0#${color}:cpu$j\t:STACK \
              GPRINT:CPU$j:MAX:%3.0lf%s\g \
              GPRINT:CPU$j:AVERAGE:%3.0lf%s\g \
              GPRINT:CPU$j:LAST:%3.0lf"
        n=$((n + 1))
        j=$((j + legendRows))
        if [ $j -ge ${nCores} ]
        then
            row=$((row + 1))
            j=$row
            SPEC="${SPEC}\n"
        fi
    done
fi

if [ $((nCores % 4)) -gt 0 ]
then
    # Force the last partial row to be left-justified:
    SPEC="${SPEC}\\l"
fi

HEADER="       Max Avg Cur"
case ${nCores} in
    1)
        HEADER="  ${HEADER}\n"
        ;;
    2)
        HEADER="  ${HEADER}   ${HEADER}\n"
        ;;
    3)
        HEADER="  ${HEADER}   ${HEADER}  ${HEADER}\n"
        ;;
    *)
        HEADER="  ${HEADER}   ${HEADER}  ${HEADER}   ${HEADER}\n"
        ;;
esac

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "CPU Usage" \
        --vertical-label "% Utilisation" \
        --watermark "${WATERMARK}" \
        --lower-limit 0 \
        --tabwidth 1 \
        "COMMENT:${HEADER}" \
        ${SPEC}
