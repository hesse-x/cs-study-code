#!/bin/bash
# bash build.sh exp.cpp 4
if [[ -n $2 && $2 =~ ^[0-9]+$ ]]; then
    N=$2
else
    N=4
fi
g++ $1 utils.cpp --std=c++20 -DP${N}
