#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

if [ -z $1 ]
then
    echo "$0: error: missing ups name" >&2
    exit
fi

ups=$1
shift

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: ups=${ups} TIMESPAN=${TIMESPAN} >&2

inst=upsc-${ups}
RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

color3=$(echo ${STACK_COLORS} | cut -d: -f3)
color4=$(echo ${STACK_COLORS} | cut -d: -f4)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "UPS ${ups}: Battery charge and voltage" \
        --vertical-label "% Charge" \
        --watermark "${WATERMARK}" \
        --lower-limit 0 --upper-limit 100 --rigid \
        --right-axis 0.15:0 --right-axis-label "Voltage (V)" \
        --right-axis-format "%2.1lf" --units-length 3 \
        --tabwidth 60 \
        COMMENT:"\t  Maximum  Average  Current\n" \
        DEF:charge=${RRDFILE}:battery_charge:AVERAGE \
        DEF:voltage=${RRDFILE}:battery_voltage:AVERAGE \
        CDEF:voltage_scaled="voltage,0.15,/" \
        LINE2:charge#${color3}:" Charge\t" \
        GPRINT:charge:MAX:"%6.1lf%s" \
        GPRINT:charge:AVERAGE:"%6.1lf%s" \
        GPRINT:charge:LAST:"%6.1lf%s\n" \
        LINE:voltage_scaled#${color4}:"Voltage\t" \
        GPRINT:voltage:MAX:"%6.1lf%s" \
        GPRINT:voltage:AVERAGE:"%6.1lf%s" \
        GPRINT:voltage:LAST:"%6.1lf%s\n"
