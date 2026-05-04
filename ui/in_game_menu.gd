extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	# El menú empieza oculto
	hide()
	# Conectamos las señales de los botones
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" por defecto es la tecla Escape en Godot
	if event.is_action_pressed("ui_cancel"):
		# Alternamos la visibilidad del menú
		visible = not visible
		
		# Si tu juego captura el mouse (ej. FPS), aquí deberías liberarlo o capturarlo
		if visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			# Cambia esto a MOUSE_MODE_CAPTURED si es un juego en primera/tercera persona
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func _on_resume_pressed() -> void:
	hide()
	# Aquí también deberías volver a capturar el mouse si aplica

func _on_quit_pressed() -> void:
	# 1. Le avisamos al Lobby que la desconexión es intencional para saltarnos el mensaje de error
	Lobby._skip_server_disconnect_action = true
	
	# 2. Usamos la función del profe que ya cierra la conexión, limpia los arreglos y cambia la escena
	Lobby.go_to_menu()
