class_name GameScene
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const FOREST_MAP_SCENE: PackedScene = preload("res://scenes/ForestMap.tscn")

const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(768, 512),
	Vector2(848, 512),
	Vector2(688, 512),
	Vector2(768, 592),
]


func _ready() -> void:
	var forest_map: ForestMap = FOREST_MAP_SCENE.instantiate()
	add_child(forest_map)

	# TODOS los clientes crean TODOS los jugadores
	# No necesitamos que solo el servidor lo haga
	for i in Game.players.size():
		var data: Statics.PlayerData = Game.players[i]
		_spawn_player(data, i)


func _spawn_player(data: Statics.PlayerData, index: int) -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(data.id)
	var pos: Vector2 = SPAWN_POSITIONS[index] if index < SPAWN_POSITIONS.size() else Vector2(200, 200)
	player.position = pos
	add_child(player)
	player.setup(data)
