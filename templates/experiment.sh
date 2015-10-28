#!/bin/bash

i=0
for a; do
  i=$(( $i + 1 ))

  printf "arg # %03d => %s\n" ${i} "$a"
done

