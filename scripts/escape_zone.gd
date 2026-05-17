class_name EscapeZone
extends Area2D

# Survivors actualmente dentro de la zona
var survivors_inside: Array[int] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if body is Player:
		var data: Statics.PlayerData = Game.get_player(body.player_id)
		if data and Statics.is_survivor_role(data.role):
			if body.player_id not in survivors_inside:
				survivors_inside.append(body.player_id)
			_check_win_condition()


func _on_body_exited(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if body is Player:
		survivors_inside.erase(body.player_id)


func _check_win_condition() -> void:
	var game_scene: GameScene = get_parent() as GameScene
	if not game_scene:
		return
	
	var total_survivors: int = 0
	for player_data in Game.players:
		if Statics.is_survivor_role(player_data.role):
			total_survivors += 1
	
	var all_items: bool = game_scene.items_collected >= GameScene.TOTAL_ITEMS
	var all_inside: bool = survivors_inside.size() >= total_survivors
	
	if all_items and all_inside:
		# Usar Lobby igual que en _end_game
		Lobby.go_to_end_screen.rpc("Survivors Win!")
