class_name RTxtOutline extends Resource

enum Style { OUTLINE, TEXT, OUTLINE_AND_TEXT }

@export var style := Style.OUTLINE
@export var size := 2.0
@export var color := Color.WHITE
@export var position := Vector2.ZERO
@export_range(-180, 180, 1.0, "radians_as_degrees") var rotation := 0.0
@export var skew := 0.0
@export var scale := Vector2.ONE
