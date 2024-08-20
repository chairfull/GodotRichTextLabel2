@tool
extends Node

class Item extends Resource:
	@export var name: String
	@export var color: Color
	func _init(n: String, c: Color):
		name = n
		color = c
	func to_string_nice():
		return "[%s;b]%s[]" % [color, name]

@export var score := 10
@export var player := "John"
@export var big_number := 123412516

@export var helmet := Item.new("Nice Helmet", Color.DEEP_SKY_BLUE)
@export var ring := Item.new("Pink Ring", Color.HOT_PINK)

@export var items := {
	"sword": {name="Sword", damage=3},
	"shield": {name="Shield", deffence=2}
}

func my_func(key: String, num: int):
	return items[key].name + "x" + str(num)
