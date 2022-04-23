#!/bin/sh

inst=$1
shift

if [ -z $1 ]
then
    echo "$0: error: missing ups name"
    exit
fi

ups=$1
shift

#echo $0: inst=$inst ups=$ups
. ./umon.conf
. ./probes/probes.env

thestats="$(upsc ${ups} 2>/dev/null)"

get() {
    echo "${thestats}" | grep -m 1 "$1" | awk -F':' '{print $2}'
}

battery_charge=$(get "battery.charge")
battery_voltage=$(get "battery.voltage")
input_frequency=$(get "input.frequency")
input_voltage=$(get "input.voltage")
output_voltage=$(get "output.voltage")
ups_load=$(get "ups.load")

ups_status=$(get "ups.status" | tr -d ' ')
case "${ups_status}" in
    OL) # online
        on_battery=0
        ;;
    OB) # on battery
        on_battery=1
        ;;
esac

gauges="battery_charge battery_voltage on_battery ups_load \
input_frequency input_voltage output_voltage"

data="N"

for gg in ${gauges}
do
    val=$(eval "echo \$$gg")
    data="${data}:${val}"
done

state=./probes/upsc-${inst}.env
if [ ! -f ${state} ]
then
    echo "gauges=\"${gauges}\"" >> ${state}
fi

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    DS=
    for gg in ${gauges}
    do
        DS="${DS} DS:${gg}:GAUGE:${RRD_HEARTBEAT}:0:U"
    done
    ${RRDTOOL} create ${RRDFILE} \
        --step ${RRD_COLLECT_STEP} \
               ${DS} \
               ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} ${data}
