class_name Item
extends Area2D

# Emitido cuando un survivor recoge el item
signal item_collected

var is_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if is_collected:
		return
	if body is Player:
		var data: Statics.PlayerData = Game.get_player(body.player_id)
		if data and data.role == Statics.Role.SURVIVOR:
			is_collected = true  # ← marcar ANTES de llamar el rpc
			_collect.rpc()


@rpc("authority", "call_local", "reliable")
func _collect() -> void:
	is_collected = true
	hide()
	# Avisar a la escena principal que se recogió un item
	var game_scene: GameScene = get_parent() as GameScene
	if game_scene:
		game_scene.on_item_collected.rpc()
