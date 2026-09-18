#!/usr/bin/env bash

i=1
while ./script.sh > stdout.txt 2> stderr.txt
do
	((i++))
done
echo "The script errored during run number $i"
echo "--- stdout ---"
cat stdout.txt
echo "--- stderr ---"
cat stderr.txt

