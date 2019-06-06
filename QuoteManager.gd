extends Object

const Quote = preload("res://Quote.gd")
const Helper = preload("res://Helper.gd")

static func orb(prefix: String) -> int:
	return {
		"B": Orb.BLUE, "G": Orb.GREEN, "P": Orb.PURPLE,
		"R": Orb.RED, "Y": Orb.YELLOW, "N": Orb.GRAY }[prefix]

const _quotes = []
static func get_all_quotes() -> Array:
	if not _quotes.empty(): return _quotes

	var regex := RegEx.new()
	# Ex.: 'B-10-11' (orb: B, name: '10-11'), 'R-63-Outro', 'Y-Outro', 'R-Failed2', 'N-3' (nightmare), etc.
	var levels := PoolStringArray(["\\d{1,2}-(?:\\d{1,2}|Outro)","Outro","Failed-?\\d*","\\d*"])
	var err := regex.compile("^([BGPRYN])-(%s)" % levels.join("|")); assert(err == OK)

	var _quotes := []
	var translation := preload("res://data/quotes.en.translation")
	assert(not translation is PHashTranslation) # Compressed translations cannot be listed
	for key in translation.get_message_list():
		var m := regex.search(key); assert(m and m.strings.size() == 3)
		var quote := Quote.new()
		quote.key = key
		quote.orb = orb(m.get_string(1))
		quote.name = m.get_string(2)
		_quotes.append(quote)
	return _quotes

static func _get_all_failure_quotes() -> Array:
	var failure_quotes := []
	var quotes := get_all_quotes()
	for quote in quotes:
		if quote.name.find("Failed") != -1:
			failure_quotes.append(quote)
	assert(not failure_quotes.empty())
	return failure_quotes

static func get_failure_quotes(level: String, orbs: Array) -> Array:
	assert(not orbs.empty())
	var orb_quotes := {} # {enum Orb : [Quote]}
	for quote in _get_all_failure_quotes():
		orb_quotes[quote.orb] = orb_quotes.get(quote.orb, []) + [quote]
	var quotes := []
	for orb in orbs:
		var _quotes = orb_quotes[orb]
		quotes.append(_quotes[randi() % _quotes.size()])
	assert(quotes.size() == orbs.size())
	return quotes

# `levels` must be like `["Level10", "Level11"]`, `["Level63", "Outro"]`, etc.
static func get_quotes(levels: Array) -> Array:
	assert(levels.size() == 2)
	return _get_quotes(levels[0], levels[1]) + _get_quotes(levels[1], levels[0])

static func _level_number(level: String) -> int:
	var number := Helper.first_match("^Level(\\d{1,2})", level)
	return int(number) if number else -1

static func _get_quotes(from: String, to: String) -> Array: # [Quote]
	assert(from != to)
	var name: String
	if to == "Intro":
		return [] # Player restarted game from Intro
	if from == "Intro":
		return [] # Tutorial
	elif from != null and to == "Outro": # From last level to outro
		name = "%s-%s" % [_level_number(from), to]
	elif from == "Outro" and to == null: # Quotes when lighting torches
		name = "Outro"
	elif from.begins_with("Nightmare"):
		var number := from["Nightmare".length()]
		name = "N-%s" % int(number)
	else:
		name = "%d-%d" % [_level_number(from), _level_number(to)]

	var quotes := []; for quote in get_all_quotes():
		if quote.key.ends_with(name):
			quotes.append(quote)
	return quotes
