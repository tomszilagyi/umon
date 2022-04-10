#!/bin/sh

inst=$1
shift

#echo $0: inst=$inst
. ./umon.conf
. ./probes/probes.env

oid_procload=.1.3.6.1.2.1.25.3.3.1.2

state=./probes/cpu.env
if [ ! -f ${state} ]
then
    nCores=$(${snmpwalk} ${SNMP_COMMON_ARGS} ${oid_procload} | \
                 wc -l | tr -d ' ')
    [ ${nCores} -eq 0 ] && exit 1

    echo "nCores=$nCores" >> $state
fi

. ${state}

pcts=$(${snmpwalk} ${SNMP_COMMON_ARGS} ${oid_procload} | \
           cut -d: -f2 | tr -d ' ' | tr '\n' ':' | cut -d: -f -${nCores})

echo "$nCores cores, pcts=$pcts"

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    DS=
    j=0
    while [ $j -lt ${nCores} ]; do
        DS="${DS} DS:cpu$j:GAUGE:${RRD_HEARTBEAT}:U:U"
        j=$((j + 1))
    done
    ${RRDTOOL} create ${RRDFILE} \
               --step ${RRD_COLLECT_STEP} \
               ${DS} \
               ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} N:${pcts}
