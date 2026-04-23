class_name EndScreen
extends CanvasLayer  # ← extiende CanvasLayer, no Control

@onready var result_label: Label = %ResultLabel

func _ready() -> void:
	result_label.text = Game.end_message
