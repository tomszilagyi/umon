# N.B.: This Makefile must be valid and correct
# for both BSD and GNU versions of Make!

all: dist

UMON_SRCS = \
    LICENSE \
    README \
    Makefile \
    examples/* \
    fcgi/*.cc \
    fcgi/*.h \
    fcgi/*.sh \
    fcgi/Makefile \
    graphs/*.sh \
    probes/*.sh \
    views/*.sh \
    static_assets/*

UMON_ARCHIVE=umon.tar.gz

dist: $(UMON_ARCHIVE)

$(UMON_ARCHIVE): $(UMON_SRCS)
	tar -czf $(UMON_ARCHIVE) $(UMON_SRCS)
