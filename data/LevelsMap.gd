extends Object # TODO: Use only static functions

var _DEBUG_ = Helper.DEBUG_ENABLED

const TWO_WAYS_LEVELS = [ # Levels played also in reverse
	"Level30", "Level31", "Level32", "Level33", "Level34"
]
const MAPPING = {
	# { level : end_name } : { level : start_name }?

	{"Intro":"End"} : {"Level1":"Start"},
	{"Level1":"End"} : {"Level2":"Start"},
	{"Level2":"End"} : {"Level3":"Start"},
	{"Level3":"End"} : {"Level4":"Start"},
	{"Level4":"End"} : {"Level10":"Start"},

	# Lifts
	{"Level10":"End"} : {"Level11":"Start"},
	{"Level11":"End"} : {"Level12":"Start"},
	{"Level12":"End"} : {"Level13":"Start"},
	{"Level13":"End"} : {"Level20":"Start"},

	# Torches
	{"Level20":"End"} : {"Level21":"Start"},
	{"Level21":"End"} : {"Level22":"Start"},
	{"Level22":"End"} : {"Level23":"Start"},
	{"Level23":"End"} : {"Level30":"Start"},

	# Purple and Red orbs
	{"Level30":"End-G"} : {"Level31":"Start"},
	{"Level31":"End"} : {"Level32":"Start"},
	{"Level32":"End"} : {"Level33":"Start"},
	{"Level33":"End"} : {"Level34":"Start"},
	{"Level34":"End"} : {"Level33":"End"}, # Player go back to start once red orb picked
	#{"Level33":"Start"} : {"Level32":"End"},
	#{"Level32":"Start"} : {"Level31":"End"},
	#{"Level31":"Start"} : {"Level30":"End"},

	{"Level30":"End-R"} : {"Level40":"Start"},
	{"Level40":"End"} : {"Level41":"Start"},
	{"Level41":"End"} : {"Level42":"Start"},
	{"Level42":"End"} : {"Level43":"Start"},
	{"Level43":"End"} : {"Level44":"Start"},
	{"Level44":"End"} : {"Level45":"Start"},
	{"Level45":"End"} : {"Level60":"Start"},

	{"Level60":"End"} : {"Level61":"Start"},
	{"Level61":"End"} : {"Level62":"Start"},
	{"Level62":"End"} : {"Level63":"Start"},
	{"Level63":"End"} : {"Outro":"Start"},

	{"Outro":"End"} : null
}

func _init():
	if _DEBUG_: _test() # DEBUG

func levels_between(level1, level2): # [String]? levels_between(String, String)
	assert(level1.find("_") == -1 and level2.find("_") == -1)
	var levels = _levels_from(level1, level2)
	if levels != null: return levels
	levels = _levels_from(level2, level1)
	assert(levels != null)
	return levels

# Returns level after `from_level` and before `to_level`, or null if none.
func _levels_from(from_level, to_level):
	assert(from_level.find("_") == -1 and to_level.find("_") == -1)
	var levels = []
	var ends = []; for end in get_ends():
		if end.keys()[0] == from_level:
			ends.append(end.values()[0])
	for end_name in ends:
		var level = from_level; var end = end_name
		while true:
			var after = level_after(level, end)
			if after == null: break
			level = after.keys()[0]
			if level == to_level: return levels
			levels.append(level)
	return null

# Returns the previous level of `level`, only if the player can go back to it.
func level_before(level, from_start_name): # {level:String : end:String}? level_before(String, String)
	assert(level.find("_") == -1)
	if not TWO_WAYS_LEVELS.has(level): return null
	var key = {level : from_start_name}
	for end in get_ends():
		if dict_eq(MAPPING[end], key): return end
	return null

func level_after(level, from_end_name): # {level:String : start:String}? level_after(String, String)
	assert(level.find("_") == -1)
	var key = {level : from_end_name}
	for end in get_ends():
		if dict_eq(end, key): return MAPPING[end]
	return null

### Private

static func get_ends():
	return MAPPING.keys()

static func dict_eq(dict1, dict2):
	if dict1 == null or dict2 == null: return false
	return dict1.hash() == dict2.hash()

func _test():
	assert(level_after("Outro", "End") == null)
	assert(level_after("Level1", "End").hash() == {"Level2":"Start"}.hash())
	assert(level_before("Level2", "Start") == null)
	assert(level_before("Level33", "Start").hash() == {"Level32":"End"}.hash())
	assert(levels_between("Level10", "Level13") == ["Level11", "Level12"])
