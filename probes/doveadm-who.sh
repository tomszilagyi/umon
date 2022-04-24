#!/bin/sh

inst=$1
shift

#echo $0: inst=$inst
. ./umon.conf
. ./probes/probes.env

case $(uname -s) in
    OpenBSD)
        if ! thestats="$(doas doveadm who)" ; then
            exit 1
        fi
        ;;
    Linux)
        if ! thestats="$(sudo doveadm who)" ; then
            exit 1
        fi
        ;;
    *)
        echo "Unsupported platform: $(uname -s)" >&2
        exit 1
esac

awks='BEGIN { ci=0; cm=0; }
      { if ($3 == "imap") { ci = ci + $2; } else { cm = cm + $2; } }
      END { printf ("%d %d\n", ci, cm); }'
counts=$(echo "${thestats}" | tail -n +2 | awk "${awks}")

imap_sess=$(echo "${counts}" | cut -d' ' -f1)
sieve_sess=$(echo "${counts}" | cut -d' ' -f2)

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    ${RRDTOOL} create ${RRDFILE} \
        --step ${RRD_COLLECT_STEP} \
        DS:imap_sessions:GAUGE:${RRD_HEARTBEAT}:U:U \
        DS:sieve_sessions:GAUGE:${RRD_HEARTBEAT}:U:U \
        ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} N:${imap_sess}:${sieve_sess}
