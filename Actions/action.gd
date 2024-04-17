extends Resource

class_name Action

## The name of the action
var name: String
## The description of the action
var description: String
## The function associated to the action
var action: Callable

## Sets up the action by associating a callable to it
func setup(_action: Callable):
    self.action = _action

## Runs the action
func execute():
    action.call()