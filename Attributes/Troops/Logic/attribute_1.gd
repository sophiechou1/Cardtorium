extends TroopAttribute

# Logic for retreat attribute can go here


func on_attack(defender: Unit):
	parent.can_move = true