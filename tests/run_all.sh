#!/bin/sh
# Roda todos os testes sem janela. Uso (Git Bash, na pasta do projeto): sh tests/run_all.sh
GODOT="${GODOT:-/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
export GODOT
FAILED=0
for scene in tests/test_*.tscn; do
	name=$(basename "$scene" .tscn)
	[ "$name" = "test_online" ] && continue
	"$GODOT" --headless --path . --fixed-fps 60 "res://$scene" > "/tmp/$name.log" 2>&1
	code=$?
	grep -h "^FAIL\|SCRIPT ERROR" "/tmp/$name.log"
	echo "$name: $code falhas"
	[ $code -ne 0 ] && FAILED=1
done
sh tests/run_online.sh | tail -1 || FAILED=1
exit $FAILED
