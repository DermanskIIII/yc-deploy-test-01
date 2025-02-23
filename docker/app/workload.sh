#!/usr/bin/env bash
function getDate
{
  /bin/date $1
  touch ./executed
  exit 0
}
test ! -f ./executed && getDate || test $((`date +%s` - `stat -c %X ./executed`)) -ge 5 && getDate || exit 1