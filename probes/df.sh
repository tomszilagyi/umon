#!/bin/sh

inst=$1
shift

#echo $0: inst=$inst
. ./umon.conf
. ./probes/probes.env

thedf="$(df -kl | tail -n +2)"

state=./probes/df.env
if [ ! -f ${state} ]
then
    n=0
    echo "${thedf}" | \
    while read line
    do
        fs=$(echo ${line} | cut -d' ' -f 1)
        case ${fs} in
            /dev/*)
                echo "fs$n=${fs}" >> ${state}
                used=$(echo ${line} | cut -d' ' -f 3)
                avail=$(echo ${line} | cut -d' ' -f 4)
                total=$((used + avail))
                echo "total$n=${total}" >> ${state}
                mounted=$(echo ${line} | cut -d' ' -f 6)
                echo "mounted$n=\"${mounted}\"" >> ${state}
                n=$((n + 1))
                ;;
            *)
                # discard "none", "udev", "tmpfs", etc.
                ;;
        esac
    done
fi

. ${state}

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    DS=
    j=0
    while true
    do
        fs=$(eval "echo \$fs${j}")
        [ -z ${fs} ] && break
        DS="${DS} DS:used$j:GAUGE:${RRD_HEARTBEAT}:U:U"
        j=$((j + 1))
    done
    ${RRDTOOL} create ${RRDFILE} \
               --step ${RRD_COLLECT_STEP} \
               ${DS} \
               ${RRA_CREATE_ARGS}
fi

j=0
data="N"
while true
do
    fs=$(eval "echo \$fs${j}")
    [ -z ${fs} ] && break
    current=$(echo "${thedf}" | grep ${fs})
    used=$(echo ${current} | cut -d' ' -f 3)
    data="${data}:${used:-0}"
    j=$((j + 1))
done

${RRDTOOL} update ${RRDFILE} ${data}
