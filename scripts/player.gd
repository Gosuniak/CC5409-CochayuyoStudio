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
	player_id = data.id
	name_label.text = data.name
	is_local_player = (data.id == multiplayer.get_unique_id())
	camera.enabled = is_local_player
	
	if data.role == Statics.Role.JOFFREY:
		sprite.modulate = Color.RED
		if multiplayer.is_server():
			capture_area.body_entered.connect(_on_body_entered)
	else:
		sprite.modulate = Color.CYAN
		capture_area.monitoring = false  # ← survivors no capturan a nadie


func _on_body_entered(body: Node) -> void:
	if body is Player and body.player_id != player_id:
		var victim_data: Statics.PlayerData = Game.get_player(body.player_id)
		if victim_data and victim_data.role == Statics.Role.SURVIVOR:
			_capture_survivor.rpc(body.player_id)


@rpc("authority", "call_local", "reliable")
func _capture_survivor(survivor_id: int) -> void:
	var survivor: Player = get_parent().get_node_or_null(str(survivor_id))
	if survivor:
		survivor.hide()


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
