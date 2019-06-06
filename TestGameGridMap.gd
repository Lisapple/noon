extends "res://GameGridMap.gd"

signal test_executed(index)
#signal test_succeed()
#signal test_failed()

const TEST_GAME_OVER = false
const INCLUDE_NIGHTMARES = TEST_GAME_OVER or true

const DELAY = 1.5
const TIMEOUT = 6.0

# Examples:
# { "type": MOVE, "to": Vector3(1,2,4) }
# { "type": ABSORB, "orb": Orb.BLUE }
# { "type": RELEASE, "orb": Orb.GREEN }
# { "type": WAIT, "secs": 1.5 } # Note: `secs` must be less than `TIMEOUT`
# Note: Test will move player to end if the last step is *not a MOVE* instruction.
enum { MOVE, ABSORB, RELEASE, WAIT }

var tests_enabled := false setget enable_tests
func enable_tests(value:=true):
	tests_enabled = value

var timer := Timer.new()
func _ready():
	add_child(timer)
	if tests_enabled:
		timer.wait_time = 0.5
		timer.start()
		yield(timer, "timeout")
		run()

func run():
	var tests := {
		"Intro": [
			{"type": WAIT, "secs": 2.0},
			{"type": MOVE, "to": Vector3(1,0,0)},
			{"type": WAIT, "secs": 1.0} # Taking orb
		],
		"Level1": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(-2,0,-4)},
			{"type": ABSORB, "orb": Orb.GREEN}
		],
		"Level2": [
			{"type": RELEASE, "orb": Orb.BLUE},
			{"type": RELEASE, "orb": Orb.GREEN}
		],
		"Level3": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": RELEASE, "orb": Orb.BLUE}
		],
		"Level4": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN}
		],
		"Level10": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(0,0,0)},
			{"type": RELEASE, "orb": Orb.BLUE}, # On lift, to raise it
			{"type": MOVE, "to": Vector3(5,1,0)},
			{"type": RELEASE, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE}, # Extra step to check lift bounce
			{"type": MOVE, "to": Vector3(6,0,0)},
			{"type": ABSORB, "orb": Orb.BLUE} # On lift, to lower it
		],
		"Level11": [
			{"type": MOVE, "to": Vector3(17,1,-8)},
			{"type": RELEASE, "orb": Orb.GREEN}, # Raise lift
			{"type": MOVE, "to": Vector3(17,0,-9)},
			{"type": ABSORB, "orb": Orb.GREEN}, # On lift, to lower it
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": RELEASE, "orb": Orb.GREEN}, # On lift, to raise it
			{"type": MOVE, "to": Vector3(17,1,-14)},
			{"type": RELEASE, "orb": Orb.GREEN},
			#{"type": MOVE, "to": Vector3(17,1,-17)},
			{"type": RELEASE, "orb": Orb.BLUE}, # Raise lift
		],
		"Level12": [
			{"type": MOVE, "to": Vector3(-2,0,1)},
			{"type": RELEASE, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(-1,-1,1)},
			{"type": ABSORB, "orb": Orb.GREEN}, # On lift, to lower it
			{"type": MOVE, "to": Vector3(5,0,-3)},
			{"type": RELEASE, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(4,-1,-3)},
			{"type": ABSORB, "orb": Orb.BLUE}, # On lift, to lower it
			{"type": MOVE, "to": Vector3(-1,-1,-3)},
			{"type": RELEASE, "orb": Orb.BLUE}, # On lift, to raise it
			{"type": MOVE, "to": Vector3(-4,0,-3)},
			{"type": RELEASE, "orb": Orb.BLUE}
		],
		"Level13": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(-1,0,-2)},
			{"type": ABSORB, "orb": Orb.GREEN}, # On lift, to lower it
			{"type": MOVE, "to": Vector3(0,0,-6)},
			{"type": RELEASE, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": RELEASE, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(3,0,-2)},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": RELEASE, "orb": Orb.GREEN} # On lift, to raise it
		],
		"Level20": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE}
		],
		"Level21": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN}
		],
		"Level22": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE}
		],
		"Level23": [
			{"type": MOVE, "to": Vector3(-3,1,0)},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": RELEASE, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(1,1,0)},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE}
		],
		"Level30": [
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(-4,0,0)},
			{"type": ABSORB, "orb": Orb.BLUE}
		],
		"Level31": [
			{"type": MOVE, "to": Vector3(5,1,0)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": RELEASE, "orb": Orb.BLUE}
		],
		"Level32": [
			{"type": ABSORB, "orb": Orb.PURPLE}, # Raise lift
			{"type": MOVE, "to": Vector3(26,0,14)},
			{"type": ABSORB, "orb": Orb.PURPLE}, # On lift, to lower it
			{"type": MOVE, "to": Vector3(33,0,10)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE}, # On lift, to raise it
			{"type": RELEASE, "orb": Orb.PURPLE}
		],
		"Level33": [
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(3,0,-2)},
			{"type": RELEASE, "orb": Orb.GREEN}
		],
		"Level34": [
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(1,0,4)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(-1,1,0)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(4,2,0)}, # Pick Red orb
			# Go back to end
			{"type": MOVE, "to": Vector3(-1,0,4)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(1,0,-4)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": get_begin()}
		],
		"Level33/End": [
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(-2,0,0) },
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": get_start()}
		],
		"Level32/End": [
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(33,0,10)},
			{"type": ABSORB, "orb": Orb.PURPLE}, # On lift, to lower it
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(29,0,13)},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(26,0,14)}, # On lift, to lower it
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": get_start()}
		],
		"Level31/End": [
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": get_start()}
		],
		"Level30/End": [
			{"type": ABSORB, "orb": Orb.RED},
			{"type": MOVE, "to": Array(get_ends()).back()}
		],
		"Level40": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.RED},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(8,0,9)},
			{"type": RELEASE, "orb": Orb.BLUE},
			{"type": RELEASE, "orb": Orb.BLUE}
		],
		"Level41": [
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.RED},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3 (5,0,5)},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": RELEASE, "orb": Orb.GREEN},
			{"type": RELEASE, "orb": Orb.RED}
		],
		"Level42": [
			{"type": ABSORB, "orb": Orb.RED},
			{"type": MOVE, "to": Vector3(2,1,0)}, # On lift, to upper it
			{"type": RELEASE, "orb": Orb.RED}
		],
		"Level43": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.RED},
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(1,0,-2)},
			{"type": RELEASE, "orb": Orb.BLUE}
		],
		"Level44": [
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.BLUE}
		],
		"Level45": [
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": ABSORB, "orb": Orb.RED},
			{"type": MOVE, "to": Vector3(5,0,0)},
			{"type": RELEASE, "orb": Orb.RED},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(9,0,0)},
			{"type": RELEASE, "orb": Orb.GREEN}
		],
		"Level60": [
			{"type": MOVE, "to": Vector3(-5,1,0)},
			{"type": ABSORB, "orb": Orb.RED},
			{"type": MOVE, "to": Vector3(-1,1,0)},
			{"type": ABSORB, "orb": Orb.RED},
			{"type": MOVE, "to": Vector3(3,1,0)},
			{"type": ABSORB, "orb": Orb.RED}
		],
		"Level61": [
			{"type": MOVE, "to": Vector3(3,0,-1)},
			{"type": ABSORB, "orb": Orb.PURPLE},
			{"type": RELEASE, "orb": Orb.PURPLE},
			{"type": MOVE, "to": Vector3(3,1,1)},
			{"type": RELEASE, "orb": Orb.PURPLE}
		],
		"Level62": [
			{"type": MOVE, "to": Vector3(-1,0,-1)},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(3,0,1)},
			{"type": RELEASE, "orb": Orb.GREEN}
		],
		"Level63": [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": MOVE, "to": Vector3(1,0,-4)},
			{"type": ABSORB, "orb": Orb.BLUE}
		],
		"Outro": [
			{"type": MOVE, "to": Vector3(-3,0,-3)},
			{"type": WAIT, "secs": 2.0},
			{"type": MOVE, "to": Vector3(2,0,-4)},
			{"type": WAIT, "secs": 2.0},
			{"type": MOVE, "to": Vector3(6,0,-4)},
			{"type": WAIT, "secs": 2.0},
			{"type": MOVE, "to": Vector3(10,0,-4)},
			{"type": WAIT, "secs": 2.0},
			{"type": MOVE, "to": Vector3(14,0,-4)},
			{"type": WAIT, "secs": 2.0},
			{"type": MOVE, "to": Vector3(18,0,-4)},
			{"type": WAIT, "secs": 2.0}
		],

		"Nightmare1": [
			{"type": MOVE, "to": Vector3(4,0,1)},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(-5,0,0)},
			{"type": RELEASE, "orb": Orb.GRAY}
		],
		"Nightmare2": [
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(-4,0,1)},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": RELEASE, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(5,0,2)},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": RELEASE, "orb": Orb.GRAY}
		],
		"Nightmare3": [
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(-1,1,-3)},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(5,1,0)},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY}
		],
		"Nightmare4": [
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(0,2,0)},
			{"type": ABSORB, "orb": Orb.GRAY}
		],
		"Nightmare5": [
			{"type": MOVE, "to": Vector3(-3,0,0)},
			{"type": ABSORB, "orb": Orb.GRAY},
			{"type": RELEASE, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(0,1,0)},
			{"type": RELEASE, "orb": Orb.GRAY},
			{"type": MOVE, "to": Vector3(1,0,0)},
			{"type": ABSORB, "orb": Orb.GRAY} # On lift, to lower it
		]
	}

	if INCLUDE_NIGHTMARES:
		tests["Level4"] = [
			{"type": ABSORB, "orb": Orb.GREEN}, # Bounce
			{"type": ABSORB, "orb": Orb.GREEN}, # Bounce
			{"type": ABSORB, "orb": Orb.GREEN} # Level over
		]
		tests["Level13"] = [
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.GREEN},
			{"type": MOVE, "to": Vector3(-1,0,-2)},
			{"type": ABSORB, "orb": Orb.GREEN}, # On lift, to lower it
			{"type": MOVE, "to": Vector3(0,0,-6)},
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE} # Level over
		]
		tests["Level22"] = [ # Level 23 is too tricky to fail
			{"type": ABSORB, "orb": Orb.BLUE},
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE} # Level over
		]
		tests["Level33"] = [
			{"type": ABSORB, "orb": Orb.GREEN}, # Bounce
			{"type": ABSORB, "orb": Orb.GREEN}, # Bounce
			{"type": ABSORB, "orb": Orb.GREEN} # Level over
		]
		tests["Level44"] = [
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE} # Level over
		]
		# No 6x level can fail

	if TEST_GAME_OVER:
		tests["Level3"] = [
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE}, # Bounce
			{"type": ABSORB, "orb": Orb.BLUE} # Level over
		]

	var level := filename.get_file().get_basename()
	if tests.get(level, []).empty():
		return # DEBUG

	if get_begin() != get_start():
		var name = "%s/End" % level
		run_tests(tests[name])
	else:
		var steps = tests.get(level, [])
		if steps.back()["type"] != MOVE:
			steps += [{"type": MOVE, "to": get_ends()[0] }]
		run_tests(steps)

