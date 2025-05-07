extends Node2D

@export var hills_per_chunk = 2
@export var points_per_hill = 10 # More points = smoother hills
@export var hill_height_range = 200
@export var hill_width_multiplier = 2.0
@export var oil_trail_length = 30 # Number of darkened segments after oil spill triggers
@export var chance_for_oil_spill = 100 # 1 out of x for oil to spawn
@export var oil_friction = 0.05
@onready var motorcycle: RigidBody2D = $"../Motorcycle"

var depth_offset = 500 # To fill in gap below hills
var oil_trail_remaining = 0
var screensize
var terrain = []
var grass_texture = preload("res://game/game_envs/2d_motorcycle_env/Images/Terrain/Grass.png")
var dirt_texture = preload("res://game/game_envs/2d_motorcycle_env/Images/Terrain/DirtBG.png")

var terrain_y_offset = 400
var leftmost_x = 0
var rightmost_x = 0

func _ready() -> void:
	randomize()
	screensize = get_viewport().get_visible_rect().size
	terrain.clear()

	var start_y = motorcycle.position.y + terrain_y_offset
	var start_point = Vector2(0, start_y)
	terrain.append(start_point)

	leftmost_x = start_point.x
	rightmost_x = start_point.x

	add_hills(start_point.x, 1) # Forward
	add_hills(start_point.x, -1) # Backward

func _process(delta: float) -> void:
	if rightmost_x < motorcycle.position.x + screensize.x:
		add_hills(rightmost_x, 1)

	if leftmost_x > motorcycle.position.x - screensize.x:
		add_hills(leftmost_x, -1)

func add_hills(start_x: float, direction: int) -> void:
	var hill_width = (screensize.x / hills_per_chunk) * hill_width_multiplier
	var hill_slices = int(hill_width / points_per_hill)

	var start_index = terrain.size() - 1 if direction == 1 else 0
	var start_point = terrain[start_index]
	var poly = PackedVector2Array()

	if direction == -1:
		# If going left, reverse the points to build correctly
		poly.append(Vector2(start_point.x, screensize.y + depth_offset))

	for i in range(hills_per_chunk):
		var height = hill_height_range / 2 + randi() % hill_height_range
		start_point.y -= height

		for j in range(hill_slices):
			var hill_point = Vector2()
			hill_point.x = start_point.x + direction * (j * points_per_hill + hill_width * i)
			hill_point.y = start_point.y + height * cos(2 * PI / hill_slices * j)

			if direction == 1:
				terrain.append(hill_point)
			else:
				terrain.insert(0, hill_point)

			poly.append(hill_point)

		start_point.y += height

	# Close the polygon to the bottom of the screen
	if direction == 1:
		poly.append(Vector2(terrain[-1].x, screensize.y + depth_offset))
		poly.append(Vector2(terrain[terrain.size() - hill_slices * hills_per_chunk - 1].x, screensize.y + depth_offset))
	else:
		poly.append(Vector2(terrain[0].x, screensize.y + depth_offset))
		poly.append(Vector2(terrain[hill_slices * hills_per_chunk].x, screensize.y + depth_offset))

	# Add collision polygon
	var shape = CollisionPolygon2D.new()
	shape.polygon = poly
	%StaticBody2D.add_child(shape)

	# Dirt polygon
	var dirt_poly = Polygon2D.new()
	dirt_poly.polygon = poly
	dirt_poly.texture = dirt_texture
	dirt_poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(dirt_poly)

	# Grass Sprites along the hilltop
	var segment_length = grass_texture.get_width() * 0.8 # Slight overlap for cleaner look

	var grass_points = []
	for point in poly:
		if point.y < screensize.y:
			grass_points.append(point)

	for i in range(grass_points.size() - 1):
		var point_a = grass_points[i]
		var point_b = grass_points[i + 1]
		var segment_vector = point_b - point_a
		var segment_distance = segment_vector.length()

		if segment_distance == 0:
			continue # Skip degenerate segments

		var direction_vector = segment_vector.normalized()
		var angle = direction_vector.angle()

		var current_pos = point_a
		var distance_covered = 0.0

		while distance_covered < segment_distance:
			var grass_sprite = Sprite2D.new()
			grass_sprite.texture = grass_texture
			grass_sprite.centered = true
			grass_sprite.position = current_pos
			grass_sprite.rotation = angle
			add_child(grass_sprite)

			grass_sprite.flip_h = bool(randi() % 2)

			# Trigger a new spill randomly
			if oil_trail_remaining == 0 and randi() % chance_for_oil_spill == 0:
				oil_trail_remaining = oil_trail_length

			if oil_trail_remaining > 0:
				grass_sprite.modulate = Color(0.4, 0.4, 0.4)
				oil_trail_remaining -= 1

				# Create slippery StaticBody2D
				var oil_body = StaticBody2D.new()
				var oil_shape = CollisionShape2D.new()
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(segment_length, 10)
				oil_shape.shape = rect_shape
				oil_shape.position = grass_sprite.position
				oil_shape.rotation = angle

				# Add low-friction physics material
				var material = PhysicsMaterial.new()
				material.friction = oil_friction
				oil_body.physics_material_override = material

				oil_body.add_child(oil_shape)
				add_child(oil_body)


			current_pos += direction_vector * segment_length
			distance_covered += segment_length

	# Update boundaries
	if direction == 1:
		rightmost_x = terrain[-1].x
	else:
		leftmost_x = terrain[0].x
