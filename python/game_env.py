import asyncio
import numpy as np
import gymnasium as gym
from sync_tcp_client import SyncTCPClient


class GameEnv(gym.Env):
    
    metadata = {
        "render_modes": ["human", "none"],  # "human" for Godot, "none" for headless
        "render_fps": 60  # Match with Godot physics frame rate
    }
    
    def __init__(self, render_mode="human"):
        """Initialize the environment and connect to the Godot server."""
        self.render_mode = render_mode
        self.tcp_client = SyncTCPClient()
# observation format: [dist_to_obstacle, distance_traveled, is_finished]
        # Observation variables
        self._distance_to_box = -1.0
        self._distance_traveled = 0.0
        self._is_finished = 0
        self._goal_reached = 0

        # Define observation space
        self.observation_space = gym.spaces.Dict(
            {
                "distance_to_box": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "distance_traveled": gym.spaces.Box(0.0, 100000.0, shape=(1,), dtype=np.float32),
                "is_finished": gym.spaces.Discrete(2),
                "goal_reached": gym.spaces.Discrete(2)
            }
        )

        # Define action space
        self.action_space = gym.spaces.Discrete(2)

        # Map discrete actions to movement inputs
        self._action_to_inputs = {
            0: [0, 1],  # Move right
            1: [1, 1]   # Jump and move right
        }

        
    def _get_obs(self):
        """Return the current observation as a dictionary."""
        return {
            "distance_to_box": np.array([self._distance_to_box], dtype=np.float32),
            "distance_traveled": np.array([self._distance_traveled], dtype=np.float32),
            "is_finished": int(self._is_finished),
            "goal_reached": int(self._goal_reached)
        }
    
    
    def _update_state(self, observation_dict):
        #print(f"Distance to box diff: {self._distance_to_box - observation_dict["p1"]}")
        
        """Update internal environment state based on received observation."""
        self._distance_to_box = observation_dict.get("p1", 1000.0)
        self._distance_traveled = observation_dict.get("p2", 0.0)
        self._is_finished = observation_dict.get("p3", 0)
        self._goal_reached = observation_dict.get("p4", 0)
        
    
    
    def reset(self, seed=None, options=None):
        """Reset the environment by sending a reset signal to Godot and receiving an initial observation."""
        # Send reset command to Godot and get new initial observation
        observation_dict = self.tcp_client.reset()

        # Update state
        self._update_state(observation_dict)

        return self._get_obs(), {}
    

    def step(self, action):
        """Send an action to Godot and receive the next observation."""
        move = self._action_to_inputs[action]

        # Send action and wait for new observation
        observation_dict = self.tcp_client.step(move)

        # Update internal state
        self._update_state(observation_dict)

        # Compute reward and termination
        terminated = self._is_finished == 1
        truncated = False
        reward = 0.02 * self._distance_traveled
        if self._is_finished and not self._goal_reached:
            reward = -1

        return self._get_obs(), reward, terminated, truncated, {}
    
    
    def close(self):
        """Ensure the connection to Godot is closed properly."""
        self.tcp_client.print_avg_step_time()
        self.tcp_client.close()