class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
var player_id: int = -1
var is_local_player: bool = false

@onready var name_label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var capture_area: Area2D = $CaptureArea

func setup(data: Statics.PlayerData) -> void:
	print("setup() - data.id:", data.id, " mi id:", multiplayer.get_unique_id())
	player_id = data.id
	name_label.text = data.name
	is_local_player = (data.id == multiplayer.get_unique_id())

	print("is_local_player:", is_local_player)
	camera.enabled = is_local_player

	if data.role == Statics.Role.JOFFREY:
		sprite.modulate = Color.RED
		if multiplayer.is_server():
			capture_area.body_entered.connect(_on_body_entered)
	else:
		sprite.modulate = Color.CYAN
		capture_area.monitoring = false  # ← survivors no capturan a nadie


var _capturing: bool = false

func _on_body_entered(body: Node) -> void:
	if _capturing:
		return
	if body is Player and body.player_id != player_id:
		var victim_data: Statics.PlayerData = Game.get_player(body.player_id)
		if victim_data and victim_data.role == Statics.Role.SURVIVOR:
			_capturing = true
			_capture_survivor.rpc(body.player_id)
			await Game.get_tree().create_timer(0.5).timeout
			if not is_inside_tree():
				return
			_capturing = false


@rpc("authority", "call_local", "reliable")
func _capture_survivor(survivor_id: int) -> void:
	# remove_survivor_life ya tiene call_local, no hace falta separar por is_server
	var game_scene: GameScene = get_parent() as GameScene
	if multiplayer.is_server():
		game_scene.remove_survivor_life.rpc()
	
	var survivor: Player = get_parent().get_node_or_null(str(survivor_id))
	if survivor:
		survivor._do_respawn()
		
# Llamar esto en el nodo del survivor capturado
func _do_respawn() -> void:
	hide()
	# Usar el árbol de Game en vez del nodo, ya que Game siempre existe
	await Game.get_tree().create_timer(GameScene.RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	position = GameScene.RESPAWN_POSITION
	show()


func _physics_process(_delta: float) -> void:
	if not is_local_player:
		return
	
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	velocity = direction.normalized() * SPEED if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	
	if direction != Vector2.ZERO:
		_sync_position.rpc(position)


@rpc("any_peer", "unreliable_ordered")
func _sync_position(new_position: Vector2) -> void:
	if not is_local_player:
		position = new_position
