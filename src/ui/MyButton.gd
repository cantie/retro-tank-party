extends Button
class_name MyButton

const ControlFocusComponentClass = preload("res://src/ui/ControlFocusComponent.gd")

enum ButtonType {
	OK,
	CANCEL,
}
@export var button_type: ButtonType = ButtonType.OK

var focus

func _ready() -> void:
	focus = ControlFocusComponentClass.new()
	add_child(focus)
	
	self.pressed.connect(self._on_pressed)

func _on_pressed() -> void:
	Sounds.play("Select" if button_type == OK else "Back")

