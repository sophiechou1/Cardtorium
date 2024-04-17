extends TileMap

## Render possible moves on the tilemap with outline
func draw_move_outlines(possible_moves: Array):
	clear()
	for move_pos in possible_moves:
		set_cell(0, move_pos, 2, Vector2i(0, 0))

## Highlights units that the troop can attack
func draw_attack_outlines(attackable_squares: Array):
	for tile in attackable_squares:
		set_cell(0, tile, 3, Vector2i(0, 0))