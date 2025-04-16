extends Node

class_name TCPServerPython


# ***   TCP   ***
# Host server adress
const HOST_IP: String = "127.0.0.1"
const HOST_PORT: int = 8888

var server : TCPServer = null
var client : StreamPeerTCP = null
var connection_thread : Thread = null
# ***   TCP   ***

@onready var game_process: GameProcess = $"../GameProcess"

func _ready():
	await $"../GameProcess".ready


func initialize_and_start(_game_process: GameProcess):
	if connection_thread != null:
		printerr("Connection thread was already set.")
		connection_thread.free()
		get_tree().quit()
	
	# Set game process	
	game_process = _game_process
	
	# Set server to listen for connections
	server = TCPServer.new()
	server.listen(HOST_PORT, HOST_IP)
	print("TCP Server Listening on Port %d" % HOST_PORT)
	
	connection_thread = Thread.new()
	connection_thread.start(_handle_connections)
	
	
func _handle_connections():
	## Runs server thread loop
	# Listens for clients and runs connection when connected
	while true:
		if client != null and client.STATUS_CONNECTED:
			_handle_socket_connection()
		elif server.is_connection_available():
			client = server.take_connection()
			client.set_no_delay(true) # Disable queue delay for socket. See Nagles algorithm
			print("Connected")


func _handle_socket_connection():
## Main loop for socket communaction with Python client
	if client == null:
		get_tree().quit()
		return
		
	client.poll()
	if client == null:
		get_tree().quit()
		return
		
		
	var status = client.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTING:
		# Keep polling to achieve proper close.
		print("connecting...")
		return
		
	if status == StreamPeerTCP.STATUS_CONNECTED:
		# Read python response if input buffer is not empty
		while client.get_available_bytes() > 0:
			# Message: packet type descriptor
			var message = client.get_utf8_string(client.get_available_bytes())
			var action_payloads = Packet.json_to_action_payloads(message)
			#print("From python: ", action_payloads)
			
			# Call correct function on main thread based on received packet type.
			# Deferred functions are run on idle/safe frames in the main thread.
			if action_payloads["action"] == "action":
				# Perform action from python response in game process
				call_deferred("_step", action_payloads["payloads"])
			elif action_payloads["action"] == "reset":
				# Reset game process
				call_deferred("_reset_and_pause")
			elif action_payloads["action"] == "disconnect":
				# Handle python disconnecting
				call_deferred("_release_inputs_and_disconnect")
				return
			# TODO: Handle setup packet

# Helper function to safely perform actions on the main thread
func _step(payloads):
	game_process.step(payloads)
	await _get_and_send_observation()

# Helper function to safely reset the game process
func _reset_and_pause():
	#print("reset and pause")
	game_process.reset_and_pause()
	await _get_and_send_observation()

# Helper function to release inputs and disconnect safely on the main thread
func _release_inputs_and_disconnect():
	game_process.release_inputs()
	disconnectFromPythonSocket()

func _get_and_send_observation():
	## Gets observation from game process and sends it to python over TCP
	# This function is deferred to the main thread
	var obs = await get_observation_json_str()
	sendPacket(obs)

func get_observation_json_str():
	# Returns next observation as a json string.
	var payloads = await game_process.get_observation()
	
	if payloads == null:
		return null
	
	var packet_str = Packet.toString("observation", payloads)
	return packet_str



func sendPacket(obs):
	#print("\nTo python: ", obs)
	client.put_utf8_string(obs)

func disconnectFromPythonSocket():
	print("disconnecting from server...\n")
	client.disconnect_from_host()
	if client.get_status() == StreamPeerTCP.STATUS_NONE:
		client = null
		print("disconnected")

func stop_server_thread():
	if connection_thread != null:
		connection_thread.wait_to_finish()
		connection_thread.free()
	queue_free()
