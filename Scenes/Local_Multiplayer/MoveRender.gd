extends TileMap

## Highlights units that the troop can attack
func draw_red_outlines(tiles: Array):
	for tile in tiles:
		set_cell(0, tile, 3, Vector2i(0, 0))

## Highlights squares which an action allows to be selected.
func draw_black_outlines(tiles:Array):
	for tile in tiles:
		set_cell(0, tile, 2, Vector2i(0, 0))
