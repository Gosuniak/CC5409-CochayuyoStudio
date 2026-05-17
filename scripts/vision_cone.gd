class_name VisionCone
extends Node2D

# Ángulo total del cono en grados (90 = 45° a cada lado)
@export var cone_angle: float = 90.0
# Distancia del cono
@export var cone_radius: float = 300.0
# Cuántos rayos para suavizar el cono (más = más suave)
@export var ray_count: int = 30

var cone_color: Color = Color(1, 1, 0, 0.15)  # amarillo semitransparente


func _draw() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	# El vértice del cono es el centro del jugador
	points.append(Vector2.ZERO)
	
	var half_angle: float = cone_angle / 2.0
	
	for i in ray_count + 1:
		var angle_deg: float = -half_angle + (cone_angle * i / ray_count)
		var angle_rad: float = deg_to_rad(angle_deg)
		var point: Vector2 = Vector2(cos(angle_rad), sin(angle_rad)) * cone_radius
		points.append(point)
	
	draw_polygon(points, PackedColorArray([cone_color]))


func _process(_delta: float) -> void:
	queue_redraw()  # Redibujar cada frame
