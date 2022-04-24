#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

inst=df

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

state=./probes/df.env
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
while true
do
    fs=$(eval "echo \$fs${j}")
    [ -z ${fs} ] && break
    total=$(eval "echo \$total${j}")
    mounted=$(eval "echo \$mounted${j}")

    color_idx=$((j % N_STACK_COLORS + 1))
    color=$(echo ${STACK_COLORS} | cut -d: -f${color_idx})

    # N.B.: the CDEF of TOTAL$j uses a multiplication by zero
    # to have a data-derived series on top of which we can
    # bring in the constant ${total}, because RRD apparently
    # does not let us define a plain constant as a VDEF...
    SPEC="${SPEC} \
          DEF:USEDKB$j=${RRDFILE}:used$j:AVERAGE \
          CDEF:USED$j=USEDKB$j,1024,* \
          CDEF:CAP$j=USEDKB$j,100.0,*,${total},/ \
          CDEF:TOTAL$j=USEDKB$j,0,*,${total},+,1024,* \
          LINE:CAP$j#${color}:${fs}\t \
          GPRINT:TOTAL$j:LAST:%5.1lf%sB \
          GPRINT:USED$j:MAX:%5.1lf%sB \
          GPRINT:USED$j:AVERAGE:%5.1lf%sB \
          GPRINT:USED$j:LAST:%5.1lf%sB \
          GPRINT:CAP$j:LAST:%5.1lf%% \
          COMMENT:${mounted}\n
         "
    j=$((j + 1))
done

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Disk usage" \
        --vertical-label "% Capacity" \
        --watermark "${WATERMARK}" \
        --base 1024 \
        --tabwidth 50 \
        "COMMENT: Filesystem\t    Total   MaxUsed  AvgUsed  CurUsed  CurCap  Mount\n" \
        ${SPEC}
