class_name Player
extends CharacterBody2D

const SPEED: float = 200.0

var player_id: int = -1
var is_local_player: bool = false

@onready var name_label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D


func setup(data: Statics.PlayerData) -> void:
	player_id = data.id
	name_label.text = data.name
	is_local_player = (data.id == multiplayer.get_unique_id())
	camera.enabled = is_local_player

	if data.role == Statics.Role.JOFFREY:
		sprite.modulate = Color.RED
	else:
		sprite.modulate = Color.CYAN


func _physics_process(_delta: float) -> void:
	if not is_local_player:
		return
	
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	velocity = direction.normalized() * SPEED if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	
	# Avisar mi posición a todos los demás
	if direction != Vector2.ZERO:
		_sync_position.rpc(position)


@rpc("any_peer", "unreliable_ordered")
func _sync_position(new_position: Vector2) -> void:
	# Solo actualizar si NO soy el jugador local
	# (el rpc igual se llama localmente, lo ignoramos)
	if not is_local_player:
		position = new_position
