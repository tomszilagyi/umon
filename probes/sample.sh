#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

state=./probes/probes.env
if [ ! -f ${state} ]
then
    case $(uname -s) in
        Linux)
            snmpget="snmpget -O n"
            snmpwalk="snmpwalk -O n"
            ;;
        OpenBSD)
            snmpget="snmp get -O n"
            snmpwalk="snmp walk -O n"
            ;;
        *)
            echo "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac

    echo "snmpget=\"${snmpget}\"" >> $state
    echo "snmpwalk=\"${snmpwalk}\"" >> $state
fi
. ${state}

probe() {
    [ -n "$1" ] || return
    name=$1
    shift

    if [ -n "$1" ]
    then
        inst=$name-$1
    else
        inst=$name
    fi

    sample=./probes/$name/sample.sh
    if [ ! -x $sample ]
    then
        echo "error: $name: no such probe" >&2
        return
    fi

    echo "probe name=$name inst=$inst args=$@"
    ./probes/$name/sample.sh $inst $@
}

if ! test -d "${RRDFILES}" ; then
    echo "Creating directory for RRD files: ${RRDFILES}"
    mkdir -p ${RRDFILES}
fi

. ./probes.conf
