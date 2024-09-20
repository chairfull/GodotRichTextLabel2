@tool
extends RefCounted

var color: Color
var color_bg: Variant
var color_fg: Variant
var align: HorizontalAlignment
var font: String
var font_size := 0
var opened := {}
var pipes: Array
var stack: Array

func reset(rt: RicherTextLabel):
	color = rt.color
	color_bg = null
	color_fg = null
	align = rt.alignment
	font = rt.font
	font_size = rt.font_size
	clear()

func clear():
	opened.clear()
	pipes.clear()
	stack.clear()
