#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

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
        echo "error: $name: no such probe"
        return
    fi

    echo "probe name=$name inst=$inst args=$@"
    ./probes/$name/sample.sh $inst $@
}

if ! test -d "${RRDFILES}" ; then
    echo "Creating directory for RRD files: ${RRDFILES}"
    mkdir -p ${RRDFILES}
fi

if ! test -d "${IMAGES}" ; then
    echo "Creating directory for image files: ${IMAGES}"
    mkdir -p ${IMAGES}
fi

. ./probes.conf
