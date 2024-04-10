extends Node

## Class which contains the logic and data required to run a game.
## Does not contain any rendering functions or input processing.
class_name Game

## Contains the game's data. Saving the board to disk allows
## saving and loading games.
var board: Board = Board.new()

## Number of players
var num_players: int

## Notifies other nodes when a set of terrain tiles is changed.
signal terrain_updated(changed: Array[Vector2i], terrain: Board.Terrain)
## Emitted when a troop is placed.
signal troop_placed(troop: Troop, pos: Vector2i)
## Emitted when a player ends their turn.
signal turn_ended(local_id: int)
## Emitted when a troop is moved
signal troop_moved(troop: Troop, path: Array)
## Emitted when a unit is removed from the board.
signal unit_removed(unit: Unit)
## Emitted right before (or maybe after) player's turn switches over
signal render_topbar(turn: int, player: Player)
## Emitted when a city is placed
signal city_placed(city: City)
## Emitted when a player claims territory
signal territory_claimed(claimed: Array[Vector2i], player_index: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	board = Board.new()
	# Creates a new board of size 11 x 11
	var width = 11
	var height = 11
	board.setup(width, height, 2)
	# for i in range(len(board.players)):
	# 	board.players[i].setup()
	board.players[0].setup(self, Vector2i(0,board.SIZE.y / 2), 0)
	board.players[1].setup(self,Vector2i(board.SIZE.x - 1,board.SIZE.y / 2), 1)
	num_players = 2

## Changes the terrain for an array of tiles
func set_terrain(terrain: Board.Terrain, location: Array[Vector2i]):
	for position in location:
		board.tiles[position.x][position.y] = terrain
	terrain_updated.emit(location, terrain)

## Takes a card as input, and places that card at position x, y.
func place_card(card: Card, x: int, y: int):
	match (card.type):
		# Places a troop card
		Card.CardType.TROOP:
			var troop: Troop = Troop.new(self, card)
			troop.owned_by = board.current_player
			board.units[x][y] = troop
			troop.pos = Vector2i(x, y)
			troop_placed.emit(troop, Vector2i(x, y))

## Places the nth card in the player's hand onto the board at position x, y
func place_from_hand(index: int, x: int, y: int):
	var player: Player = board.players[board.current_player]
	var card: Card = player.hand[index]
	if player.resources < card.cost:
		return
	player.remove_from_hand(index)
	render_topbar.emit(board.turns, board.players[board.current_player])
	self.place_card(card, x, y)

## Goes to the next player's turn
func end_turn():
	var prev = board.current_player
	# Updates current_player
	board.current_player += 1
	if board.current_player == num_players:
		board.current_player = 0
		board.turns += 1
	# Sets next player up to begin their turn
	board.players[board.current_player].begin_turn()
	render_topbar.emit(board.turns, board.players[board.current_player])
	
	# Lets other nodes know that a player has ended their turn
	turn_ended.emit(prev, board.players[board.current_player])

	print("end turn clicked")
	print(board.current_player)
	print(board.turns)

	

## Claims territory in a radius for a player.
## Passing a -1 for the player parameter will unclaim territory.
## If a player is not passed, defaults to current player
func claim_territory(pos: Vector2i, radius: int, player: int = -2):
	if player == -2:
		player = board.current_player
	# Claims territory
	var claimed: Array[Vector2i] = []
	for x in range(pos.x - radius, pos.x + radius + 1):
		if x < 0:
			continue
		elif x >= board.SIZE.x:
			break
		for y in range(pos.y - radius, pos.y + radius + 1):
			if y < 0:
				continue
			elif y >= board.SIZE.y:
				break
			var old = board.territory[x][y]
			board.territory[x][y] = player
			if old != -1:
				board.players[old].territory -= 1
				board.players[old].calculate_rpt()
			board.players[player].territory += 1
			claimed.append(Vector2i(x, y))
	# Emits signals
	board.players[player].calculate_rpt()
	territory_claimed.emit(claimed, player)
	render_topbar.emit(board.turns, board.players[player])


## Moves a troop from one position to another.
## WARNING: If the move is invalid, then this function will throw
## an error.
func troop_move(troop: Troop, tile: Vector2i):
	# Moves the unit
	self.board.units[troop.pos.x][troop.pos.y] = null
	self.board.units[tile.x][tile.y] = troop
	# Sets the troop's position and stores its old position
	var from = Vector2i(troop.pos.x, troop.pos.y)
	troop.pos = tile
	# Emits the move signal
	var path: Array = troop.move_graph[tile]
	troop.clear_fog()
	troop_moved.emit(troop, path)

## Removes a unit from the board
func remove_unit(unit: Unit):
	board.units[unit.pos.x][unit.pos.y] = null
	unit_removed.emit(unit)


## Places a city
func place_city(pos: Vector2i):
	if board.buildings[pos.x][pos.y] != null:
		return
	var city: City = City.new()
	city.position = 64 * pos
	board.buildings[pos.x][pos.y] = city
	city_placed.emit(city)