func run_tests(tests: Array):
	var index := 0
	while index < tests.size():
		var info = tests[index]
		var type := info["type"] as int
		print("=> Starting test #%d: %s with %s" % [index+1, ["MOVE","ABSORB","RELEASE","WAIT"][type], info])
		match type:
			MOVE:
				move_player(info["to"])
			ABSORB:
				start_absorbing(info["orb"])
			RELEASE:
				start_releasing(info["orb"])
			WAIT:
				wait_for(info["secs"])
			_: assert(false)

		print("=> Waiting...")
		wait_for_timeout()
		yield(self, "test_executed")
		cancel_timeout()

		# Delay next test
		timer.wait_time = DELAY; timer.start()
		yield(timer, "timeout")
		index += 1
	print("=> ... All tests done!")

# Timeout management (assert on timeout)
# `wait_for_timeout()` / `cancel_timeout()`
var timeout_timer := Timer.new()
func wait_for_timeout(timeout=TIMEOUT):
	if not timeout_timer.is_inside_tree():
		timeout_timer.connect("timeout", self, "_on_timeout")
		add_child(timeout_timer)
	timeout_timer.wait_time = timeout
	timeout_timer.start()
func _on_timeout():
	assert("### Timeout when waiting for test completion ###")
func cancel_timeout():
	timeout_timer.stop()

