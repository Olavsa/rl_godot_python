extends Node

class_name GameProcess
"""
This controls the game process.

It runs the game for a certain number of steps,
then pauses the game and waits for new input actions from python and this repeats.
"""


signal game_paused # Used to await until game pauses when the server/python asks for new observation before its ready

@onready var main = $".."

var human_mode = true
var agent: Agent = null


var paused = false
@export var frames_per_step = 8

var active_inputs: PackedStringArray = [] # Current input actions received from python

var initial_state: Dictionary # Store game state that needs to be reset here

func _ready() -> void:
	await main.ready
	
	if not human_mode:
		agent = get_tree().get_first_node_in_group("AGENTS")
		pause()
		assert(agent != null, "Agent was not found in game process")

## Physics process stops after a certain number of steps to wait for new input.
# This makes it possible to train with different engine speeds and have consistent behavior.
var frame_counter = 0
func _physics_process(_delta):
	if human_mode:
		return
	
	if not human_mode:
		frame_counter += 1
		if agent.get_is_done() or frame_counter >= frames_per_step:
			frame_counter = 0
			pause()


func reset_and_pause():
	## Reset game environment
	# Implement reset in agent, so that player and environment state are reset
	
	release_inputs()
	agent.reset()
	
	pause()



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


func set_input_actions(payloads: Array):
	## Select and trigger key presses in the game based on actions in payload.	
	agent.set_actions(payloads)


# ** Pause and unpause game process.
func pause():
	get_tree().paused = true
	paused = true
	
	emit_signal("game_paused")
	
func unpause():
	get_tree().paused = false
	paused = false


# ** Trigger and release key inputs from string array
func trigger_inputs(new_input_actions: PackedStringArray):
	## Set active input actions/key presses.
	## The keys are pressed and held between updates, so must be released when not active.

	# Release keys that are no longer active
	for input in active_inputs:
		if input not in new_input_actions:
			#print("Releasing " + input)
			Input.action_release(input)

	# Press keys that are newly activated
	for input in new_input_actions:
		if input not in active_inputs:
			#print("Pressing " + input)
			Input.action_press(input)

	# Update active input actions
	active_inputs = new_input_actions.duplicate()

func release_inputs():
	## Releases all pressed keys (removes all active actions)
	#print("Releasing all keys pressed.")
	for input in active_inputs:
		Input.action_release(input)
	active_inputs = []
# **
