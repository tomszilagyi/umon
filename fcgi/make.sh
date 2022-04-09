#!/bin/sh

cd $(dirname $0)
clang++ -std=c++20 -Wall -c -o child.o child.cc
clang++ -std=c++20 -Wall -c -o utils.o utils.cc
clang++ -std=c++20 -Wall -c -o umon.o umon.cc
clang++ -std=c++20 -Wall -o umon_fcgi *.o
