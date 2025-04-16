extends Agent

class_name ParkingAgent

@export var player: PlayerCar = null # set playable character here

@onready var level: Node3D = $"../.."


# Debug UI labels
@onready var gasText: Label = $"../../../../Control/VBoxContainer/Gas"
@onready var steeringText: Label = $"../../../../Control/VBoxContainer/Steering"
@onready var rewardText: Label = $"../../../../Control/VBoxContainer/EpisodeReward"

const MAX_PARK_DIST = 1000

# Actions
var throttle: float = 0.0
var steering: float = 0.0

var is_parked = false
var collided = false
var init_dist_to_target = 1000.0
var prev_progress = 0.0

var observation: Dictionary = {
	"speed": 0.0,
	"car_pos": [0.0, 0.0],
	"target_pos": [0.0, 0.0],
	"sensors_front": [],
	"sensors_back": [],
	"sensors_middle": [],
	"car_rotation_basis": []

	
}
var init_observation: Dictionary = {
	"speed": 0.0,
	"car_pos": [0.0, 0.0],
	"target_pos": [0.0, 0.0],
	"sensors_front": [],
	"sensors_back": [],
	"sensors_middle": [],
	"car_rotation_basis": []
}

var truncated_counter = 0
var max_seconds = 240 # seconds before truncating
func _physics_process(_delta: float) -> void:
	truncated_counter += 1
	if truncated_counter >= 60 * max_seconds and not truncated:
		truncated = true


# ---------------- OVERRIDE THESE ---------------------------------
func get_observation():
	ep_reward += reward
	rewardText.text = "Ep reward: %.3f" % ep_reward

	update_obs_dict()
	#print(observation["car_rotation_basis"])
	return [observation["speed"],
	observation["car_pos"],
	observation["target_pos"],
	observation["sensors_front"],
	observation["sensors_back"],
	observation["sensors_middle"],
	observation["car_rotation_basis"],
	reward,
	1 if truncated else 0,
	1 if done else 0]
	
	

var colors = [Color.RED, Color.WHITE, Color.GREEN]
func set_actions(_actions: Array):
	throttle = float(_actions[0])
	steering = float(_actions[1])
	
	if $"../../../..".should_render:
		gasText.text = "Throttle: %.2f" % throttle
		gasText.add_theme_color_override("font_color", colors[round(throttle + 1)])
		
		steeringText.text = "Steering: %.2f" % steering
		steeringText.add_theme_color_override("font_color", colors[round(steering + 1)])
	
	
var ep_reward = 0.0
func reset():
	ep_reward = 0.0
	player.reset_car()
	
	done = false
	truncated = false
	truncated_counter = 0
	reward = 0.0
	
	is_parked = false
	collided = false
	init_dist_to_target = player.get_distance_to_parking_spot()
	prev_progress = 0.0
	
	observation = init_observation.duplicate(true)
	throttle = 0
	steering = 0
	
	
	for parking_spot in get_tree().get_nodes_in_group("parking_spot"):
		parking_spot.replace_car()
	if level.set_random_target:
		level.set_random_target_spot()

func update_obs_dict():
	if $"../../../..".should_render:
		if reward > 0.0:
			rewardText.add_theme_color_override("font_color", colors[2])
		else:
			rewardText.add_theme_color_override("font_color", colors[0])
			
	reward = 0.0
	var dist_to_target = player.get_distance_to_parking_spot()
	var tmp_speed = player.get_speed()
	
	if is_parked or truncated:
		done = true
	
	if is_parked:
		reward += 30
		if abs(tmp_speed) < 0.1:
			reward += 10
		print("PARKED!!!!!!!!!")
		
	if truncated:
		reward -= 0.1

	if collided:
		collided = false
		reward -= 0.1
		print("collided")
	
	#if dist_to_target > 3 and abs(tmp_speed) < 0.5:
	#	reward -= 0.1
	var progress = (init_dist_to_target - dist_to_target) / init_dist_to_target	
	var progress_reward = 0.01 * clamp(progress, 0, 1)
	if progress > prev_progress:
		reward += progress_reward
	else:
		reward -= progress_reward
	
	
	reward -= 0.001 # - reward for time to encourage finding the spot faster
	
	observation["speed"] = tmp_speed
	observation["car_pos"] = player.get_car_pos()
	observation["target_pos"] = player.get_target_pos()
	observation["sensors_front"] = player.get_sensors_front()
	observation["sensors_back"] = player.get_sensors_back()
	observation["sensors_middle"] = player.get_sensors_middle()
	observation["car_rotation_basis"] = player.get_rotation_basis()
