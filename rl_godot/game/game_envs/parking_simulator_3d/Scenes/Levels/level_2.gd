extends Node3D
class_name ParkingLevel
@export var run_random_input_test = false

@export var set_random_target = true
@export var target_spot: ParkingSpot = null

var rnd = RandomNumberGenerator.new()
var rnd_seed = 123

@onready var player_car: VehicleBody3D = $hatchback_car

func _ready() -> void:
	rnd.set_seed(rnd_seed)
	
	if set_random_target:
		set_random_target_spot()
	else:	
		set_target_spot(target_spot)


func _physics_process(_delta: float) -> void:
	if run_random_input_test:
		test()

func set_random_target_spot():
	var parking_spots = get_tree().get_nodes_in_group("parking_spot")
	var rand_spot_nr = randi_range(0, parking_spots.size() - 1)
	
	set_target_spot(parking_spots[rand_spot_nr])
	

func set_target_spot(parking_spot: ParkingSpot):
	if target_spot != null:
		target_spot.is_target = false
		target_spot.remove_as_target()
	parking_spot.set_as_target()
	target_spot = parking_spot


func run_rand_input_action():
	var r = rnd.randi_range(0, 5)
	if r == 0:
		Input.action_press("ui_up")
		Input.action_release("ui_down")
	if r == 1:
		Input.action_release("ui_up")
		Input.action_press("ui_down")
	if r == 2:
		Input.action_press("ui_right")
		Input.action_release("ui_left")
	if r == 3:
		Input.action_press("ui_left")
		Input.action_release("ui_right")
		

func test():
	# Seed=123 with render and 8x speed -> 		 Position after 6000 ticks: (5.441027, 0.023884, 18.48198)
	# Seed 123 withhout render and 200x speed -> Position after 6000 ticks: (5.441027, 0.023884, 18.48198)
	run_rand_input_action()
	var physics_ticks = Engine.get_physics_frames()
	const base_fps = 60
	const time_before_check_pos = 20
	if physics_ticks % (base_fps * time_before_check_pos) == 0:
		print("Position after "+ str(physics_ticks) + " ticks: %s" % str($hatchback_car.global_position))		


# 1x with rendering
#Position after 1200 ticks: (23.80098, 0.022456, -3.81862)
#Position after 2400 ticks: (24.53352, 0.027196, -2.218262)
#Position after 3600 ticks: (17.78854, 0.029036, 5.794172)
#Position after 4800 ticks: (19.8131, 0.029738, 7.954369)
#Position after 6000 ticks: (23.4629, 0.02725, 16.91899)
#Position after 18000 ticks:(-6.77454, 0.027036, 8.081354)


# 8x with rendering
#Position after 1200 ticks: (23.80098, 0.022456, -3.81862)
#Position after 2400 ticks: (24.53352, 0.027196, -2.218262)
#Position after 3600 ticks: (17.78854, 0.029036, 5.794172)
#Position after 4800 ticks: (19.8131, 0.029738, 7.954369)
#Position after 6000 ticks: (23.4629, 0.02725, 16.91899)
#Position after 18000 ticks: (-6.77454, 0.027036, 8.081354)

# 16x with rendering
#Position after 1200 ticks: (23.80098, 0.022456, -3.81862)
#Position after 2400 ticks: (24.53352, 0.027196, -2.218262)
#Position after 3600 ticks: (17.78854, 0.029036, 5.794172)
#Position after 4800 ticks: (19.8131, 0.029738, 7.954369)
#Position after 6000 ticks: (23.4629, 0.02725, 16.91899)
#Position after 18000 ticks: (-6.77454, 0.027036, 8.081354)



#50x without rendering
#Position after 1200 ticks: (23.80098, 0.022456, -3.81862)
#Position after 2400 ticks: (24.53352, 0.027196, -2.218262)
#Position after 3600 ticks: (17.78854, 0.029036, 5.794172)
#Position after 4800 ticks: (19.8131, 0.029738, 7.954369)
#Position after 6000 ticks: (23.4629, 0.02725, 16.91899)
#Position after 18000 ticks: (-6.77454, 0.027036, 8.081354)
