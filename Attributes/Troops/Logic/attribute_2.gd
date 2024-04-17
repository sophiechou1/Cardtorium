extends TroopAttribute

# Logic for fortify attribute

var bonus: int

func setup(attribute_id: int, game: Game, troop: Troop):
    super.setup(attribute_id, game, troop)
    bonus = int(troop.base_stats.defense * 0.5)
    parent.defense += bonus


func on_moved(from: Vector2i, to: Vector2i):
    # TODO: Add logic for defendable buildings
    if board.buildings[to.x][to.y] is City:
        if board.buildings[from.x][from.y] is City:
            return
        parent.defense += bonus
    else:
        if board.buildings[from.x][from.y] is City:
            parent.defense -= bonus

    
func reset():
    if board.buildings[parent.pos.x][parent.pos.y] is City:
        parent.defense += bonus