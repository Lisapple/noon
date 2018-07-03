extends MeshInstance

signal particles_bounced(node, orb, position)
signal particles_finished(node, orb, behaviour, callback)

var orb setget set_orb, get_orb
func get_orb():
	return orb
func set_orb(value):
	orb = value

var player = AnimationPlayer.new()
func _ready():
	add_child(player)

func get_player():
	return player

func bounced(orb, position): # void bounced(Orb, Vector3)
	emit_signal("particles_bounced", self, orb, position)

func finished_moves(orb, behaviour, callback): # void finished_moves(Orb, Behaviour, String)
	emit_signal("particles_finished", self, orb, behaviour, callback)
	queue_free(); get_parent().remove_child(self)
