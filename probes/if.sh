#!/bin/sh

inst=$1
shift

if [ -z $1 ]
then
    echo "$0: error: missing interface name"
    exit
fi

interface=$1
shift

#echo $0: inst=$inst interface=$interface
. ./umon.conf
. ./probes/probes.env

# Ref.: http://www.net-snmp.org/docs/mibs/ifMIBObjects.html
oid_ifdescr=.1.3.6.1.2.1.31.1.1.1.1
oid_rxbytes=.1.3.6.1.2.1.31.1.1.1.6
oid_txbytes=.1.3.6.1.2.1.31.1.1.1.10
oid_rxpkts=.1.3.6.1.2.1.31.1.1.1.7
oid_txpkts=.1.3.6.1.2.1.31.1.1.1.11

state=./probes/if-$inst.env
if [ ! -f ${state} ]
then
    ifIndex=$(${snmpwalk} ${SNMP_COMMON_ARGS} ${oid_ifdescr} | \
                  grep -m 1 ${interface} | cut -d= -f1 | cut -d. -f13)
    [ -z ${ifIndex} ] && exit 1

    echo "ifIndex=$ifIndex" >> ${state}
fi

. ${state}

rxbytes=$(${snmpget} ${SNMP_COMMON_ARGS} \
                     ${oid_rxbytes}.${ifIndex} | cut -d: -f2 | tr -d ' ')
txbytes=$(${snmpget} ${SNMP_COMMON_ARGS} \
                     ${oid_txbytes}.${ifIndex} | cut -d: -f2 | tr -d ' ')
rxpkts=$(${snmpget} ${SNMP_COMMON_ARGS} \
                    ${oid_rxpkts}.${ifIndex} | cut -d: -f2 | tr -d ' ')
txpkts=$(${snmpget} ${SNMP_COMMON_ARGS} \
                    ${oid_txpkts}.${ifIndex} | cut -d: -f2 | tr -d ' ')
#echo "rxbytes=${rxbytes}"
#echo "txbytes=${txbytes}"
#echo "rxpkts=${rxpkts}"
#echo "txpkts=${txpkts}"

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    ${RRDTOOL} create ${RRDFILE} \
        --step ${RRD_COLLECT_STEP} \
        DS:rxbytes:DERIVE:${RRD_HEARTBEAT}:0:U \
        DS:txbytes:DERIVE:${RRD_HEARTBEAT}:0:U \
        DS:rxpkts:DERIVE:${RRD_HEARTBEAT}:0:U \
        DS:txpkts:DERIVE:${RRD_HEARTBEAT}:0:U \
        ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} N:${rxbytes}:${txbytes}:${rxpkts}:${txpkts}
