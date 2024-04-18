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

func on_card_selected(card_index: int):
	selected_index = card_index
		
## Called when a tile is clicked
func on_selected_tile(pos: Vector2i):
	# Checks that the tile is in bounds
	if (pos.x < 0 or pos.y < 0 or pos.x >= game.board.SIZE.x or pos.y >= game.board.SIZE.y):
		return
	selected_tile = pos
	# Checks for action input
	if action_input_wait:
		if selected_tile in action_input_options:
			action_input_wait = false
			game.input_received.emit(selected_tile)
		else:
			return
	# Checks if the tile selection was for the purpose of placing a card
	check_and_place_card()

	# Checks if the clicked tile contains any units
	var tile_content = game.board.units[selected_tile.x][selected_tile.y]
	# Sets a new active unit
	if tile_content != null and tile_content is Troop and active_unit == null:
		if tile_content.owned_by != game.board.current_player:
			return
		var troop = tile_content as Troop
		print_rich("[b]Name[/b]    : %s" % [troop.base_stats.name])
		print_rich("[b]Health[/b]  : %d / %d" % [troop.health, troop.base_stats.health])
		print_rich("[b]Attack[/b]  : %d" % [troop.attack])
		print_rich("[b]Defense[/b] : %d\n" % [troop.defense])
		select_unit(troop)
		return
	# Don't need to do anything if no unit selected
	elif active_unit == null:
		return
	
	# Checks for attacking
	if active_unit is Troop and selected_tile in active_unit.attack_list:
		# Checks for attacking a troop
		if tile_content != null:
			active_unit.attack_unit(tile_content)
			deselect_unit()
	# Checks for moving
	elif active_unit is Troop and selected_tile in active_unit.move_graph:
		active_unit.move(selected_tile)
		deselect_unit()
	# Deselect unit
	else:
		deselect_unit()

## Selects a unit
func select_unit(unit: Unit):
	if unit is Troop:
		# Sets active unit
		active_unit = unit
		# Builds the lists of a troop's potential actions
		unit.build_graph()
		unit.build_action_list()
		unit.build_attack_list()
		# Renders the moves it can make
		move_renderer.clear()
		move_renderer.draw_move_outlines(unit.move_graph.keys()) # Draw move outlines
		move_renderer.draw_attack_outlines(unit.attack_list.keys())
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

## Must first select card to place on a tile
func check_and_place_card():
	if selected_index != - 1:
		if selected_tile != null:
			var tile_content = game.board.units[selected_tile.x][selected_tile.y]
			if tile_content != null and tile_content is Troop:
				# Troop already exists on the selected tile, don't allow card placement
				return
			if not game.board.buildings[selected_tile.x][selected_tile.y] is City:
				return
			var current_player = game.board.current_player
			if not game.board.territory[selected_tile.x][selected_tile.y] == current_player:
				return
			game.place_from_hand(selected_index, selected_tile.x, selected_tile.y)
			selected_index = -1
			selected_tile = Vector2i()
		else:
			# Deselect any selected tile
			selected_tile = Vector2i()

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
	elif action_input_wait:
		return
	if active_unit.owned_by == game.board.territory[active_unit.pos.x][active_unit.pos.y]:
		# Deselects unit if input is not necessary
		# Otherwise waits for the player to click something
		if not active_unit.act(index):
			deselect_unit()
		else:
			action_input_wait = true

## Called when an action requests user input
func _on_game_input_requested(options:Array[Vector2i]):
	action_input_options = options
	move_renderer.draw_action_options(options)
