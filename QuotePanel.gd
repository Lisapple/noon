extends "res://BlurPanel.gd"

var _DEBUG_ = Helper.DEBUG_ENABLED

const Quote = preload("res://Quote.gd")
const QuoteLabel = preload("res://QuoteLabel.gd")
const QuoteManager = preload("res://QuoteManager.gd")

signal finished()

var FADE_DURATION := 0.2 if _DEBUG_ else 0.7
var DURATION_PER_WORD := 0.04 if _DEBUG_ else 0.37

func set_transition(from_level: String, to_level: String):
	var levels := [from_level, to_level]
	assert(levels and levels.size() == 2)
	quotes = QuoteManager.get_quotes(levels)

var quotes := []

func _duration(quote: Quote) -> float:
	return quote.get_text().split(" ", false).size() * DURATION_PER_WORD

var timer := Timer.new()
var tween := Tween.new()
func _ready():
	timer.one_shot = true
	add_child(timer)
	add_child(tween)

	self_modulate.a = 0
	tween.interpolate_property(self, "self_modulate", Color(0,0,0,0), Color(1,1,1),
		FADE_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_method(self, "set_blur", 1.0, 3.4,
		FADE_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")

	assert(not quotes.empty())
	var offset := 40.0
	for quote in quotes:
		var label := QuoteLabel.new()
		label.set_anchors_and_margins_preset(PRESET_WIDE, PRESET_MODE_KEEP_SIZE, 50)
		label.add_color_override("font_color", Orb.color(quote.orb))
		label.add_font_override("font", QuoteLabel.QuoteFont.new(57))
		label.text = quote.get_text()
		add_child(label)
		VisualServer.canvas_item_set_z_index(label.get_canvas_item(), z_index+1)

		# Fade in
		label.fade_in()
		var pos := label.rect_position
		tween.interpolate_property(label, "rect_position", pos + Vector2(offset, 0), pos,
			0.45, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.start()
		
		var duration := _duration(quote)
		timer.wait_time = duration; timer.start()
		yield(timer, "timeout")

		# Fade out
		label.fade_out()
		tween.interpolate_property(label, "rect_position", pos, pos + Vector2(offset, 0),
			0.35, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.start()
		offset = -offset # Alternate left/right transition
		
		timer.wait_time = 0.4; timer.start()
		yield(timer, "timeout")

		label.queue_free(); remove_child(label)

	tween.interpolate_method(self, "set_blur", 3.4, 1.0,
		FADE_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "self_modulate", Color(1,1,1), Color(0,0,0,0),
		FADE_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")

	emit_signal("finished")
	tween.stop_all()
