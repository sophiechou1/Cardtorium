extends Button


var index: int

func setup(action: Action, _index: int):
	var label: Label = $Label
	label.text = action.name
	tooltip_text = action.description
	custom_minimum_size = Vector2(100, 50)
	index = _index

signal pressed_with(index: int)

func _pressed():
	pressed_with.emit(index)