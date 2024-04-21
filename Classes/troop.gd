extends Unit

## Class which represents a troop on the board.
class_name Troop

## The troop id
var id: int = 0
## Whether or not the troop can move
var can_move: bool = false
## Whether or not the troop can attack
var can_attack: bool = false
## Whether or not the troop can act
var can_act: bool = false
## Graph of tiles that the troop can move to.
var move_graph = null
## Stores the troop's attributes
var attributes: Array[TroopAttribute] = []
## Defense of the card
var defense: int
## Movement of the card
var movement: int
## All possible actions that the troop can take
var actions: Array[Action]
## A list of all troops / buildings that this troop can attack
var attack_list: Dictionary

## Initiallizes a troop object from a card.
func _init(_game: Game, card: Card=null):
	self.game = _game
	self.id = card.id
	self.base_stats = card
	attack = base_stats.attack
	defense = base_stats.defense
	movement = base_stats.movement
	rng = base_stats.attack_range
	health = base_stats.health
	game.turn_ended.connect(reset)
	owned_by = game.board.current_player
	card_type = Card.CardType.TROOP
	# Loads attributes
	for attribute_id in self.base_stats.attributes:
		var attribute_file = load('res://Attributes/Troops/Logic/attribute_{0}.gd'.format({0:attribute_id}))
		if attribute_file == null:
			continue
		var attribute: TroopAttribute = attribute_file.new()
		attribute.setup(attribute_id, game, self)
		attributes.append(attribute)

## Clears fog in a radius around the card
func clear_fog():
	var clear_tiles: Array[Vector2i] = []
	var temp = null
	for attribute in attributes:
		temp = attribute.clear_fog(pos)
		if temp != null:
			break
	if temp == null:
		for x_off in range(-1, 2):
			for y_off in range(-1, 2):
				var tile: Vector2i = pos + Vector2i(x_off, y_off)
				if tile.x < 0 or tile.y < 0:
					continue
				elif tile.x >= game.board.SIZE.x or tile.y >= game.board.SIZE.y:
					continue
				clear_tiles.append(tile)
	else:
		for tile in temp:
			clear_tiles.append(tile as Vector2i)
	game.board.players[owned_by].clear_fog(clear_tiles)

## Helper function which returns all tiles within a certain
## radius of the center.
func _get_surrounding(center: Vector2i, radius: int) -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	for x_off in range( - radius, radius + 1):
		for y_off in range( - radius, radius + 1):

			if x_off == 0 and y_off == 0:
				continue
			output.append(center + Vector2i(x_off, y_off))
	return output

## Builds a graph of the tiles that the unit can move to.
func build_graph():
	var graph: Dictionary = {}
	if not can_move:
		graph[pos] = [pos]
		move_graph = graph
		return
	var x = pos.x
	var y = pos.y
	var start = Vector2i(x, y)
	var frontier: Array = []
	# Elements in the frontier_data take the form
	# [strength, dist, [path_to_tile]]
	var frontier_data: Dictionary = {}
	var strength: float = float(self.base_stats.movement)
	for surround in _get_surrounding(start, 1):
		var new_strength = self._calc_move_cost(strength, start, surround)
		if new_strength < 0:
			continue
		# Deep copies surround for the path
		var to = Vector2i(surround.x, surround.y)
		var path = [start, to]
		# Adds nodes to the frontier
		frontier.append(to)
		frontier_data[to] = [new_strength, 0, path]
	# Runs breadth-first search
	while frontier:
		var tile = frontier.pop_front()
		strength = frontier_data[tile][0]
		var dist = frontier_data[tile][1]
		var path = frontier_data[tile][2]
		graph[tile] = path
		# If the troop has no strength left, cannot move further
		if strength <= 0:
			continue
		# Search surrounding tiles
		for surround in _get_surrounding(tile, 1):
			var new_strength = self._calc_move_cost(strength, tile, surround)
			if new_strength < 0:
				continue
			var to = Vector2i(surround.x, surround.y)
			var new_dist = (tile - start).length_squared()
			if to == start:
				continue
			# If the node is in the frontier, check if the current path is better or worse
			elif to in frontier_data:
				var old_strength = frontier_data[to][0]
				var old_dist = frontier_data[to][1]
				if new_strength < old_strength:
					continue
				elif new_dist >= old_dist and new_strength == old_strength:
					continue
				if to not in frontier:
					frontier.append(to)
			else:
				frontier.append(to)
			var new_path = path + [to]
			frontier_data[to] = [new_strength, new_dist, new_path]
	self.move_graph = graph

