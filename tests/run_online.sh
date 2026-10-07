#!/bin/sh
# Roda o teste online (host + cliente sem janela) e mostra o resultado dos dois.
# Uso (Git Bash, na pasta do projeto): sh tests/run_online.sh [ruim]
# "ruim" liga o simulador de internet ruim nos dois (ping 160, oscilando, perdendo pacotes).
GODOT="${GODOT:-/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
NET="$1"
TEST_SCENE="${TEST_SCENE:-res://tests/test_online.tscn}"
"$GODOT" --headless --path . "$TEST_SCENE" -- host $NET > /tmp/online_host.log 2>&1 &
HOST=$!
"$GODOT" --headless --path . "$TEST_SCENE" -- client $NET > /tmp/online_client.log 2>&1
CLIENT_CODE=$?
wait $HOST
HOST_CODE=$?
grep -h "^\[host\]\|^\[client\]\|SCRIPT ERROR" /tmp/online_host.log /tmp/online_client.log
echo "host: $HOST_CODE falhas, cliente: $CLIENT_CODE falhas"
[ $HOST_CODE -eq 0 ] && [ $CLIENT_CODE -eq 0 ]
