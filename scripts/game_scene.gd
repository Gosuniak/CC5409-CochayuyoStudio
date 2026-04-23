class_name GameScene
extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const RESPAWN_POSITION: Vector2 = Vector2(600, 400)  # Ajusta al centro de tu mapa
const RESPAWN_DELAY: float = 2.0
const MAX_LIVES: int = 3
const TOTAL_ITEMS: int = 3
var survivor_lives: int = MAX_LIVES
var items_collected: int = 0
@onready var hud: HUD = $HUD  # agregar HUD como hijo de GameScene

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
		
	# Mostrar HUD solo a survivors
	var current: Statics.PlayerData = Game.get_current_player()
	hud.visible = true
	hud.update_lives(survivor_lives)
	hud.update_items(items_collected, TOTAL_ITEMS)


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
	hud.update_lives(survivor_lives)
	print("Vidas restantes: ", survivor_lives)
	if survivor_lives < 0:
		_end_game.rpc("Joffrey Wins!")
	# Aquí luego actualizaremos el HUD
	
@rpc("authority", "call_local", "reliable")
func _end_game(message: String) -> void:
	Lobby.go_to_end_screen.rpc(message)
	
# El servidor actualiza el contador y avisa a todos
@rpc("authority", "call_local", "reliable")
func on_item_collected() -> void:
	if not multiplayer.is_server():
		return  # Solo el servidor incrementa
	items_collected += 1
	hud.update_items(items_collected, TOTAL_ITEMS)
	# Avisar a todos los clientes el valor real
	_sync_items.rpc(items_collected)
	
@rpc("authority", "call_local", "reliable")  
func _sync_items(count: int) -> void:
	items_collected = count
	print("Items recogidos: %d/%d" % [items_collected, TOTAL_ITEMS])
	hud.update_items(items_collected, TOTAL_ITEMS)
