#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z "$1" ] || TIMESPAN="$1"
# This needs to come after graph-related input parameters are set:
. ./graph.conf

cat <<EOF
<h1>$(hostname)</h1>
<h3>
$(uname -mrsv)</br>
$(uptime | cut -d' ' -f 3-)
</h3>
<p>$(date "+%Y-%m-%d %H:%M:%S %Z")</p>
EOF

probe() {
    [ -n "$1" ] || return
    name=$1
    shift

    params=""
    while [ -n "$1" ]
    do
        params="${params}/$1"
        shift
    done

    case "${name}" in
        "cpu")
            echo "<p><img src=\"/graph/${name}${params}/${TIMESPAN}\"></p>"
            ;;
        "vmstat")
            echo "<p><img src=\"/graph/${name}-events${params}/${TIMESPAN}\"></p>"
            echo "<p><img src=\"/graph/${name}-memory${params}/${TIMESPAN}\"></p>"
            echo "<p><img src=\"/graph/${name}-swap${params}/${TIMESPAN}\"></p>"
            ;;
        *)
            ;;
    esac
}

. ./probes.conf
