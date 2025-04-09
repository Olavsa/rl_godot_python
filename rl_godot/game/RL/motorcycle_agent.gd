extends Agent

@onready var motorcycle: RigidBody2D = $".."

var forward = 0
var backward = 0
var lean_right = 0
var lean_left = 0
# ---------------- OVERRIDE THESE ---------------------------------
func get_observation():
	# This should either get observation data from methods in your player instance,
	# or the agent observation data should be continually updated in the player instance.
	var observation = []
	#observation.append(player.get_distance_to_box())
	#observation.append(player.distance_traveled)
	#observation.append(int(player.is_finished))
	#observation.append(int(player.goal_reached))
	return observation

func set_actions(_actions: Array):
	forward = _actions[0]
	backward = _actions[1]
	lean_right = _actions[2]
	lean_left = _actions[3]
	
	
func reset():
	#player.reset()
	set_is_done(false)
	set_reward(0)
