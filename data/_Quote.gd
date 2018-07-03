extends Node

### Constants

var ORBS = [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED, Orb.YELLOW]

### Variables

var restart_quotes = {} # {key:String : enum Orb}

func _ready():
	_test() # DEBUG
	for orb in ORBS:
		for i in range(1, 15):
			var key = "%s-Restart%s" % [Orb.prefix(orb), i if i > 1 else ""]
			if tr(key) != key: restart_quotes[key] = orb
			else: break

# Return level identifier, like "15" for "Level15".
func level_id(level): # String level_id(String)
	assert(level.find("_") == -1)
	if ["Intro","Outro"].has(level):
		return level
	else:
		var regex = RegEx.new(); assert(regex.compile("^[Ll]evel(\\d{1,3})$") == OK)
		var m = regex.search(level); assert(m.strings.size() == 2)
		var identifier = m.strings[1]; assert(int(identifier) > 0)
		return String(identifier)

func get_restart_quotes(level_name, orbs):
	assert(not orbs.empty())

	var key; var orb; while not orbs.has(orb):
		var index = randi() % restart_quotes.size()
		key = restart_quotes.keys()[index]; orb = restart_quotes[key]
	return {tr(key) : Orb.color(orb)}

# {String : Color}? get_quotes([String], enum Orb)
func get_quotes(levels, orbs):
	assert(levels.size() == 2)

	var quotes = {}
	var from = level_id(levels[0]); var to = level_id(levels[1])
	for orb in ORBS:
		var color = Orb.color(orb)
		var name = "%s%s-%s" % [Orb.prefix(orb), from, to] # Like "B12-13"
		if tr(name) != name: quotes[tr(name)] = color
		var inv_name = "%s%s-%s" % [Orb.prefix(orb), to, from] # Like "B13-12"
		if tr(inv_name) != inv_name: quotes[tr(inv_name)] = color
	#if not from_level.begins_with("Intro"): assert(not quotes.empty())
	return quotes

func quotes_for_transition(from_level, to_level, season=Season.SUMMER):
	return get_quotes([from_level, to_level], progression.available_orbs)

func _test():
	var quotes = quotes_for_transition("Level1", "Level2")
	var inv_quotes = quotes_for_transition("Level2", "Level1")
	assert(quotes.hash() == inv_quotes.hash())
	assert(quotes_for_transition("Intro", "Level1").empty())
	assert(quotes_for_transition("Level5", "Level10").empty())
