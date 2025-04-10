extends RigidBody2D

var wheels = []
var raycasts = []
var speed = 600000
var max_speed = 50
var body_torque_impulse_force = 0.4
@export var distance_to_goal = 300
var truncate_counter = 0
var truncate_limit = 3

@onready var head: RigidBody2D = $Head
@onready var upper_body: RigidBody2D = $UpperBody
@onready var agent: Motorcycle_agent = $Agent

var initial_state = {} 
var distance_traveled = 0
var distance_check = 0
var previous_position_x = 0.0
var goal_reached = false
var is_done = false

var backward_distance_limit = -200

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
		"is_done": false,
		"goal_reached": false
	}
	
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	
func _physics_process(delta: float) -> void:
	handle_movement(delta)
	
	if global_position.y > 1000:
		is_truncated() 
	
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
	distance_traveled = initial_state["distance_traveled"]
	
	# Reset flags
	goal_reached = initial_state["goal_reached"]
	is_done = initial_state["is_done"]
	
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
	distance_check = 0
	is_done = true
	goal_reached = false
	agent.set_is_done(true)

func player_hit_head():
	distance_check = 0
	is_done = true
	goal_reached = false
	agent.set_is_done(true)
	
func goal_is_reached():
	distance_check = 0
	is_done = true
	goal_reached = true
	agent.set_is_done(true)
	
func handle_movement(delta):
	#print("AGENT VALUES LIVE:", agent.forward, agent.backward, agent.lean_right, agent.lean_left)	
	if Input.is_action_pressed("ui_up") or agent.forward:
		for wheel in wheels:
			if wheel.angular_velocity < max_speed:
				wheel.apply_torque_impulse(speed * delta)
	
	if Input.is_action_pressed("ui_left") or agent.lean_left:
		head.apply_torque_impulse(-speed * body_torque_impulse_force * delta)
		upper_body.apply_torque_impulse(-speed * body_torque_impulse_force * delta)
		
	if Input.is_action_pressed("ui_right") or agent.lean_right:
		head.apply_torque_impulse(body_torque_impulse_force * speed * delta)
		upper_body.apply_torque_impulse(body_torque_impulse_force * speed * delta)
	
	if Input.is_action_pressed("ui_down") or agent.backward :
		for wheel in wheels:
			if wheel.angular_velocity > -max_speed:
				wheel.apply_torque_impulse(-speed * delta)
	
	
	# Update distance traveled (right increases, left decreases)
	distance_traveled = 0
	
	var current_position_x = global_position.x
	var delta_position_x = current_position_x - previous_position_x
	
	var old_distance_traveled = distance_traveled 
	
	distance_traveled += round(delta_position_x / 10)
	distance_traveled += 10
	
	distance_check += round(delta_position_x / 10)
	
	if old_distance_traveled == distance_traveled:
		truncate_counter += 0.01
	else:
		truncate_counter = 0


	if truncate_counter >= truncate_limit:
		is_truncated()
	
	if distance_check > distance_to_goal:
		print("goal!")
		goal_is_reached()
		
	if distance_check < backward_distance_limit:
		is_truncated()
	
	previous_position_x = current_position_x

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		player_hit_head()
