#!/bin/sh

cd $(dirname $0)
. ./params.sh

case $FUNC in
    sample)
        sample
        ;;
    graph)
        graph
        ;;
    *)
        echo "Usage: $0 sample|graph [args...]"
        exit 1
        ;;
esac
