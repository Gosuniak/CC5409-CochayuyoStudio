class_name GameScene
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const RESPAWN_POSITION: Vector2 = Vector2(600, 400)  # Ajusta al centro de tu mapa
const RESPAWN_DELAY: float = 2.0
const MAX_LIVES: int = 3
var survivor_lives: int = MAX_LIVES

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
	
# Llamado por el servidor cuando un survivor es capturado
@rpc("authority", "call_local", "reliable")
func remove_survivor_life() -> void:
	survivor_lives -= 1
	print("Vidas restantes: ", survivor_lives)
	if survivor_lives < 0:
		_end_game.rpc("Joffrey Wins!")
	# Aquí luego actualizaremos el HUD
	
@rpc("authority", "call_local", "reliable")
func _end_game(message: String) -> void:
	Lobby.go_to_end_screen.rpc(message)
