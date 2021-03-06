extends Node

# Starts at 1 to avoid "if" to fail (`var orb = Orb.BLUE; if orb: ...` would fail)
enum { BLUE=1, GREEN, PURPLE, RED, YELLOW, GRAY }
const ALL = [ BLUE, GREEN, PURPLE, RED, YELLOW, GRAY ]

const PREFIXES = { "B":BLUE, "G":GREEN, "P":PURPLE, "R":RED, "Y":YELLOW, "N":GRAY }

static func with(prefix: String) -> int:
	return PREFIXES[prefix]

static func prefix(orb: int) -> String:
	var index = PREFIXES.values().find(orb)
	return PREFIXES.keys()[index]

static func color(orb: int, season:=Season.SUMMER) -> Color:
	if orb == Orb.GRAY:
		return Color(0.7,0.7,0.7,1)
	return Color({
		Season.SUMMER: {BLUE:"0F81B6", GREEN:"06DC74", PURPLE:"A15DB2", RED:"E13C49", YELLOW:"FFD352"},
		Season.AUTUMN: {BLUE:"2986B1", GREEN:"27D380", PURPLE:"A16BAF", RED:"D8525D", YELLOW:"F3D067"},
		Season.WINTER: {BLUE:"3E84A3", GREEN:"41C485", PURPLE:"9A70A3", RED:"C8636C", YELLOW:"DEC475"},
		Season.SPRING: {BLUE:"618DA1", GREEN:"67BB92", PURPLE:"9B80A1", RED:"BF7E84", YELLOW:"D1C08D"}
	}[season][orb])

static func particle_color(orb: int, season:=Season.SUMMER) -> Color:
	var c = color(orb, season)
	c.s *= 1.2; c.v *= 1.3
	return c