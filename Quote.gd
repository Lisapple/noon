extends Object

const NBSP = "\u00a0"

var key
var orb
var name

func get_text():
	return tr(key).replace("I ", "I"+NBSP)