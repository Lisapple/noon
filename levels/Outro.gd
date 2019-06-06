extends "res://TestGameGridMap.gd"

const Quote = preload("res://Quote.gd")
const QuotePanel = preload("res://QuotePanel.gd")

var ORB_SPOTS := {
	Orb.BLUE: 	Vector3(2,0,-4),
	Orb.GREEN: 	Vector3(6,0,-4),
	Orb.PURPLE:	Vector3(10,0,-4),
	Orb.RED: 	Vector3(14,0,-4),
	Orb.YELLOW:	Vector3(18,0,-4)
}

var QUOTE_KEYS := {
	Orb.BLUE:   "B-Outro",
	Orb.GREEN:  "G-Outro",
	Orb.PURPLE: "P-Outro",
	Orb.RED:    "R-Outro",
	Orb.YELLOW: "Y-Outro"
}

var current_orb = null

func _init():
	if _DEBUG_:
		progression.available_orbs = [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED] # DEBUG

func start():
	.start()
	var orbs = progression.available_orbs
	assert(orbs == [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED])

func init_path_extension(from_start:=true, from_ends:=true):
	.init_path_extension(true, false)

func get_spots() -> PoolVector3Array:
	var spots := Array(.get_spots())
	spots.erase(get_start())

	var orbs = progression.get_available_orbs()
	if orbs.has(Orb.YELLOW):
		if current_orb == null:
			current_orb = Orb.BLUE
		if ORB_SPOTS.has(current_orb):
			spots.append(ORB_SPOTS[current_orb])
			spots.erase(get_ends()[0])
	else:
		spots.erase(get_ends()[0])

	return PoolVector3Array(spots)

func _on_walked(node: Spatial, to: Vector3):
	._on_walked(node, to)

	var index = ORB_SPOTS.values().find(to)
	if index != -1:
		var orb = ORB_SPOTS.keys()[index]
		start_releasing(orb) # Release to matching torch

func release_orb_ended(orb: int, behaviour: int):
	.release_orb_ended(orb, behaviour)
	assert(behaviour == Behaviour.ABSORBED)
	current_orb += 1

	var quote := Quote.new()
	quote.key = QUOTE_KEYS[orb]; quote.orb = orb

	var panel := QuotePanel.new()
	panel.quotes = [ quote ]
	add_child(panel)

	yield(panel, "finished")
	remove_child(panel)
	reload_spots()