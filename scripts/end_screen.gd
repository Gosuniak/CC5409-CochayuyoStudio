class_name EndScreen
extends CanvasLayer  # ← extiende CanvasLayer, no Control

@onready var result_label: Label = %ResultLabel

func _ready() -> void:
	# 1. Mostramos el mensaje de victoria/derrota
	result_label.text = Game.end_message
	
	# 2. Iniciamos un temporizador de 5 segundos
	await get_tree().create_timer(3.0).timeout
	
	# 3. Solo el servidor ejecuta la orden para que todos cambien de escena a la vez
	if multiplayer.is_server():
		Lobby.go_to_lobby.rpc()
