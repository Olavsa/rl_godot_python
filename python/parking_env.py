import asyncio
import numpy as np
import gymnasium as gym
from sync_tcp_client import SyncTCPClient


class ParkingEnv(gym.Env):
    """Gymnasium environment for integration with Godot 'Parking Simulator' simulated environment."""
    metadata = {
        "render_modes": ["human", "none"],
        "render_fps": 60
    }
    
    def __init__(self, render_mode="human"):
        """Initialize the environment and connect to the Godot server."""
        self.render_mode = render_mode
        self.tcp_client = SyncTCPClient()
        
        # Observation variables
        self._speed = 0.0
        self._car_pos = np.array([0.0, 0.0])
        self._target_pos = np.array([0.0, 0.0])
        self._sensors_front = np.array([20.0] * 13)
        self._sensors_back = np.array([20.0] * 13)
        self._sensors_middle = np.array([20.0] * 6)
        self._rotation = np.array([0.0]*3)
        
        self._reward = 0.0
        self._truncated = 0
        self._done = 0

        # Upper bound for car and target position.
        POS_LIMIT = np.float32(1e4)

        self.observation_space = gym.spaces.Dict(
            {
                "speed": gym.spaces.Box(low=0.0, high=100.0, shape=(1,), dtype=np.float32),
                "car_pos": gym.spaces.Box(low=-POS_LIMIT, high=POS_LIMIT, shape=(2,), dtype=np.float32),
                "target_pos": gym.spaces.Box(low=-POS_LIMIT, high=POS_LIMIT, shape=(2,), dtype=np.float32),
                "sensors_front": gym.spaces.Box(low=0.0, high=20.0, shape=(13,), dtype=np.float32),
                "sensors_back": gym.spaces.Box(low=0.0, high=20.0, shape=(13,), dtype=np.float32),
                "sensors_middle": gym.spaces.Box(low=0.0, high=20.0, shape=(6,), dtype=np.float32),
                "rotation": gym.spaces.Box(low=-1.0, high=1.0, shape=(3,), dtype=np.float32)
            }
        )

        self.action_space = gym.spaces.Box(
            low=np.array([-1.0, -1.0], dtype=np.float32),
            high=np.array([1.0, 1.0], dtype=np.float32),
            dtype=np.float32
        )


    def _get_obs(self):
        return {
            "speed": np.array([self._speed], dtype=np.float32),  # (1,)
            "car_pos": self._car_pos.astype(np.float32),         #  (2,)
            "target_pos": self._target_pos.astype(np.float32),   #  (2,)
            "sensors_front": self._sensors_front.astype(np.float32),  #  (13,)
            "sensors_back": self._sensors_back.astype(np.float32),    #  (13,)
            "sensors_middle": self._sensors_middle.astype(np.float32),    #  (6,)
            "rotation": self._rotation.astype(np.float32)    #  (3,)
        }


    def _update_state(self, observation_dict):
        """Update internal environment state based on received observation."""
        
        self._speed = observation_dict.get("p1", 0.0)
        self._car_pos = np.array(observation_dict["p2"], dtype=np.float32)
        self._target_pos = np.array(observation_dict["p3"], dtype=np.float32)
        self._sensors_front = np.array(observation_dict["p4"], dtype=np.float32)
        self._sensors_back = np.array(observation_dict["p5"], dtype=np.float32)
        self._sensors_middle = np.array(observation_dict["p6"], dtype=np.float32)
        self._rotation = np.array(observation_dict["p7"], dtype=np.float32)
        
        self._reward = observation_dict.get("p8", 0)
        self._truncated = observation_dict.get("p9", 0)
        self._done = observation_dict.get("p10", 0)
        
    
    
    def reset(self, seed=None, options=None):
        """Reset the environment by sending a reset signal to Godot and receiving an initial observation."""
        observation_dict = self.tcp_client.reset()

        self._update_state(observation_dict)

        return self._get_obs(), {}
    

    def step(self, action):
        """Send an action to Godot and receive the next observation."""
        observation_dict = self.tcp_client.step(action)

        self._update_state(observation_dict)

        terminated = self._done == 1
        truncated = self._truncated == 1
        
        reward = self._reward

        return self._get_obs(), reward, terminated, truncated, {}
    
    
    def close(self):
        """Ensure the connection to Godot is closed properly."""
        self.tcp_client.print_avg_step_time()
        self.tcp_client.close()