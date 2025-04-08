extends CharacterBody2D

class_name Player

var is_finished = false
var goal_reached = false
var local_col_point
var distance_traveled = 0

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
@onready var agent: Agent = $Agent

var initial_state = {}  # Dictionary to store the initial state


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():

	# Store the initial state when the player enters the scene
	initial_state = {
		"position": position,
		"velocity": Vector2.ZERO,
		"is_finished": false,
		"goal_reached": false,
		"distance_traveled": 0
	}
	
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _physics_process(delta):

	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if (agent.jump or Input.is_action_pressed("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
		
	# Get the input direction and handle the movement/deceleration.
	var direction = 0
	if Input.is_action_pressed("move_right"):
		direction = 1
	elif Input.is_action_pressed("move_left"):
		direction = -1
		
	direction = agent.move
	
	# Update distance traveled
	distance_traveled = direction * SPEED * delta
	
	# Set velocity and trigger move
	velocity.x = direction * SPEED
	move_and_slide()


func _on_area_2d_goal_reached():
	#print("goal")
	is_finished = true
	goal_reached = true
	agent.set_is_done(true)
	
	reset_position_velocity()


func get_distance_to_box():
	var dist_to_obstacle: int = 1000
	
	# Return -1 for both distances if raycast is not hitting anything
	if not $RayCast2D.is_colliding():
		return dist_to_obstacle


	var collider = $RayCast2D.get_collider()
	var col_point = $RayCast2D.get_collision_point()
	var local_col_point = to_local(col_point)
	
	var dist_to_collider = round(local_col_point.x)
	dist_to_obstacle = dist_to_collider if collider.is_in_group("obstacle") else 1000
	
	return dist_to_obstacle

func reset():
	# Restore initial state
	reset_position_velocity()
	
	is_finished = initial_state["is_finished"]
	distance_traveled = initial_state["distance_traveled"]
	goal_reached = initial_state["goal_reached"]

func reset_position_velocity():
	position = initial_state["position"]
	velocity = initial_state["velocity"]
	

	
	
func obstacle_hit(_body: Node2D) -> void:
	#print("obstacle hit")
	is_finished = true
	goal_reached = false
	reset_position_velocity()
	
	agent.set_is_done(true)
