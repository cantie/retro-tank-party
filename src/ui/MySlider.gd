extends HSlider
class_name MySlider

const ControlFocusComponentClass = preload("res://src/ui/ControlFocusComponent.gd")

var focus

func _ready() -> void:
	focus = ControlFocusComponentClass.new()
	add_child(focus)
