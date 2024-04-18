extends Resource

class_name Action

## The name of the action
var name: String
## The description of the action
var description: String
## The function associated to the action.
## This function should either take no arguments, or take a single 
## Vector2i as an argument.
var action: Callable
## A list of tiles which the user can choose from. If this array is nonempty,
## the player will be required to click on a tile before the action is executed.
## The tile coordinates they select will be passed as an argument to the action
## funcion.
var selectable_tiles: Array[Vector2i]
## Whether or not the action should ask the player to select a tile.
var require_input: bool = false
## The game object
var game: Game

## Adds logic to the action, and connects itself to its own signal.
func setup(_game: Game, _action: Callable, tiles = null):
    self.game = _game
    if tiles != null:
        selectable_tiles = tiles
        require_input = true
        game.input_received.connect(on_input_received)
    self.action = _action

## Runs the action. If [member Action.selectable_tiles] is set,
## this will prompt the player to click on one of the tiles in the
## array [member Action.selectable_tiles], and the tile coords they select
## will be sent as a parameter to [member Action.action].
## Returns whether or not it needs to wait on input.
func execute():
    if not require_input:
        action.call()
        return false
    else:
        game.input_requested.emit(selectable_tiles)
        return true


## Called after the player selects a tile.
func on_input_received(tile: Vector2i):
    action.call(tile)