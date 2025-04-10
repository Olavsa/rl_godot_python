extends Agent
class_name Motorcycle_agent

@onready var motorcycle: RigidBody2D = $".."

var do_nothing = 0
var forward = 0
var backward = 0
var lean_right = 0
var lean_left = 0
# ---------------- OVERRIDE THESE ---------------------------------
func get_observation():
	var obs = []
	var safe_goal_distance = max(1.0, motorcycle.distance_to_goal)

	obs.append(abs(motorcycle.distance_traveled) / safe_goal_distance)

	obs.append(abs(motorcycle.global_position.x) / 1000.0)
	obs.append(abs(motorcycle.global_position.y) / 1000.0)

	obs.append(abs(motorcycle.linear_velocity.x) / 100.0)
	obs.append(abs(motorcycle.linear_velocity.y) / 100.0)

	obs.append(abs(motorcycle.angular_velocity) / 10.0)

	obs.append(abs(motorcycle.rotation) / PI)

	for ray_distance in motorcycle.get_raycast_info():
		obs.append(clamp(ray_distance / 1000.0, 0.0, 1.0))

	obs.append(int(motorcycle.is_done))
	obs.append(int(motorcycle.goal_reached))
	
	return obs


func set_actions(_actions: Array):
	#print("Received actions: ", _actions)
	do_nothing = _actions[0]
	forward = _actions[1]
	backward = _actions[2]
	lean_right = _actions[3]
	lean_left = _actions[4]
	
	
func reset():
	motorcycle.reset()
	set_is_done(false)
	set_reward(0)
