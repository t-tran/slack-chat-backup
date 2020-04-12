#!/bin/bash

for i in messages/*/*/*.json; do
  if [[ ! -s $i ]]; then
    echo "Removing empty file: $i"
    if [[ "X$1" == "X--run" ]]; then
      rm -rf $i
    fi
    continue
  fi
  cat $i | jq . >/dev/null
  if [[ $? -gt 0 ]]; then
    echo "Removing error file: $i"
    if [[ "X$1" == "X--run" ]]; then
      rm -rf $i
    fi
    continue
  fi
done
