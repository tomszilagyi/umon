# N.B.: This Makefile must be valid and correct
# for both BSD and GNU versions of Make!

TARGET=umon_fcgi

all: ${TARGET}

HDRS=child.h fcgi.h utils.h
OBJS=child.o umon.o utils.o

CC=c++
CCFLAGS=-std=c++20 -funsigned-char -Wall -g -O2

.SUFFIXES: .cc .o

.cc.o:
	${CC} ${CCFLAGS} -c -o $@ $<

${OBJS}: ${HDRS}

${TARGET}: ${OBJS}
	${CC} ${CCFLAGS} -o $@ ${OBJS}

clean:
	rm -f ${TARGET} ${OBJS}