func add_timer(secs) -> Timer:
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = secs
	timer.start()
	return timer

func wait_for(secs: float):
	assert(secs < TIMEOUT)
	var timer := add_timer(secs)
	yield(timer, "timeout")
	emit_signal("test_executed")
	timer.queue_free(); remove_child(timer)

func move_player(to: Vector3):
	if not tests_enabled:
		.move_player(to)
		return

	for _i in 5:
		var timer := add_timer(1.0)
		yield(timer, "timeout")
		timer.queue_free(); remove_child(timer)

		call_deferred("reload_spots")
		if Array(get_accessible_spots()).has(to): break

	prints("Spots:", get_accessible_spots())
	assert(Array(get_accessible_spots()).has(to)) # Notice: Test failed!
	prints("Move to:", to)

	.move_player(to)

func _on_walked(node: Spatial, to: Vector3):
	._on_walked(node, to)
	emit_signal("test_executed")

func _on_end_accessible(end_name: String):
	pass # Ignore (test already move player to end)

func _on_level_finished(cell: Vector3):
	._on_level_finished(cell)
	print("=> Level finished!")

#func start_absorbing(orb):
#	.start_absorbing(orb)

#func absorbing_ended(orb, behaviour):
#	.absorbing_ended(orb, behaviour)

func all_absorbed():
	.all_absorbed()
	emit_signal("test_executed")

#func start_releasing(orb):
#	.start_releasing(orb)

func release_orb_ended(orb: int, behaviour: int):
	.release_orb_ended(orb, behaviour)
	emit_signal("test_executed")
