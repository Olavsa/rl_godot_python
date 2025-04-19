extends Agent


@export var player: Node = null # set playable character here

# ---------------- OVERRIDE THESE ---------------------------------
func get_observation():
	# This should either get observation data from methods in your player instance,
	# or the agent observation data should be continually updated in the player instance.
	push_error("Not implemented: get observation in agent")
	return {
		"observation_data": obs_data,
		"reward": reward,
		"done": done
		}

# Override this
func set_actions(_actions: Array):
	## Set the actions that your agent should perform
	push_error("Not implemented: set actions in agent")
	actions = _actions
	
	
func reset():
	push_error("Not implemented: reset in agent")
	# This should reset the agent state, or this can be done in game_process
	# Keep this
	set_is_done(false)
	set_reward(0)
