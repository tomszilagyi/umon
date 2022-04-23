#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z "$1" ] || TIMESPAN="$1"
# This needs to come after graph-related input parameters are set:
. ./graph.conf

. ./views/header.sh

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
        "diskio")
            echo "<img src=\"/graph/${name}-ops${params}/${TIMESPAN}\">"
            echo "<img src=\"/graph/${name}-xfer${params}/${TIMESPAN}\">"
            ;;
        "df")
            echo "<img src=\"/graph/${name}${params}/${TIMESPAN}\">"
            ;;
        *)
            ;;
    esac
}

. ./probes.conf

echo "</div>"
