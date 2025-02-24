#!/usr/bin/env bash

IP=`newgrp docker <<< "docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' genotek-test"`

cat << EOF
Логика работы скрипта запускаемого веб-приложением такова, что корректно отрабатывать он должен
не чаще 1 раза в 5 секунд. Демонстрация будет состоять из 20 запросов утилитой curl,
с интервалом в 1 секунду, с выводом номера запроса в серии, телом ответа сервера, при 200 коде,
а также выводом самого кода.

Чтобы начать, нажмите ввод.
EOF

read

for i in {1..20}; do
  echo -en "$i\t"
  curl -w "\t\t\t\tHTTP STATUS %{http_code}\n" $IP 2>/dev/null | sed -E "s/UTC\t\t\t\t/UTC\t/g"
  sleep 1
done;
