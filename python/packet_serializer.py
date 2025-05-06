import json
import numpy as np

# Command types
COMMAND_STEP = "step"
COMMAND_RESET = "reset"
COMMAND_SETUP = "setup"
COMMAND_DISCONNECT = "disconnect"


class PacketSerializer:
    """
    Serializes and deserializes packets for TCP communication
    with Godot remote environment. Converts Numpy datatypes for
    JSON compatibility.
    """

    @staticmethod
    def convert_numpy_types(np_obj):
        """
        Recursively convert Numpy types to native
        Python types for JSON serialization.
        """
        if isinstance(np_obj, (np.integer, np.int32, np.int64)):
            return int(np_obj)
        elif isinstance(np_obj, (np.floating, np.float32, np.float64)):
            return float(np_obj)
        elif isinstance(np_obj, np.ndarray):
            return np_obj.tolist()
        elif isinstance(np_obj, (list, tuple)):
            return [PacketSerializer.convert_numpy_types(i) for i in np_obj]
        elif isinstance(np_obj, dict):
            return {k: PacketSerializer.convert_numpy_types(v) for k, v in np_obj.items()}
        else:
            return np_obj

    @staticmethod
    def serialize_step_command(np_action):
        """
        Create a JSON-encoded 'step' command with action data.
        """
        payload = {
            "command": COMMAND_STEP,
            "action": PacketSerializer.convert_numpy_types(np_action)
        }
        return json.dumps(payload)

    @staticmethod
    def serialize_reset_command():
        """
        Create a JSON-encoded 'reset' command.
        """
        return json.dumps({
            "command": COMMAND_RESET
        })
        
    @staticmethod
    def serialize_disconnect_command():
        """
        Create a JSON-encoded 'disconnect' command.
        """
        return json.dumps({
            "command": COMMAND_DISCONNECT
        })

    @staticmethod
    def serialize_setup_command(config):
        """
        Create a JSON-encoded 'setup' command with optional config.
        """
        payload = {
            "command": COMMAND_SETUP,
            "config": PacketSerializer.convert_numpy_types(config)
        }
        return json.dumps(payload)

    @staticmethod
    def dict_from_json_response(json_string):
        """
        Parse a JSON string received from the environment.
        Returns a Python dictionary.
        """
        try:
            return json.loads(json_string)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON received: {e}")
