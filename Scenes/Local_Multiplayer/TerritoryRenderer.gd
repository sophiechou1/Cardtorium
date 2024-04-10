extends TileMap




func _on_game_territory_claimed(claimed:Array[Vector2i], player_index:int):
	for tile in claimed:
		set_cell(0, tile, player_index, Vector2i.ZERO)
