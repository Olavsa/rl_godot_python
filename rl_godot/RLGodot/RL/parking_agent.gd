extends Agent

class_name ParkingAgent

# Game environment / level
@onready var level: ParkingLevel = $"../.."

# Set playable character here
@export var player: PlayerCar = null

# Configurable episode params
@export var random_pos = false
@export var random_pos_x_lim: float = 3
@export var random_pos_z_lim: float = 5
@export var full_random_rotation = false
@export var random_rotation_180 = false
@export var seconds_before_truncation = 30 # seconds before truncating
@export var reset_on_collision = true


# Debug UI labels
#    Inputs
@onready var gasText: Label = $"../../../../Control/VBoxContainer/Gas"
@onready var steeringText: Label = $"../../../../Control/VBoxContainer/Steering"
#    Episode stats
@onready var rewardText: Label = $"../../../../Control/VBoxContainer/EpisodeReward"


# Actions
var throttle: float = 0.0
var steering: float = 0.0

# Episode environment state info
var is_parked = false
var collided = false
var prev_dist_to_target = 1000.0
const MAX_PARK_DIST = 1000

# Observation definition
var init_observation: Dictionary
var observation: Dictionary = {
	"speed": 0.0,
	"car_pos": [0.0, 0.0],
	"target_pos": [0.0, 0.0],
	"sensors_front": [],
	"sensors_back": [],
	"sensors_middle": [],
	"car_rotation_basis": []	
}

# Episode reward info for UI overlay
var ep_reward_dict: Dictionary = {
	"progress": 0.0,
	"park": 0.0,
	"collided": 0.0,
	"truncated": 0.0,
	"time": 0.0,
	"ep_reward": 0.0
}
var ep_counter = 0


func _ready() -> void:
	init_observation = observation

# Set truncated after seconds_before_truncation
var truncated_counter = 0
func _physics_process(_delta: float) -> void:
	truncated_counter += 1
	if not truncated and truncated_counter >= 60 * seconds_before_truncation:
		truncated = true


# RL methods
func get_observation():
	""" Get next observation from agent.
	Agent updates it's state from player state, then returns the next observation.
	"""
	# Set done flag if parked, truncated or collided
	if is_parked or truncated or (reset_on_collision and collided):
		done = true
		
	# Update step reward from player state
	reward = get_updated_reward()
	# Update observation dict from player state
	update_obs_dict()
	
	if is_parked:
		print("Ep reward: %.2f" % ep_reward_dict["ep_reward"])
	# Return observation + reward, truncated and done
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
	
	
func set_actions(_actions: Array):
	# Set input actions
	throttle = float(_actions[0])
	steering = float(_actions[1])
	
	if $"../../../..".should_render:
		update_ui_input_overlay_text(throttle, steering)
	
	
func reset():
	#print("Ep reward: %.2f" % ep_reward_dict["ep_reward"])
	ep_counter += 1
		
	# Reset car
	reset_player()
	# Reset level and parked cars
	reset_level()

	# Reset actions
	reset_actions()

	# Reset episode flags and state
	reset_episode_flags()
	
	# Reset observation dict
	observation = init_observation.duplicate(true)

	# Reset episode extras
	truncated_counter = 0
	reward = 0.0
	reset_ep_reward_dict()
	# Reinitialize prev_dist to target
	prev_dist_to_target = player.get_distance_to_parking_spot()

func reset_player():
	player.reset_car()
	
	# Random position
	if random_pos:
		random_move_player_xz(random_pos_x_lim, random_pos_z_lim)
	
	# Rotate car if toggled
	if random_rotation_180:
		var rot = PI if randf() > 0.5 else 0.0
		player.rotate_y(rot)
	if full_random_rotation:
		player.rotate_y(2 * PI * randf() - PI)

func reset_level():
	# Reset all cars in parking spots
	for parking_spot in get_tree().get_nodes_in_group("parking_spot"):
		parking_spot.replace_car()
	# Set random target parking spot
	if level.set_random_target:
		level.set_random_target_spot()

func reset_episode_flags():
	done = false
	truncated = false
	is_parked = false
	collided = false

func reset_actions():
	throttle = 0
	steering = 0

func update_obs_dict():
	observation["speed"] = player.get_speed()
	observation["car_pos"] = player.get_car_pos()
	observation["target_pos"] = player.get_target_pos()
	observation["sensors_front"] = player.get_sensors_front()
	observation["sensors_back"] = player.get_sensors_back()
	observation["sensors_middle"] = player.get_sensors_middle()
	observation["car_rotation_basis"] = player.get_rotation_basis()


