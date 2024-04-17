extends Control

@onready var hbox: HBoxContainer =  get_node("MarginContainer/ColorRect/MarginContainer/HBoxContainer")
@onready var end_button: Button =  get_node("MarginContainer/ColorRect/MarginContainer/HBoxContainer/End_Turn")
var action_button_scene = preload("res://Scenes/Action_Button/action_button.tscn")

# Pattern which action buttons will match
var pattern: String = "action_*"

## Displays a player's default dock
func display_default():
    var action_nodes: Array[Node] = hbox.find_children(pattern, "", false, false)
    for button in action_nodes:
        button.queue_free()
    end_button.visible = true

## Displays actions for a troop
func display_troop(troop: Troop) -> Array[Button]:
    end_button.visible = false 
    var actions: Array[Action] = troop.actions
    var i = 0
    var buttons: Array[Button] = []
    for action in actions:
        var scene = action_button_scene.instantiate()
        scene.setup(action)
        scene.name = "action_%d" % [i]
        hbox.add_child(scene)
        buttons.append(scene)
        i += 1
    return buttons