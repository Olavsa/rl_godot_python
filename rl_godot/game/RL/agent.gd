extends Node

class_name Agent


var done: bool = false
var reward: float = 0.0
var obs_data: Array = [] # Define observation data here
var actions = null # Define actions here. Use for controlling character in player code.

var needs_reset: bool = false


func _enter_tree() -> void:
	#print("adding to group AGENTS")
	add_to_group("AGENTS")

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

func set_actions(_actions: Array):
	## Set the actions that your agent should perform
	push_error("Not implemented: set actions in agent")
	actions = _actions
	
	
func reset():
	push_error("Not implemented: reset in agent")
	set_is_done(false)
	set_reward(0)
	# This should reset the agent state, or this can be done in game_process
	
	
# ^---------------- OVERRIDE THESE ---------------------------------^


# Use these to set agent info in player script
func get_is_done():
	return done

func set_observation(_obs_arr: Array):
	obs_data = _obs_arr

func set_is_done(is_done: bool):
	done = is_done
	
func set_reward(_reward: int):
	reward = _reward

func pause():
	# TODO: Find a way to access player more directly
	get_parent().call("set_physics_process", false)
	
func unpause():
	# TODO: Find a way to access player more directly
	get_parent().call("set_physics_process", true)
