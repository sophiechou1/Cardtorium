extends TroopAttribute


var bonus = 1.5

# Logic for fortify attribute
func setup(attribute_id: int, game: Game, troop: Troop):
    super.setup(attribute_id, game, troop)
    parent.defense = int(parent.base_stats.defense * bonus)


func on_moved(from: Vector2i, to: Vector2i):
    # TODO: Add logic for defendable buildings
    if board.buildings[to.x][to.y] is City:
        parent.defense = int(parent.base_stats.defense * bonus)
    else:
        parent.defense = parent.base_stats.defense