#!/usr/bin/env bash
time=$((`date +%s` - `stat -c %X ./executed`))
if [ $time -ge 5 ]; then
  /bin/date $1
  touch ./executed
  exit 0
else
  exit 1
fi