#!/bin/sh

cd $(dirname $0)

./load.sh sample localhost
./cpu.sh sample localhost
./if.sh sample localhost 1
./if.sh sample localhost 3
