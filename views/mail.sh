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

<div id="graphs">
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
        "mx")
            echo "<img src=\"/graph/${name}-rates${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-levels${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-memory${params}/${TIMESPAN}\">"
            ;;
        "doveadm-who")
            echo "<img src=\"/graph/${name}${params}/${TIMESPAN}\">"
            ;;
        *)
            ;;
    esac
}

. ./probes.conf

echo "</div>"
