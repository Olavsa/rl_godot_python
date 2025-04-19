extends Node

class_name Agents
"""
This controls the agents.

It runs the game for a certain number of steps,
then pauses the game and waits for new input actions from python and this repeats.
"""


signal game_paused # Used to await until game pauses when the server/python asks for new observation before its ready


var human_mode = true
var agent: Agent = null
var agents: Array[Agent] = []

var n_agents: int = 1


var paused = false
@export var frames_per_step = 8

var active_inputs: PackedStringArray = [] # Current input actions received from python

func _ready() -> void:
	await get_parent().ready
	
	if not human_mode:
		agent = get_tree().get_first_node_in_group("AGENTS")
		pause()
		assert(agent != null, "Agent was not found in game process")


func spawn_agents(n_agents: int):
	for i in range(n_agents):
		# create agent
		# add to agents array
	# instantiate agent scenes
	# add as children

## Physics process stops after a certain number of steps to wait for new input.
# This makes it possible to train with different engine speeds and have consistent behavior.
var frame_counter = 0
func _physics_process(_delta):
	if human_mode:
		return
	
	if not human_mode:
		frame_counter += 1
		if frame_counter > frames_per_step:# or agent.get_is_done():
			frame_counter = 0
			pause()



# -------------- FUNCTIONS TO OVERRIDE -----------------------------------------
	
func reset_and_pause():
	## Reset game environment
	# Implement so player and environment are reset
	#push_error("UNIMPLEMEMTED METHOD: game_process.reset")
	
	agent.reset() # If game environment is static, you only need to implement reset in agent.
	# ** Implementation strategy **
	#	1. Reset environment and agent states:
	#		- Can store initial state in provided dictionary and revert from that.
	#		- Or delegate to methods in agent and level
	pause()
# -------------- FUNCTIONS TO OVERRIDE -----------------------------------------






# ----------  IMPLEMENTED FUNCTIONS ----------------------------------------------------------------

func get_observation() -> Array:
	## Collect observation data from the game process.
	# Waits for game process to pause after specified number of steps: frames_per_step.
	# Then gathers and returns new observation from game instance.
	
	if not paused:
		await game_paused
		
	var obs: Array = agent.get_observation()
	return obs

func step(payloads: Array):
	set_input_actions(payloads)
	unpause()


func set_input_actions(actions: Array):
	## Select and trigger key presses in the game based on actions in payload.
	for i in range(n_agents):
		agents[i].set_actions(actions[i])


# ** Pause and unpause game process.
func pause():
	get_tree().paused = true
	paused = true
	emit_signal("game_paused")
	
func unpause():
	get_tree().paused = false
	paused = false
