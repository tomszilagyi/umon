#!/bin/sh

inst=$1
shift

if [ -z $1 ]
then
    echo "$0: error: missing device name"
    exit
fi

device=$1
shift

#echo $0: inst=$inst device=$device
. ./umon.conf
. ./probes/probes.env

# Ref.: http://www.net-snmp.org/docs/mibs/ucdDiskIOMIB.html
oid_devdescr=.1.3.6.1.4.1.2021.13.15.1.1.2
oid_rdbytes=.1.3.6.1.4.1.2021.13.15.1.1.12
oid_wrbytes=.1.3.6.1.4.1.2021.13.15.1.1.13
oid_rdops=.1.3.6.1.4.1.2021.13.15.1.1.5
oid_wrops=.1.3.6.1.4.1.2021.13.15.1.1.6

state=./probes/diskio-${inst}.env
if [ ! -f ${state} ]
then
    devIdx=$(${snmpwalk} ${SNMP_COMMON_ARGS} ${oid_devdescr} | \
                 grep -m 1 ${device} | cut -d= -f1 | cut -d. -f14)
    [ -z ${devIdx} ] && exit 1

    echo "devIdx=$devIdx" >> ${state}
fi

. ${state}

rdbytes=$(${snmpget} ${SNMP_COMMON_ARGS} \
                     ${oid_rdbytes}.${devIdx} | cut -d: -f2 | tr -d ' ')
wrbytes=$(${snmpget} ${SNMP_COMMON_ARGS} \
                     ${oid_wrbytes}.${devIdx} | cut -d: -f2 | tr -d ' ')
rdops=$(${snmpget} ${SNMP_COMMON_ARGS} \
                   ${oid_rdops}.${devIdx} | cut -d: -f2 | tr -d ' ')
wrops=$(${snmpget} ${SNMP_COMMON_ARGS} \
                   ${oid_wrops}.${devIdx} | cut -d: -f2 | tr -d ' ')
#echo "rdbytes=${rdbytes}"
#echo "wrbytes=${wrbytes}"
#echo "rdops=${rdops}"
#echo "wrops=${wrops}"

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    ${RRDTOOL} create ${RRDFILE} \
        --step ${RRD_COLLECT_STEP} \
        DS:rdbytes:COUNTER:${RRD_HEARTBEAT}:U:U \
        DS:wrbytes:COUNTER:${RRD_HEARTBEAT}:U:U \
        DS:rdops:COUNTER:${RRD_HEARTBEAT}:U:U \
        DS:wrops:COUNTER:${RRD_HEARTBEAT}:U:U \
        ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} N:${rdbytes}:${wrbytes}:${rdops}:${wrops}
