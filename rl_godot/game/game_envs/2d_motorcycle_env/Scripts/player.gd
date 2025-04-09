extends RigidBody2D

var wheels = []
var raycasts = []
var speed = 600000
var max_speed = 50
var body_torque_impulse_force = 0.4
var distance_to_goal = 1000
var truncate_counter = 0
var truncate_limit = 3

@onready var head: RigidBody2D = $Head
@onready var upper_body: RigidBody2D = $UpperBody
@onready var agent: Agent = $Agent

var initial_state = {} 
var distance_traveled = 0
var previous_position_x = 0.0
var truncated = false
var hit_head = false
var goal_reached = false
var is_finished = false

func _ready() -> void:
	raycasts = get_tree().get_nodes_in_group("raycast")
	wheels = get_tree().get_nodes_in_group("wheel")
	previous_position_x = global_position.x
	initial_state = {
		"distance_traveled": 0,
		"position": position,
		"rotation": rotation,
		"linear_velocity": Vector2.ZERO,
		"angular_velocity": 0.0,
		"truncated": false,
		"hit_head": false,
		"is_finished": false,
		"goal_reached": false
	}
	
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	
func _physics_process(delta: float) -> void:
	handle_movement(delta)
	get_raycast_info()
	
func get_raycast_info():
	var raycast_info = []
	
	for raycast in raycasts:
		if raycast is RayCast2D and raycast.is_colliding():
			var collider = raycast.get_collider()
			var col_point = raycast.get_collision_point()
			var local_col_point = to_local(col_point)
			
			var dist_to_collider = round(local_col_point.x)
			raycast_info.append(dist_to_collider)
		else:
			raycast_info.append(10000)
	return raycast_info


func reset():
	# Restore main body state
	position = initial_state["position"]
	rotation = initial_state["rotation"]
	linear_velocity = initial_state["linear_velocity"]
	angular_velocity = initial_state["angular_velocity"]
	
	# Reset flags
	hit_head = initial_state["hit_head"]
	distance_traveled = initial_state["distance_traveled"]
	goal_reached = initial_state["goal_reached"]
	is_finished = initial_state["is_finished"]
	truncated = initial_state["truncated"]
	
	# Reset wheels
	reset_wheels()
	
	# Reset child rigid bodies (head and upper body)
	reset_child_bodies()
	
	# Reset previous position tracker
	previous_position_x = global_position.x

func reset_wheels():
	for wheel in wheels:
		wheel.angular_velocity = 0
		wheel.linear_velocity = Vector2.ZERO
		wheel.rotation = 0

func reset_child_bodies():
	head.angular_velocity = 0
	head.linear_velocity = Vector2.ZERO
	head.rotation = 0
	
	upper_body.angular_velocity = 0
	upper_body.linear_velocity = Vector2.ZERO
	upper_body.rotation = 0

func is_truncated():
	truncated = true
	hit_head = false
	is_finished = true
	goal_reached = false
	print("truncated")
	reset()
	agent.set_is_done(true)

func player_hit_head():
	hit_head = true
	is_finished = true
	goal_reached = false
	truncated = false
	reset()
	print("head")	
	agent.set_is_done(true)
	
func goal_is_reached():
	print("goal")
	is_finished = true
	goal_reached = true
	hit_head = false
	truncated = false
	agent.set_is_done(true)
	
	reset()
	
func handle_movement(delta):
	if Input.is_action_pressed("ui_up"):
		for wheel in wheels:
			if wheel.angular_velocity < max_speed:
				wheel.apply_torque_impulse(speed * delta)
	
	if Input.is_action_pressed("ui_left"):
		head.apply_torque_impulse(-speed * body_torque_impulse_force * delta)
		upper_body.apply_torque_impulse(-speed * body_torque_impulse_force * delta)
		
	if Input.is_action_pressed("ui_right"):
		head.apply_torque_impulse(body_torque_impulse_force * speed * delta)
		upper_body.apply_torque_impulse(body_torque_impulse_force * speed * delta)
	
	if Input.is_action_pressed("ui_down"):
		for wheel in wheels:
			if wheel.angular_velocity > -max_speed:
				wheel.apply_torque_impulse(-speed * delta)
	
	# Update distance traveled (right increases, left decreases)
	var current_position_x = global_position.x
	var delta_position_x = current_position_x - previous_position_x
	
	var old_distance_traveled = distance_traveled 
	
	distance_traveled += round(delta_position_x / 10)
	
	if old_distance_traveled == distance_traveled:
		truncate_counter += 0.01
	else:
		truncate_counter = 0


	if truncate_counter >= truncate_limit:
		is_truncated()
		pass
	
	if distance_traveled > distance_to_goal:
		goal_is_reached()
	
	previous_position_x = current_position_x


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		player_hit_head()
