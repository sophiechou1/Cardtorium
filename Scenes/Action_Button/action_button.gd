extends Button


func setup(action: Action):
	var label: Label = $Label
	label.text = action.name
	tooltip_text = action.description
	custom_minimum_size = Vector2(100, 50)
