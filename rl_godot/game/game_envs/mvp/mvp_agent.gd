extends Agent


@export var player: Player = null # set playable character here

var jump = 0
var move = 0
# ---------------- OVERRIDE THESE ---------------------------------
func get_observation():
	# This should either get observation data from methods in your player instance,
	# or the agent observation data should be continually updated in the player instance.
	var observation = []
	observation.append(player.get_distance_to_box())
	observation.append(player.distance_traveled)
	observation.append(int(player.is_finished))
	observation.append(int(player.goal_reached))
	print(observation)
	return observation

func set_actions(_actions: Array):
	jump = _actions[0]
	move = _actions[1]
	
	
func reset():
	player.reset()
	set_is_done(false)
	set_reward(0)
