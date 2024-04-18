extends TroopAttribute

# Logic for the rally attribute

var mult: float = 0.5

func build_action() -> Action:
    var action: Action = Action.new()
    action.name = attribute.name
    action.description = attribute.description
    action.setup(parent.game, buff_nearby)
    return action

func buff_nearby():
    for x in range(parent.pos.x - 1, parent.pos.x + 2):
        if x < 0:
            continue
        elif x >= board.SIZE.x:
            break
        for y in range(parent.pos.y - 1, parent.pos.y + 2):
            if y < 0:
                continue
            elif y >= board.SIZE.y:
                break
            if board.units[x][y] == null:
                continue
            var troop: Troop = board.units[x][y]
            if troop.owned_by == parent.owned_by:
                troop.defense += int(troop.base_stats.defense * mult)
                troop.attack += int(troop.base_stats.attack * mult)