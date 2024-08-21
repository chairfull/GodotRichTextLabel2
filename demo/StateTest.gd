@tool
extends Node

@export var score := 10
@export var player := { name="Bob" }
@export var big_number := 123412516

@export var helmet: TestItem = preload("res://demo/helmet.tres")
@export var ring: TestItem = preload("res://demo/ring.tres")

func add_numbers(a, b):
	return a + b

func get_items():
	return [helmet, ring]

func _ready() -> void:
	%progress.value_changed.connect(func(v):
		%rt_trans.progress = v)
	
