extends TroopAttribute

# Logic for retreat attribute can go here


func on_attack(defender: Unit):
	parent.can_move = true

func build_action() -> Action:
	var action: Action = Action.new()
	action.name = "Test"
	action.description = "Test action for the retreat attribute"
	action.setup(print_pressed)
	return action

func print_pressed():
	print('Action button pressed :D')
