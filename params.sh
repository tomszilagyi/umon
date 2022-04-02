# Constants

COMMUNITY="public"
RRDFILES="/var/umon"
RRDTOOL="/usr/local/bin/rrdtool"
IMAGES="/var/www/htdocs/umon"
WATERMARK="uMon | $(hostname) | generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
COLLECT_STEP=300

RRA_CREATE_ARGS="\
    RRA:AVERAGE:0.5:1:600 \
    RRA:AVERAGE:0.5:6:700 \
    RRA:AVERAGE:0.5:24:775 \
    RRA:AVERAGE:0.5:288:797 \
    RRA:MAX:0.5:1:600 \
    RRA:MAX:0.5:6:700 \
    RRA:MAX:0.5:24:775 \
    RRA:MAX:0.5:288:797"


# Parameters

# Graph dimensions
WIDTH=800
HEIGHT=150

# Timespan of graph. Choose from 1d, 6d, 24d, 288d
# according to the RRA definitions above, or anything
# in between (rrdtool will resample/interpolate).
TIMESPAN=2d

RRD_GRAPH_ARGS="\
    --end now --start end-${TIMESPAN} \
    --width ${WIDTH} \
    --height ${HEIGHT}"
