extends Object

const NBSP = "\u00a0" # No secable space

var key: String
var orb: int
var name: String

func get_text():
	return tr(key).replace("I ", "I"+NBSP)