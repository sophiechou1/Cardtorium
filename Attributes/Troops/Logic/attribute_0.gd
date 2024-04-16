extends TroopAttribute

# Contains the logic for the dash attribute

var has_attacked: bool = false

func on_attack(defender: Unit):
    has_attacked = true

func on_moved(from: Vector2i, to: Vector2i):
    if not has_attacked:
        parent.can_attack = true

func reset():
    has_attacked = false