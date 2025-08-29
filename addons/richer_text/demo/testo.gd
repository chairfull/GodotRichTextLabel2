extends Node

@onready var label: RicherTextLabel = %label
@onready var reset: Button = %reset
@onready var advance: Button = %advance
@onready var reverse: Button = %reverse
@onready var slider: HSlider = %slider

func _ready() -> void:
	var anim := label.get_animation()
	if not anim:
		return
	reset.pressed.connect(anim.reset)
	advance.pressed.connect(anim.advance)
	reverse.pressed.connect(anim.reverse)
	
	#anim.started.connect(func(): print("Anim STARTED"))
	#anim.paused.connect(func(): print("Anim PAUSED"))
	#anim.continued.connect(func(): print("Anim CONTINUED"))
	anim.progressed.connect(func(p): slider.value = p * 100.0)
	#anim.finished.connect(func(): print("Anim FINISHED"))
	
	slider.drag_ended.connect(func(v): anim.progress = slider.value / 100.0)
