extends TroopAttribute

# Logic for the doctor attribute

func build_action() -> Action:
	var options: Array[Vector2i] = []
	for x in range(parent.pos.x - 1, parent.pos.x + 2):
		if x < 0:
			continue
		elif x > board.SIZE.x:
			break
		for y in range(parent.pos.y - 1, parent.pos.y + 2):
			if y < 0:
				continue
			elif y > board.SIZE.y:
				break
			if x == parent.pos.x and y == parent.pos.y:
				continue
			var troop = board.units[x][y]
			if troop == null:
				continue
			elif troop is Troop:
				if troop.owned_by != parent.owned_by:
					continue
				options.append(Vector2i(x, y))
	if not options:
		return null
	var action = Action.new()		
	action.setup(parent.game, heal_on_tile, options)
	action.name = "Doctor"
	action.description = attribute.description
	return action


func heal_on_tile(tile: Vector2i):
	var ally: Troop = board.units[tile.x][tile.y]
	var amount: int = parent.health / 2
	ally.health = clampi(ally.heath + amount, 0, ally.base_stats.health)