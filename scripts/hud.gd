class_name HUD
extends CanvasLayer

@onready var lives_label: Label = %LivesLabel
@onready var items_label: Label = %ItemsLabel


func update_lives(lives: int) -> void:
	lives_label.text = "Vidas: %d" % lives


func update_items(collected: int, total: int) -> void:
	items_label.text = "Items: %d/%d" % [collected, total]
