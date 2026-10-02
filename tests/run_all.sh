#!/bin/sh
# Roda todos os testes sem janela. Uso (Git Bash, na pasta do projeto): sh tests/run_all.sh
# Termina com código 0 só se tudo passar (falha também se aparecer qualquer SCRIPT ERROR).
GODOT="${GODOT:-/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
export GODOT
FAILED=0
# Atualiza o cache de classes (scripts novos com class_name).
"$GODOT" --headless --path . --import > /dev/null 2>&1
for scene in tests/test_*.tscn; do
	name=$(basename "$scene" .tscn)
	[ "$name" = "test_online" ] && continue
	"$GODOT" --headless --path . --fixed-fps 60 "res://$scene" > "/tmp/$name.log" 2>&1
	code=$?
	grep -h "^FAIL\|SCRIPT ERROR" "/tmp/$name.log" | sort | uniq -c
	errors=$(grep -c "SCRIPT ERROR" "/tmp/$name.log")
	echo "$name: $code falhas, $errors erros de script"
	[ $code -ne 0 ] && FAILED=1
	[ "$errors" -ne 0 ] && FAILED=1
done
for net in "" ruim; do
	if sh tests/run_online.sh $net > /tmp/online_summary.log 2>&1; then
		echo "test_online $net: ok"
	else
		grep "FAIL\|SCRIPT ERROR" /tmp/online_summary.log
		echo "test_online $net: FALHOU"
		FAILED=1
	fi
done
exit $FAILED
