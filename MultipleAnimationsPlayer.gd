extends AnimationPlayer

#class TweenAnimation extends Animation:
#	var tween_node

# Can queue value and transform type animations
var animations_queue = []

func _ready():
	self.connect("animation_started", self, "_on_animation_started")
	self.connect("animation_finished", self, "_on_animation_finished")

func queue(name, animation): # void queue(String, Animation)
	animations_queue.append(animation)
	add_animation(name, animation)
	if animations_queue.size() == 1: # Play next if queue contains no other animations
		.queue(name)

func _on_animation_started(name):
	print("Start playing ", name)
	var animation = get_animation(name)
	animations_queue.erase(animation)

func queue_next_animation():
	if animations_queue.size() > 0:
		var next_animation = animations_queue.front(); animations_queue.pop_front()
		.queue(find_animation(next_animation))

func clear_queue():
	.clear_queue()
	stop(true)
	animations_queue.clear()

func _on_animation_finished():
	clear_caches()
	queue_next_animation()