class_name ForestMap
extends Node2D

const TILE_SIZE: int = 16
const MAP_WIDTH: int = 96
const MAP_HEIGHT: int = 64

const GRASS_TEXTURE: Texture2D = preload("res://assets/sprites/tilesets/grass.png")
const DECOR_TEXTURE: Texture2D = preload("res://assets/sprites/tilesets/decor_16x16.png")
const FENCE_TEXTURE: Texture2D = preload("res://assets/sprites/tilesets/fences.png")
const OBJECTS_TEXTURE: Texture2D = preload("res://assets/sprites/objects/objects.png")

const GROUND_SOURCE_ID: int = 0
const DECOR_SOURCE_ID: int = 1
const FENCE_SOURCE_ID: int = 2
const OBJECT_SOURCE_ID: int = 3

const PATH_TILE: Vector2i = Vector2i(3, 1)
## Árboles y matorrales en `objects.png` (celdas del atlas 16×16).
const OBJECT_TREE_ATLASES: Array[Vector2i] = [
	Vector2i(0, 5),
	Vector2i(8, 6),
	Vector2i(6, 7),
]
const OBJECT_TREE_SIZES: Array[Vector2i] = [
	Vector2i(3, 3),
	Vector2i(2, 3),
	Vector2i(2, 2),
]
const FENCE_TILES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]

var _ground_layer: TileMapLayer
var _details_layer: TileMapLayer


func _ready() -> void:
	_ground_layer = TileMapLayer.new()
	_ground_layer.name = "Ground"
	_ground_layer.z_index = -2
	_ground_layer.tile_set = _build_tileset()
	add_child(_ground_layer)

	_details_layer = TileMapLayer.new()
	_details_layer.name = "Details"
	_details_layer.z_index = -1
	_details_layer.collision_enabled = false
	_details_layer.tile_set = _ground_layer.tile_set
	add_child(_details_layer)

	_paint_ground()
	_paint_path()
	_paint_forest()
	_paint_fence_border()


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var grass_source := TileSetAtlasSource.new()
	grass_source.texture = GRASS_TEXTURE
	grass_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	grass_source.create_tile(Vector2i.ZERO)
	tileset.add_source(grass_source, GROUND_SOURCE_ID)

	var decor_source := TileSetAtlasSource.new()
	decor_source.texture = DECOR_TEXTURE
	decor_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in 5:
		for x in 4:
			decor_source.create_tile(Vector2i(x, y))
	tileset.add_source(decor_source, DECOR_SOURCE_ID)

	var fence_source := TileSetAtlasSource.new()
	fence_source.texture = FENCE_TEXTURE
	fence_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in 2:
		for x in 4:
			fence_source.create_tile(Vector2i(x, y))
	tileset.add_source(fence_source, FENCE_SOURCE_ID)

	var object_source := TileSetAtlasSource.new()
	object_source.texture = OBJECTS_TEXTURE
	object_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in OBJECT_TREE_ATLASES.size():
		object_source.create_tile(OBJECT_TREE_ATLASES[i], OBJECT_TREE_SIZES[i])
	tileset.add_source(object_source, OBJECT_SOURCE_ID)

	return tileset


func _paint_ground() -> void:
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			_ground_layer.set_cell(Vector2i(x, y), GROUND_SOURCE_ID, Vector2i.ZERO)


func _paint_path() -> void:
	var center_y := MAP_HEIGHT / 2
	for x in MAP_WIDTH:
		if x % 2 == 0 or x % 5 == 0:
			_ground_layer.set_cell(Vector2i(x, center_y), DECOR_SOURCE_ID, PATH_TILE)
			if center_y + 1 < MAP_HEIGHT:
				_ground_layer.set_cell(Vector2i(x, center_y + 1), DECOR_SOURCE_ID, PATH_TILE)


func _paint_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5409
	var occupied: Dictionary = {}

	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var cell: Vector2i = Vector2i(x, y)
			if occupied.has(cell):
				continue
			if _is_forest_reserved(cell):
				continue
			# Cada intento puede colocar un sprite de varias celdas; ~6 % de celdas intentan (mitad de antes).
			if rng.randi_range(0, 99) >= 6:
				continue

			var order: Array[int] = _shuffled_variant_order(rng)
			for vi in order:
				if not _can_place_object_tree(cell, OBJECT_TREE_SIZES[vi], occupied):
					continue
				_place_object_tree(cell, vi, occupied)
				break


func _is_forest_reserved(cell: Vector2i) -> bool:
	var near_center_path: bool = absi(cell.y - MAP_HEIGHT / 2) <= 2
	var near_spawn_area: bool = (
		cell.x > MAP_WIDTH / 2 - 8
		and cell.x < MAP_WIDTH / 2 + 8
		and cell.y > MAP_HEIGHT / 2 - 6
		and cell.y < MAP_HEIGHT / 2 + 6
	)
	return near_center_path or near_spawn_area


func _can_place_object_tree(origin: Vector2i, size: Vector2i, occupied: Dictionary) -> bool:
	for dy in size.y:
		for dx in size.x:
			var c: Vector2i = origin + Vector2i(dx, dy)
			if c.x < 1 or c.y < 1:
				return false
			if c.x >= MAP_WIDTH - 1 or c.y >= MAP_HEIGHT - 1:
				return false
			if occupied.has(c):
				return false
			if _is_forest_reserved(c):
				return false
	return true


func _place_object_tree(origin: Vector2i, variant_index: int, occupied: Dictionary) -> void:
	var size: Vector2i = OBJECT_TREE_SIZES[variant_index]
	var atlas: Vector2i = OBJECT_TREE_ATLASES[variant_index]
	_details_layer.set_cell(origin, OBJECT_SOURCE_ID, atlas)
	for dy in size.y:
		for dx in size.x:
			occupied[origin + Vector2i(dx, dy)] = true


func _shuffled_variant_order(rng: RandomNumberGenerator) -> Array[int]:
	var order: Array[int] = [0, 1, 2]
	for i in order.size():
		var j: int = rng.randi_range(i, order.size() - 1)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	return order


func _paint_fence_border() -> void:
	for x in MAP_WIDTH:
		var top_tile := FENCE_TILES[x % FENCE_TILES.size()]
		var bottom_tile := FENCE_TILES[(x + 1) % FENCE_TILES.size()]
		_details_layer.set_cell(Vector2i(x, 0), FENCE_SOURCE_ID, top_tile)
		_details_layer.set_cell(Vector2i(x, MAP_HEIGHT - 1), FENCE_SOURCE_ID, bottom_tile)

	for y in MAP_HEIGHT:
		var left_tile := FENCE_TILES[y % FENCE_TILES.size()]
		var right_tile := FENCE_TILES[(y + 2) % FENCE_TILES.size()]
		_details_layer.set_cell(Vector2i(0, y), FENCE_SOURCE_ID, left_tile)
		_details_layer.set_cell(Vector2i(MAP_WIDTH - 1, y), FENCE_SOURCE_ID, right_tile)