## Internal function which determines the cost of moving from a tile to a tile.[br][br]
##
## This is used in [method build_graph] to determine where a unit can move to. Attributes which
## override the [method TroopAttribute.calc_move_cost] method can change the behavior of this
## method.[br][br]
##
## [b]Parameters:[/b][br]
## [param strength]: An approximation to how many tiles this unit can move[br]
## [param from]: Tile that the unit is moving from[br]
## [param to]: Tile that the unit is moving to. Should be 1 tile away from [param from][br]
## [b]Returns: [float][/b][br]
## A number which represents approximately how much farther a unit can move. A return
## of 0 indicates that the unit can no longer move after going to [param to]. A return of
## -1 indicates that the unit cannot move to [param to]. Non-integer returns are allowed.
func _calc_move_cost(strength: float, from: Vector2i, to: Vector2i) -> float:
	var board = game.board
	# Checks if destination is even on the board
	if to.x < 0 or to.y < 0 or to.x >= board.SIZE.x or to.y >= board.SIZE.y:
		return -1
	var dest_type: Board.Terrain = board.tiles[to.x][to.y]
	# Check if the destination tile contains another troop, skip if it does
	var unit_at_destination = board.units[to.x][to.y]
	if unit_at_destination != null and unit_at_destination is Troop:
		return - 1
	# Checks if any attributes override the behavior of calc_move_cost
	for attr in attributes:
		var value = attr.calc_move_cost(strength, from, to, board)
		if value != null:
			return value
	# Checks if the move is even discovered
	if not board.players[self.owned_by].discovered[to.x][to.y]:
		return - 1
	# Checks terrain type
	if dest_type == Board.Terrain.FOREST:
		return 0
	elif dest_type == Board.Terrain.MOUNTAIN:
		return 0
	elif dest_type == Board.Terrain.WATER:
		return - 1
	# Checks for zone-of-control
	var temp: Vector2i = Vector2i.ZERO
	for x_off in range(-1, 2):
		temp.x = to.x + x_off
		if temp.x < 0 or temp.x >= board.SIZE.x:
			continue
		for y_off in range(-1, 2):
			temp.y = to.y + y_off
			if temp.y < 0 or temp.y >= board.SIZE.y:
				continue
			var unit: Unit = board.units[temp.x][temp.y]
			if unit != null and owned_by != unit.owned_by:
				return 0
	# TODO: Check if there is an enemy nearby to apply zone-of-control
	return max(strength - 1, 0)

## Builds an array of tiles that the unit can attack
func build_attack_list():
	attack_list = {}
	if not can_attack:
		return
	for x in range(pos.x - rng, pos.x + rng + 1):
		if x < 0:
			continue
		elif x >= game.board.SIZE.x:
			break
		for y in range(pos.y - rng, pos.y + rng + 1):
			if y < 0:
				continue
			elif y >= game.board.SIZE.y:
				break
			if game.board.units[x][y] != null:
				var troop: Troop = game.board.units[x][y]
				if troop.owned_by == owned_by:
					continue
				attack_list[Vector2i(x, y)] = troop

## Called when the unit is attacked
func being_attacked(attacker: Unit, atk: int, attack_force: float) -> int:
	# Calculates your defense force
	var def_force = self.defense * float(health)/float(base_stats.health)
	# Damages the unit
	var damage = floor((attack_force/(attack_force+def_force))*atk)
	health -= damage
	# If the troop is dead, then it dies
	if health <= 0:
		health = 0
		game.remove_unit(self)
		return 0
	# Runs through attributes
	for attr in attributes:
		attr.on_attacked(attacker)
	# Calculates counter damage
	var counter_damage: int = floor((def_force/(attack_force+def_force))*defense)
	return counter_damage

## Attacks another unit
func attack_unit(defender: Unit):
	if not can_attack:
		return
	var atk_force  = attack * float(self.health)/float(base_stats.health)
	health -= defender.being_attacked(self, attack, atk_force)
	# Prevents the unit from doing other actions
	can_act = false
	can_attack = false
	can_move = false
	# If the troop is dead, then it dies
	if health <= 0:
		health = 0
		game.remove_unit(self)
	# Runs through attributes if it survives
	for attr in attributes:
		attr.on_attack(defender)
	if not can_act and not can_attack and not can_move:
		game.troop_toggle_act.emit(self)

## Moves a troop from one position to another
func move(destination: Vector2i):
	if not can_move or game.board.units[destination.x][destination.y] != null:
		return
	# Moves the unit
	var from: Vector2i = Vector2i(pos.x, pos.y)
	game.board.units[from.x][from.y] = null
	game.board.units[destination.x][destination.y] = self
	pos = destination
	# Prevents unit from doing other actions
	can_act = false
	can_attack = false
	can_move = false
	# Emits the move signal
	var path: Array = move_graph[destination]
	clear_fog()
	game.troop_moved.emit(self, path)
	# Runs attributes
	for attr in attributes:
		attr.on_moved(from, destination)
	# Emits the done signal
	if not can_act and not can_attack and not can_move:
		game.troop_toggle_act.emit(self)

## Clears data which is generated on selection
func clear():
	move_graph = {}
	attack_list = {}
	actions = []

## Resets a troop at the end of a turn
func reset(prev: int, player: Player):
	clear()
	# Resets abilities
	can_move = true
	can_attack = true
	can_act = true
	# Sets all stats back to default
	attack = base_stats.attack
	defense = base_stats.defense
	rng = base_stats.attack_range
	movement = base_stats.movement
	# Runs through attributes
	for attr in attributes:
		attr.reset()
	# game.troop_toggle_act(self)

## Builds the troop's action list
func build_action_list():
	actions = []
	if not can_act:
		return
	# Checks if the troop is able to claim territory
	# If so, builds the claim action
	if game.board.territory[pos.x][pos.y] == owned_by:
		var claim = Action.new()
		claim.setup(game, claim_territory)
		claim.name = "Claim"
		claim.description = "Claims territory in a 1-tile radius"
		actions.append(claim)
	# Adds attribute actions
	for attr in attributes:
		var action = attr.build_action()
		if action != null:
			actions.append(action)

## Claims territory in a 1-tile radius for the troop
func claim_territory():
	game.claim_territory(pos, 1, owned_by)

## Runs a certain action
## Returns whether or not the action needs to wait on player input.
func act(index: int) -> bool:
	if index >= len(actions):
		return false
	elif not can_act:
		return false
	can_move = false
	can_attack = false
	can_act = false
	var input_needed = actions[index].execute()
	if not can_act and not can_attack and not can_move:
		game.troop_toggle_act.emit(self)
	return input_needed
