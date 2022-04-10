#!/bin/sh

inst=$1
shift

#echo $0: inst=$inst
. ./umon.conf
. ./probes/probes.env

export thevms="$(vmstat -s)"

get() {
    echo "${thevms}" | grep -m 1 "$1" | awk '{print $1}'
}

case $(uname -s) in
    OpenBSD)
        # Gauges
        bytes_per_page=$(get "bytes per page")
        total_memory=$((bytes_per_page * $(get "pages managed")))
        free_memory=$((bytes_per_page * $(get "pages free")))
        active_memory=$((bytes_per_page * $(get "pages active")))
        inactive_memory=$((bytes_per_page * $(get "pages inactive")))

        total_swap=$((bytes_per_page * $(get "swap pages")))
        used_swap=$((bytes_per_page * $(get "swap pages in use")))

        # Event counters
        pf=$(get "page faults")
        pi=$(get "pagein operations")
        syscalls=$(get "syscalls")
        ints=$(get "interrupts")
        cs=$(get "cpu context switches")
        forks=$(get "forks")

        counters="pf pi syscalls ints cs forks"
        ;;
    Linux)
        # Gauges
        total_memory=$((1024 * $(get "K total memory")))
        free_memory=$((1024 * $(get "K free memory")))
        active_memory=$((1024 * $(get "K active memory")))
        inactive_memory=$((1024 * $(get "K inactive memory")))

        total_swap=$((1024 * $(get "K total swap")))
        used_swap=$((1024 * $(get "K used swap")))

        # Event counters
        pi=$(get "pages paged in")
        po=$(get "pages paged out")
        si=$(get "pages swapped in")
        so=$(get "pages swapped out")
        ints=$(get "interrupts")
        cs=$(get "CPU context switches")
        forks=$(get "forks")

        counters="pi po si so ints cs forks"
        ;;
    *)
        echo "Unsupported platform: $(uname -s)" >&2
        exit 1
esac

data="N"

# These metrics are the same regardless of platform:
gauges="total_memory free_memory active_memory inactive_memory \
        total_swap used_swap"
for gg in ${gauges}
do
    val=$(eval "echo \$$gg")
    data="${data}:${val}"
done

for ctr in ${counters}
do
    val=$(eval "echo \$$ctr")
    data="${data}:${val}"
done

state=./probes/vmstat/$inst.env
if [ ! -f ${state} ]
then
    echo "gauges=\"${gauges}\"" >> ${state}
    echo "counters=\"${counters}\"" >> ${state}
    # Set up labels for the graph (defaults to variable name)
    cat <<EOF >> ${state}

label_pf="page_faults"
label_pi="pageins"
label_po="pageouts"
label_si="swapins"
label_so="swapouts"
label_ints="interrupts"
label_cs="ctx_switches"
EOF
fi

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    DS=
    for gg in ${gauges}
    do
        DS="${DS} DS:${gg}:GAUGE:${RRD_HEARTBEAT}:U:U"
    done
    for ctr in ${counters}
    do
        DS="${DS} DS:${ctr}:COUNTER:${RRD_HEARTBEAT}:U:U"
    done
    ${RRDTOOL} create ${RRDFILE} \
               --step ${RRD_COLLECT_STEP} \
               ${DS} \
               ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} ${data}
