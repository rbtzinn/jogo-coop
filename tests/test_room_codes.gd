extends Node

func _ready() -> void:
	# Never contact a production service from this input-validation test.
	OS.set_environment("GAME_RELAY_URL", "")
	var failures := 0
	# Valid room codes can begin with digits, and player entry accepts lowercase and spaces.
	for code in ["2ABC9D", "  9abcde  ", "ABCDEF"]:
		var accepted := Network.join_room(code) == ERR_UNCONFIGURED
		print("%s valid code: %s" % ["OK" if accepted else "FAIL", code])
		if not accepted:
			failures += 1
	for code in ["ABC", "ABCDEF7", "ABCD_2", "ABC0D2", "ABC1D2", "ABCID2", "ABCOD2"]:
		var rejected := Network.join_room(code) == ERR_INVALID_PARAMETER
		print("%s invalid code: %s" % ["OK" if rejected else "FAIL", code])
		if not rejected:
			failures += 1
	print("FAILURES: %d" % failures)
	get_tree().quit(failures)
