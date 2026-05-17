class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
var player_id: int = -1
var is_local_player: bool = false
var last_direction: Vector2 = Vector2.RIGHT

@onready var name_label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var capture_area: Area2D = $CaptureArea
@onready var vision_cone: VisionCone = $VisionCone

func setup(data: Statics.PlayerData) -> void:
	print("setup() - data.id:", data.id, " mi id:", multiplayer.get_unique_id())
	player_id = data.id
	name_label.text = Statics.get_role_name(data.role)
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
		if victim_data and Statics.is_survivor_role(victim_data.role):
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
		# Ocultar el cono en jugadores que no son locales
		# (cada quien ve solo su propio cono)
		vision_cone.visible = false
		return
	
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
		velocity = direction.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
	
	# Rotar el cono hacia la dirección de movimiento
	vision_cone.rotation = last_direction.angle()
	
	move_and_slide()
	
	if direction != Vector2.ZERO:
		_sync_position.rpc(position)
		
	if is_local_player:
		_update_visibility_of_others()
		
func _update_visibility_of_others() -> void:
	var all_players: Array = get_parent().get_children()
	for node in all_players:
		if node is Player and node.player_id != player_id:
			node.visible = _is_in_cone(node.global_position)


func _is_in_cone(target_pos: Vector2) -> bool:
	var to_target: Vector2 = target_pos - global_position
	var distance: float = to_target.length()
	
	# Verificar distancia
	if distance > vision_cone.cone_radius:
		return false
	
	# Verificar ángulo
	var angle_to_target: float = rad_to_deg(to_target.angle())
	var cone_direction: float = rad_to_deg(last_direction.angle())
	var angle_diff: float = abs(angle_to_target - cone_direction)
	
	# Normalizar la diferencia entre 0 y 180
	if angle_diff > 180:
		angle_diff = 360 - angle_diff
	
	return angle_diff <= vision_cone.cone_angle / 2.0


@rpc("any_peer", "unreliable_ordered")
func _sync_position(new_position: Vector2) -> void:
	if not is_local_player:
		position = new_position
