#!/bin/sh

cd $(dirname $0)/..
. ./umon.conf

[ -z $1 ] || TIMESPAN=$1
# This needs to come after graph-related input parameters are set:
. ./graph.conf

echo $0: TIMESPAN=${TIMESPAN} >&2

inst=doveadm-who
RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}"
then
    echo "RRD not found, expected: ${RRDFILE}" >&2
    echo "Has the probe run yet?" >&2
    exit 1
fi

color3=$(echo ${STACK_COLORS} | cut -d: -f3)
color4=$(echo ${STACK_COLORS} | cut -d: -f4)

exec ${RRDTOOL} graph - -a PNG ${RRD_GRAPH_ARGS} \
        --title "Dovecot user sessions" \
        --vertical-label "Count" \
        --watermark "${WATERMARK}" \
        --legend-direction=bottomup \
        --tabwidth 60 \
        DEF:sieve=${RRDFILE}:sieve_sessions:AVERAGE \
        DEF:imap=${RRDFILE}:imap_sessions:AVERAGE \
        AREA:sieve#${color4}50:STACK \
        LINE:0#${color4}:"Sieve\t":STACK \
        GPRINT:sieve:MAX:"%6.1lf" \
        GPRINT:sieve:AVERAGE:"%6.1lf" \
        GPRINT:sieve:LAST:"%6.1lf\n" \
        AREA:imap#${color3}50:STACK \
        LINE:0#${color3}:" IMAP\t":STACK \
        GPRINT:imap:MAX:"%6.1lf" \
        GPRINT:imap:AVERAGE:"%6.1lf" \
        GPRINT:imap:LAST:"%6.1lf\n" \
        COMMENT:"\t Maximum  Average Current\n"
