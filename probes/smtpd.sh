#!/bin/sh

inst=$1
shift

#echo $0: inst=$inst
. ./umon.conf
. ./probes/probes.env

case $(uname -s) in
    OpenBSD)
        thestats="$(doas smtpctl show stats)"
        ;;
    Linux)
        thestats="$(sudo smtpctl show stats)"
        ;;
    *)
        echo "Unsupported platform: $(uname -s)" >&2
        exit 1
esac

get() {
    rv=$(echo "${thestats}" | grep -m 1 "$1" | awk -F'=' '{print $2}')
    if [ -z ${rv} ]
    then
        # empty stats are omitted from the output, be explicit
        echo "0"
    else
        echo "${rv}"
    fi
}

## An audit of the smtpd sources reveals the following metrics
## (grep for "stat_(in|de)crement" calls):

## GAUGES (both increased and decreased):
# bounce.envelope
# bounce.message
# bounce.session
# mda.envelope
# mda.pending
# mda.running
# mda.user
# mta.connector
# mta.domain
# mta.envelope
# mta.host
# mta.relay
# mta.route
# mta.session
# mta.source
# mta.task
# mta.task.running
# queue.evpcache.size
# queue.ram.envelope.size
# queue.ram.message.size
# scheduler.envelope
# scheduler.envelope.incoming
# scheduler.envelope.inflight
# scheduler.ramqueue.envelope
# scheduler.ramqueue.hold
# scheduler.ramqueue.holdq
# scheduler.ramqueue.message
# scheduler.ramqueue.update
# smtp.session
# smtp.smtps
# smtp.tls

mem_q_env=$(get "queue.ram.envelope.size")
mem_q_msg=$(get "queue.ram.message.size")
bounce_env=$(get "bounce.envelope")
evpcache_size=$(get "queue.evpcache.size")
sched_env=$(get "scheduler.envelope")
smtp_sess=$(get "smtp.session")

gauges="mem_q_env mem_q_msg bounce_env evpcache_size sched_env smtp_sess"

## COUNTERS (only increased, never decreased):
# queue.bounce
# queue.evpcache.load.hit
# queue.evpcache.load.missed
# queue.evpcache.update.hit
# queue.evpcache.update.missed
# scheduler.delivery.loop
# scheduler.delivery.ok
# scheduler.delivery.permfail
# scheduler.delivery.tempfail
# scheduler.envelope.expired
# scheduler.envelope.removed
# scheduler.envelope.updated
# smtp.session.inet4
# smtp.session.inet6
# smtp.session.local

del_pf=$(get "scheduler.delivery.permfail")
del_tf=$(get "scheduler.delivery.tempfail")
del_ok=$(get "scheduler.delivery.ok")
del_loop=$(get "scheduler.delivery.loop")
env_expire=$(get "scheduler.envelope.expired")
env_remove=$(get "scheduler.envelope.removed")
env_bounce=$(get "queue.bounce")

counters="del_pf del_tf del_ok del_loop env_expire env_remove env_bounce"

fields="${gauges} ${counters}"

data="N"

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

state=./probes/smtpd.env
if [ ! -f ${state} ]
then
    echo "gauges=\"${gauges}\"" >> ${state}
    echo "counters=\"${counters}\"" >> ${state}
    # Set up labels for the graph (defaults to variable name)
    cat <<EOF >> ${state}
label_mem_q_env=queued_envelopes
label_mem_q_msg=queued_messages
label_bounce_env=bounce_envelopes
label_evpcache_size=envelope_cache_size
label_sched_env=scheduled_envelopes
label_smtp_sess=smtp_client_sessions
label_del_pf=perm_fail
label_del_tf=temp_fail
label_del_ok=delivered_ok
label_del_loop=message_loop
label_env_expire=expired_envelopes
label_env_remove=removed_envelopes
label_env_bounce=bounces_generated
EOF
fi

RRDFILE="${RRDFILES}/${inst}.rrd"
if ! test -f "${RRDFILE}" ; then
    echo "Creating ${RRDFILE}"
    DS=
    for gg in ${gauges}
    do
        DS="${DS} DS:${gg}:GAUGE:${RRD_HEARTBEAT}:0:U"
    done
    for ctr in ${counters}
    do
        DS="${DS} DS:${ctr}:DERIVE:${RRD_HEARTBEAT}:0:U"
    done
    ${RRDTOOL} create ${RRDFILE} \
        --step ${RRD_COLLECT_STEP} \
               ${DS} \
               ${RRA_CREATE_ARGS}
fi

${RRDTOOL} update ${RRDFILE} ${data}