func get_updated_reward():
	#*** POSITIVE REWARDS ***
	# Reward for progress/distance to parking spot
	var progress_reward = get_progress_reward()
	var park_reward = get_parking_reward()
	
	#*** NEGATIVE REWARDS (positive values and subtracted for final reward sum)***
	const TIME_REWARD = 0.01 # Punish for time taken to encourage faster parking
	var collided_reward = 3 if collided else 0.0     # Punish colliding
	var truncated_reward = 5.0 if truncated else 0.0 # Punish not parking or colliding to prevent agent getting stuck doing nothing.
	# Reset collided flag, so next collision can be caught
	collided = false
	# Reset step reward
	var reward = 0.0
	
	# Sum step reward
	reward += progress_reward
	reward += park_reward
	
	reward -= TIME_REWARD
	reward -= truncated_reward
	reward -= collided_reward
	
	update_ep_reward_dict(progress_reward, park_reward, collided_reward, truncated_reward ,TIME_REWARD, reward)
	# Update UI overlay if rendering
	if $"../../../..".should_render:
		update_ui_stats_overlay_text(ep_reward_dict)
	return reward


func get_progress_reward():
	var dist_to_target = player.get_distance_to_parking_spot()
	var progress = prev_dist_to_target - dist_to_target
	prev_dist_to_target = dist_to_target
	
	progress = 0.3 * progress
	return clamp(progress, -1, 1)

func get_parking_reward():
	if not is_parked:
		return 0.0
	# Get player state needed to calculate rewards
	var player_speed = player.get_speed()

	# Base rewards for parking
	const park_base_reward = 30
	var park_speed_under_10_reward = 20 # Agent gets 0 for speed >= 10 and 20 for speed == 0
	var park_speed_under_3_reward = 20 # Agent gets 0 for speed >= 3 and 20 for speed == 0
	
	# Find normalized speeds for calculating bonus parking rewards
	var speed_abs = abs(player_speed)
	var speed_norm_10 = clampf(speed_abs / 10, 0.0, 1.0)
	var speed_norm_3 = clampf(speed_abs / 3, 0.0, 1.0)

	# Linear bonus for speed below 10 to encourage not parking at full speed
	park_speed_under_10_reward = park_speed_under_10_reward * (1 - speed_norm_10) # speed < 10

	# Non-linear bonus for speed below 3 to encourage fully stopping
	park_speed_under_3_reward = park_speed_under_3_reward * pow((1 - speed_norm_3), 2) # speed < 3
	
	# Add parking rewards
	var park_reward = park_base_reward
	park_reward += park_speed_under_10_reward
	park_reward += park_speed_under_3_reward
	
	# Debug print
	print("\nEpisode ", str(ep_counter))
	print("Speed when parked: %.2f" % player_speed)
	print("Speed bonus: %.1f" % (park_speed_under_10_reward + park_speed_under_3_reward))
	print("Spot: %s" % str(level.target_spot.name))
	
	return park_reward

# Update UI overlay
const COLORS = [Color.RED, Color.WHITE, Color.GREEN]
func update_ui_input_overlay_text(_throttle: float, _steering: float):
	gasText.text = "Throttle: %.2f" % throttle
	gasText.add_theme_color_override("font_color", COLORS[round(throttle + 1)])
	
	steeringText.text = "Steering: %.2f" % steering
	steeringText.add_theme_color_override("font_color", COLORS[round(steering + 1)])

func update_ui_stats_overlay_text(_ep_reward_dict):
	var reward_str = "Ep reward: %.3f" % _ep_reward_dict["ep_reward"]
	reward_str += "\n    progress: %.3f" % _ep_reward_dict["progress"]
	reward_str += "\n    time: %.3f" % _ep_reward_dict["time"]
	#reward_str += "\n    park: %.3f" % _ep_reward_dict["park"]
	#reward_str += "\n    crash: %.3f" % _ep_reward_dict["collided"]
	#reward_str += "\n    timeout: %.3f" % _ep_reward_dict["truncated"]
	rewardText.text = reward_str

func reset_ep_reward_dict():
	ep_reward_dict["progress"] = 0.0
	ep_reward_dict["park"] = 0.0
	ep_reward_dict["collided"] = 0.0
	ep_reward_dict["truncated"] = 0.0
	ep_reward_dict["time"] = 0.0
	ep_reward_dict["ep_reward"] = 0.0

func update_ep_reward_dict(progress_reward, park_reward, collided_reward, truncated_reward ,time_reward, reward):
	ep_reward_dict["progress"] += progress_reward
	ep_reward_dict["park"] += park_reward
	ep_reward_dict["collided"] -= collided_reward
	ep_reward_dict["truncated"] -= truncated_reward
	ep_reward_dict["time"] -= time_reward
	ep_reward_dict["ep_reward"] += reward


func random_move_player_xz(x_lim: float, z_lim: float):
	var dist_x = x_lim * randf()
	var dist_z = z_lim * randf()
	dist_x = -dist_x if randf() < 0.5 else dist_x
	dist_z = -dist_z if randf() < 0.5 else dist_z
	player.global_position.x += dist_x
	player.global_position.z += dist_z
