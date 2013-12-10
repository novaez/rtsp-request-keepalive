#!/bin/bash

logdir=${1:-"log"}/"procs"

echo "$(grep 'Connection has been closed by server'  -r ${logdir} | wc -l) + $(grep 'ANNOUNCE' -r ${logdir} | wc -l)" | bc
