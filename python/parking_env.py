import asyncio
import numpy as np
import gymnasium as gym
from sync_tcp_client import SyncTCPClient


class ParkingEnv(gym.Env):
    
    metadata = {
        "render_modes": ["human", "none"],  # "human" for Godot, "none" for headless
        "render_fps": 60  # Match with Godot physics frame rate
    }
    
    def __init__(self, render_mode="human"):
        """Initialize the environment and connect to the Godot server."""
        self.render_mode = render_mode
        self.tcp_client = SyncTCPClient()
        
        # TODO: Define obs variables
        # Observation variables
        self._speed = 0.0
        self._car_pos = np.array([0.0, 0.0])
        self._target_pos = np.array([0.0, 0.0])
        self._sensors_front = np.array([20.0, 20.0, 20.0, 20.0, 20.0])
        self._sensors_back = np.array([20.0, 20.0, 20.0, 20.0, 20.0])
        self._reward = 0.0
        self._truncated = 0
        self._done = 0

        # Define observation space
        self.observation_space = gym.spaces.Dict(
            {
                "speed": gym.spaces.Box(low=0.0, high=100.0, shape=(1,), dtype=np.float32),
                "car_pos": gym.spaces.Box(low=-np.inf, high=np.inf, shape=(2,), dtype=np.float32),
                "target_pos": gym.spaces.Box(low=-np.inf, high=np.inf, shape=(2,), dtype=np.float32),
                "sensors_front": gym.spaces.Box(low=0.0, high=20.0, shape=(5,), dtype=np.float32),
                "sensors_back": gym.spaces.Box(low=0.0, high=20.0, shape=(5,), dtype=np.float32),
                "reward": gym.spaces.Box(low=-15, high=15, shape=(1,), dtype=np.float32),
                "truncated" : gym.spaces.Discrete(2),
                "done": gym.spaces.Discrete(2)
            }
        )

        self.action_space = gym.spaces.Box(
            low=np.array([-1.0, -1.0]),
            high=np.array([1.0, 1.0]),
            dtype=np.float32
        )


    def _get_obs(self):
        return {
            "speed": np.array([self._speed], dtype=np.float32),  # (1,)
            "car_pos": self._car_pos.astype(np.float32),         #  (2,)
            "target_pos": self._target_pos.astype(np.float32),   #  (2,)
            "sensors_front": self._sensors_front.astype(np.float32),  #  (5,)
            "sensors_back": self._sensors_back.astype(np.float32),    #  (5,)
            "reward": np.array([self._reward], dtype=np.float32),     #  (1,)
            "truncated": int(self._truncated),
            "done": int(self._done)
        }


    def _update_state(self, observation_dict):
        #print(f"Distance to box diff: {self._distance_to_box - observation_dict["p1"]}")
        
        """Update internal environment state based on received observation."""
        
        self._speed = observation_dict.get("p1", 0.0)
        self._car_pos = np.array(observation_dict["p2"], dtype=np.float32)
        self._target_pos = np.array(observation_dict["p3"], dtype=np.float32)
        self._sensors_front = np.array(observation_dict["p4"], dtype=np.float32)
        self._sensors_back = np.array(observation_dict["p5"], dtype=np.float32)
        self._reward = observation_dict.get("p6", 0)
        self._truncated = observation_dict.get("p7", 0)
        self._done = observation_dict.get("p8", 0)
        
    
    
    def reset(self, seed=None, options=None):
        """Reset the environment by sending a reset signal to Godot and receiving an initial observation."""
        # Send reset command to Godot and get new initial observation
        observation_dict = self.tcp_client.reset()

        # Update state
        self._update_state(observation_dict)

        return self._get_obs(), {}
    

        # TODO: Define step
    def step(self, action):
        """Send an action to Godot and receive the next observation."""
        move = tuple([int(action[0]), float(action[1])])

        # Send action and wait for new observation
        observation_dict = self.tcp_client.step(move)

        # Update internal state
        self._update_state(observation_dict)

        # Compute reward and termination
        terminated = self._done == 1
        truncated = self._truncated == 1
        
        reward = self._reward

        return self._get_obs(), reward, terminated, truncated, {}
    
    
    def close(self):
        """Ensure the connection to Godot is closed properly."""
        self.tcp_client.print_avg_step_time()
        self.tcp_client.close()