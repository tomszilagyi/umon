#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z "$1" ] || TIMESPAN="$1"
# This needs to come after graph-related input parameters are set:
. ./graph.conf

. ./views/header.sh

echo "<div id=\"graphs\">"

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
        "upsc")
            echo "<img src=\"/graph/${name}-status${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-battery${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-load${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-line-voltage${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-line-frequency${params}/${TIMESPAN}\">"
            ;;
        *)
            ;;
    esac
}

. ./probes.conf

echo "</div>"
