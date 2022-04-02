#!/bin/sh

NAME=testplugin

test -n "$1" || exit 1
FUNC="$1"
shift

test -n "$1" || exit 1
HOST=$1

sample() {
    echo "Sample: ${NAME} ${HOST}"
}

graph() {
    echo "Graph: ${NAME} ${HOST}"
}

case $FUNC in
    sample)
        shift
        sample $@
        ;;
    graph)
        shift
        graph $@
        ;;
    *)
        echo "Usage: $0 sample|graph [args...]"
        exit 1
        ;;
esac
