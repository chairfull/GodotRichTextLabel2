@tool
extends Node

@onready var rt_trans: RichTextAnimation = %rt_trans
@onready var progress: HSlider = %progress
@onready var waiting_bar: HSlider = %waiting
@onready var trans: CenterContainer = %trans
@onready var talker: Sprite2D = %talker
@onready var talker2: Sprite2D = %talker2
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var stars: Label = %stars
@onready var stars_anim: AnimationPlayer = %stars_anim
@onready var camera: Camera2D = %camera
@onready var wait_items: HBoxContainer = %wait_items
@onready var hold_items: HBoxContainer = %hold_items

@export var helmet: TestItem = preload("res://demo/helmet.tres")
@export var ring: TestItem = preload("res://demo/ring.tres")
@export var score := 10
@export var player := { name="Bob" }
@export var big_number := 123412516
var activetalker := "talker"

var messages := [
	"Let's go over some ~RichTextAnimation~ features.",
	"The ~[[w]~ or ~[[wait]~ tag...[w] Waits an amount of time.[w=2] Then shows more text.[w=4] User can skip waiting by manually pressing.",
	"The ~[[h]~ or ~[[hold]~ tag will hold until advance() is called. (Press any key.)[h] Then it shows more text.[h] Maybe confusing to users.",
	"The ~[[p]~ or ~[[pace]~ tag...[p=0.25] Can slow text down...[w][p=1.6] Or speed text up! Look how fast we are speaking![p=0.1] Down to a crawl![p=3.0] Or nearly instant!",
	"[p=0.5]The ~[[skip]~ tag... [skip]Can show all text at once.[;w=2] Good for [skip]making an impact[]![w=2] Up to you!",
	"[p=0.5]The ~[[$expression]~ tags can trigger expressions.[$print('Wee woo');$hop();w] Now let's wait till the end and then...[$print('The End');$hop();w]",
	#"[p=0.5]The <<> tags also can trigger expressions.<print('Wee woo')><hop()>[w] Now let's wait till the end and then...<print('The End')><hop()>[w]",
	"[p=0.5]The ~[[#bookmark]~ tag signals on_bookmark when it occurs.[#bookmark;w] Like that.[#or this;w] Useful for triggering animations.[#end;w]",
	#"[p=0.5]The ##bookmark tag signals on_bookmark when it occurs.#bookmark[w] Like that.#or_this[w] Useful for triggering animations.#end",
	'[p=0.25]Blueguy said#talker "It\'s good to be blue!"[w] to which 2Blue said#talker2 "I can\'t agree more!"[w] Together they sang,#both "We love being blue together!"',
	"[p=0.25]Sometimes you may *sigh*[w] or *cough*[w] or maybe do a *punch*.[w] This is what the on_stars signals are for.",
	"~The End~\nNow create some cool stories!",
]
var current := -1
var waiting := false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	wait_items.modulate.a = 0.0
	hold_items.modulate.a = 0.0
	
	progress.value_changed.connect(func(v):
		rt_trans.progress = v)
	
	rt_trans.on_bookmark.connect(func(bookmark: String):
		if bookmark in ["talker", "talker2", "both"]:
			activetalker = bookmark
		else:
			animation_player.play(&"hop")
			print_rich("Bookmark: [color=yellow]%s" % bookmark)
	)
	
	rt_trans.on_quote_started.connect(func(s):
		if activetalker == "both":
			talker.modulate = Color(2.0, 2.0, 2.0, 1.0)
			talker2.modulate = Color(2.0, 2.0, 2.0, 1.0)
		else:
			self[activetalker].modulate = Color(2.0, 2.0, 2.0, 1.0)
		print_rich("Quote: [color=yellow]%s" % s))
	
	rt_trans.on_quote_finished.connect(func():
		if activetalker == "both":
			talker.modulate = Color.WHITE
			talker2.modulate = Color.WHITE
		else:
			self[activetalker].modulate = Color.WHITE)
	
	rt_trans.on_stars_started.connect(func(s: String):
		%stars.text = "*%s*" % [s.to_upper()]
		%stars_anim.play("stars")
		match s:
			"sigh": %camera.add_trauma(0.5)
			"cough": %camera.add_trauma(0.75)
			"punch": %camera.add_trauma(1.0)
		print_rich("Stars: [color=yellow]%s" % s))
	
	rt_trans.wait_started.connect(func(): wait_items.modulate.a = 1.0)
	rt_trans.wait_finished.connect(func(): wait_items.modulate.a = 0.0)
	rt_trans.hold_started.connect(func(): hold_items.modulate.a = 1.0)
	rt_trans.hold_finished.connect(func(): hold_items.modulate.a = 0.0)
	
	rt_trans.set_bbcode("Press ~<<Space>~ to start.")

func hop():
	animation_player.play(&"hop")

func next_message():
	if current < len(messages)-1:
		current += 1
	else:
		current = 0
	
	rt_trans.autostyle_numbers = false
	# Hide ctc on final message.
	rt_trans.ctc_on_finished = current != len(messages)-1
	rt_trans.set_bbcode(messages[current])
	
	waiting = true
	await rt_trans.anim_finished
	waiting = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	progress.value = rt_trans.progress
	waiting_bar.value = rt_trans.get_wait_delta()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	# Key pressed while on trans tab?
	if event.is_action_pressed("ui_accept", false, true) and trans.visible:
		get_viewport().set_input_as_handled()
		if waiting:
			rt_trans.advance()
		else:
			next_message()

func add_numbers(a, b):
	return a + b

func get_items():
	return [helmet, ring]
