class_name GameScene
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const RESPAWN_POSITION: Vector2 = Vector2(600, 400)  # Ajusta al centro de tu mapa
const RESPAWN_DELAY: float = 2.0

const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(100, 100),
	Vector2(300, 100),
	Vector2(500, 100),
	Vector2(300, 300),
]


func _ready() -> void:
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
