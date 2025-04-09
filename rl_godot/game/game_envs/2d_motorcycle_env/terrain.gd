extends Node2D

@export var num_hills = 2
@export var slice = 10
@export var hill_range = 200
@export var hill_width_multiplier = 2.0
@export var depth_offset = 500
@onready var motorcycle: RigidBody2D = $"../Motorcycle"

var screensize
var terrain = Array()
var texture = preload("res://game/game_envs/2d_motorcycle_env/Images/Terrain/Grass.png")

func _ready() -> void:
	randomize()
	screensize = get_viewport().get_visible_rect().size
	terrain = Array()
	var start_y = screensize.y * 3/4 + (-hill_range + randi() % hill_range * 2)
	terrain.append(Vector2(0, start_y))
	add_hills()
	
func _process(delta: float) -> void:
	if terrain[-1].x < motorcycle.position.x + screensize.x:
		add_hills()

func add_hills() -> void:
	var hill_width = (screensize.x / num_hills) * hill_width_multiplier # Wider hills
	var hill_slices = int(hill_width / slice)
	var start = terrain[-1]
	var poly = PackedVector2Array()

	for i in range(num_hills):
		var height = hill_range / 2 + randi() % hill_range # Taller hills
		start.y -= height
		
		for j in range(hill_slices):
			var hill_point = Vector2()
			hill_point.x = start.x + j * slice + hill_width * i
			hill_point.y = start.y + height * cos(2 * PI / hill_slices * j)
			terrain.append(hill_point)
			poly.append(hill_point)
			
		start.y += height

	# Close the polygon (important: extend lower to hide empty space)
	poly.append(Vector2(terrain[-1].x, screensize.y + depth_offset))
	poly.append(Vector2(terrain[poly.size() - hill_slices - 1].x, screensize.y + depth_offset))

	# Add collision
	var shape = CollisionPolygon2D.new()
	shape.polygon = poly
	%StaticBody2D.add_child(shape)

	# Add visual polygon
	var ground = Polygon2D.new()
	ground.polygon = poly
	ground.texture = texture
	add_child(ground)
