extends Node

const ENABLED = true
const LOG_ENABLED = true

static func False(cond, message):
	if ENABLED:
		if LOG_ENABLED and not cond:
			print("*** Assertion: %s ***" % message)
		assert(cond)

static func Exist(value):
	False(value != null, "The value must not be null")

static func Null(value):
	False(value != null, "The value must not be null")