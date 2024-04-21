extends Node2D

var troop_scene = preload ("res://Scenes/Rendering/rendered_troop.tscn")
var card: Card

const TILE_SIZE = 64
@onready var game: Game = $Game
var selected_index = -1
var selected_tile: Vector2i = Vector2i()
signal card_placed(card_index: int)
@onready var move_renderer = $MoveRender
@onready var hand_renderer = $GUI_Renderer/HandRenderer
@onready var action_bar = $GUI_Renderer/Control/ActionBar
#@onready var ter_renderer = $TerrainRenderer
var active_unit: Unit = null
var action_input_wait: bool = false
var action_input_options: Array[Vector2i] = []
var valid_tiles: Array[Vector2i] = []

## States of the high-level state machine which represents the game
enum States {
	## Default state when nothing is selected
	DEFAULT, 
	## When a card in the hand is selected
	CARD_SELECTED, 
	## State when a unit on the board is selected
	UNIT_SELECTED,
	## State when a unit is awaiting input to perform an action
	UNIT_ACTION_INPUT,
	## State when an animation is playing
	ANIMATION_PLAYING
}
## The current state of the game
var state: States = States.DEFAULT

# Called when the node enters the scene tree for the first time.
func _ready():
	# Renders the background
	var board: Board = game.board
	var background: Sprite2D = $Background
	background.region_rect.size = TILE_SIZE * Vector2(board.SIZE.x+2, board.SIZE.y+2)
	# Renders the tiles
	var terrain: TileMap = $TerrainRenderer
	terrain.board = board
	# terrain.render_all()
	# Renders fog
	var fog: TileMap = $FogRenderer
	fog.setup(board)
	# Sets up hand rendering
	for player in board.players:
		hand_renderer.connect_to_player(player)
	board.players[0].begin_turn()
	game.render_topbar.emit(board.turns, board.players[board.current_player])

	var camera = $Camera2D
	camera.selected_tile.connect(self.on_selected_tile)
	hand_renderer.card_selected.connect(self.on_card_selected)
	game.turn_ended.connect(on_turn_ended)

## Called when the user clicks on a card in their hand.
func on_card_selected(card_index: int):
	selected_index = card_index
	active_unit = game.build_unit(game.board.players[game.board.current_player].hand[card_index])
	valid_tiles = active_unit.get_placeable_tiles()
	move_renderer.draw_black_outlines(valid_tiles)
	state = States.CARD_SELECTED
		
## Called when a tile is clicked
## Behavior depends on the state
func on_selected_tile(pos: Vector2i):
	# Checks that the tile is in bounds. If not, return
	if (pos.x < 0 or pos.y < 0 or pos.x >= game.board.SIZE.x or pos.y >= game.board.SIZE.y):
		return
	# Handles the input
	match state:
		States.DEFAULT:
			var troop = game.board.units[pos.x][pos.y]
			# var building = game.board.buildings[pos.x][pos.y]
			# Checks if selection was successful
			select_unit(troop)
			if active_unit != null:
				state = States.UNIT_SELECTED
		States.CARD_SELECTED:
			if pos not in valid_tiles:
				return
			game.place_from_hand(selected_index, pos.x, pos.y, active_unit)
			valid_tiles = []
			move_renderer.clear()
			active_unit = null
			state = States.DEFAULT
		States.UNIT_SELECTED:
			if active_unit.card_type == Card.CardType.TROOP:
				var troop: Troop = active_unit
				if pos in troop.move_graph:
					troop.move(pos)
				elif pos in troop.attack_list:
					var defender = game.board.units[pos.x][pos.y]
					if defender != null:
						troop.attack_unit(defender)
					else:
						troop.attack_unit(game.board.buildings[pos.x][pos.y])
			deselect_unit()
			state = States.DEFAULT
		States.UNIT_ACTION_INPUT:
			if not pos in valid_tiles:
				return
			game.input_received.emit(pos)
			move_renderer.clear()
			deselect_unit()

## Attempts to select a unit
func select_unit(unit: Unit):
	if unit == null:
		return
	if unit is Troop:
		# If the unit cannot do anything, return
		if not (unit.can_act or unit.can_attack or unit.can_move):
			return
		# Sets active unit
		active_unit = unit
		# Builds the lists of a troop's potential actions
		unit.build_graph()
		unit.build_action_list()
		unit.build_attack_list()
		# Renders the moves it can make
		move_renderer.clear()
		move_renderer.draw_black_outlines(unit.move_graph.keys()) # Draw move outlines
		move_renderer.draw_red_outlines(unit.attack_list.keys())
		# Displays actions it can take
		var action_buttons: Array[Button] = action_bar.display_troop(unit)
		for button in action_buttons:
			button.pressed_with.connect(troop_action)

## Deselects a unit
func deselect_unit():
	if active_unit is Troop:
		active_unit.clear()
	# Clears action bar
	action_bar.display_default()
	# Clears the move outlines
	move_renderer.clear()
	active_unit = null

## Called when a player presses the end_turn button
func on_turn_ended(prev_player: int, current_player: Player):
	action_input_wait = false
	deselect_unit()
	
## Renders a troop card by adding it to the scene tree
func render_troop(troop: Troop, pos: Vector2i):
	var instance = troop_scene.instantiate()
	instance.prepare_for_render(troop, game)
	instance.position = Vector2(pos) * TILE_SIZE
	add_child.call_deferred(instance)

## Renders a newly-placed city
func render_city(city: City):
	add_child.call_deferred(city)

## Runs an action for some troop
func troop_action(index: int):
	if active_unit == null:
		return
	elif state == States.UNIT_ACTION_INPUT:
		return
	# Checks if the action requires user input
	if not active_unit.act(index):
		deselect_unit()
		state = States.DEFAULT
	else:
		state = States.UNIT_ACTION_INPUT

## Called when an action requests user input
func _on_game_input_requested(options:Array[Vector2i]):
	valid_tiles = options
	move_renderer.draw_black_outlines(options)
