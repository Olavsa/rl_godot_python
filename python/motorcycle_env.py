import asyncio
import numpy as np
import gymnasium as gym
from sync_tcp_client import SyncTCPClient


class MotorcycleEnv(gym.Env):
    
    metadata = {
        "render_modes": ["human", "none"],  # "human" for Godot, "none" for headless
        "render_fps": 60  # Match with Godot physics frame rate
    }
    
    def __init__(self, render_mode="human"):
        """Initialize the environment and connect to the Godot server."""
        self.render_mode = render_mode
        self.tcp_client = SyncTCPClient()

        self._previous_distance_traveled = 0.0
        self._delta_distance = 0.0
        self._previous_linear_velocity_x = 0.0

        # Observation format: [dist_to_obstacle, distance_traveled, is_finished]
        # Observation variables

        # Bike information
        self._distance_traveled = 0.0
        self._position_x = 0
        self._position_y = 0
        self._linear_velocity_x = 0
        self._linear_velcity_y = 0
        self._angular_velocity = 0
        self._bike_rotation = 0

        # Raycasts
        self._raycast1 = 0
        self._raycast2 = 0
        self._raycast3 = 0
        self._raycast4 = 0
        self._raycast5 = 0
        self._raycast6 = 0
        self._raycast7 = 0
        self._raycast8 = 0

        # Flags
        self._is_done = 0
        self._goal_reached = 0
        self._moving_left = 0



        # Define observation space
        self.observation_space = gym.spaces.Dict(
            {
                "distance_traveled": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "position_x": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "position_y": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "linear_velocity_x": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "linear_velcity_y": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "angular_velocity": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "bike_rotation": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),

                "raycast1": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast2": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast3": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast4": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast5": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast6": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast7": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast8": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                
                "is_done": gym.spaces.Discrete(2),
                "goal_reached": gym.spaces.Discrete(2),
                "moving_left": gym.spaces.Discrete(2)
            }
        )

        # Define action space
        self.action_space = gym.spaces.Discrete(5)

        self._action_to_inputs = {
            0: [0, 0, 0, 0, 0],  # Do nothing
            1: [1, 0, 0, 0, 0],  # Forward
            2: [0, 1, 0, 0, 0],  # Backward
            3: [0, 0, 1, 0, 0],  # Lean right
            4: [0, 0, 0, 1, 0],  # Lean left
        }

        
    def _get_obs(self):
        """Return the current observation as a dictionary."""
        return  {
                "distance_traveled": np.array([self._distance_traveled], dtype=np.float32),
                "position_x": np.array([self._position_x], dtype=np.float32),
                "position_y": np.array([self._position_y], dtype=np.float32),
                "linear_velocity_x": np.array([self._linear_velocity_x], dtype=np.float32),
                "linear_velcity_y": np.array([self._linear_velcity_y], dtype=np.float32),
                "angular_velocity": np.array([self._angular_velocity], dtype=np.float32),
                "bike_rotation": np.array([self._bike_rotation], dtype=np.float32),

                "raycast1": np.array([self._raycast1], dtype=np.float32),
                "raycast2": np.array([self._raycast2], dtype=np.float32),
                "raycast3": np.array([self._raycast3], dtype=np.float32),
                "raycast4": np.array([self._raycast4], dtype=np.float32),
                "raycast5": np.array([self._raycast5], dtype=np.float32),
                "raycast6": np.array([self._raycast6], dtype=np.float32),
                "raycast7": np.array([self._raycast7], dtype=np.float32),
                "raycast8": np.array([self._raycast8], dtype=np.float32),

                "is_done": int(self._is_done),
                "goal_reached": int(self._goal_reached),
                "moving_left": int(self._moving_left),
            }
    
    
    def _update_state(self, observation_dict):
        """Update internal environment state based on received observation."""
        self._distance_traveled = observation_dict.get("p1", 0.0)
        self._position_x = observation_dict.get("p2", 0)
        self._position_y = observation_dict.get("p3", 0)
        self._linear_velocity_x = observation_dict.get("p4", 0)
        self._linear_velocity_y = observation_dict.get("p5", 0)
        self._angular_velocity = observation_dict.get("p6", 0)
        self._bike_rotation = observation_dict.get("p7", 0)

        # Raycasts
        self._raycast1 = observation_dict.get("p8", 0)
        self._raycast2 = observation_dict.get("p9", 0)
        self._raycast3 = observation_dict.get("p10", 0)
        self._raycast4 = observation_dict.get("p11", 0)
        self._raycast5 = observation_dict.get("p12", 0)
        self._raycast6 = observation_dict.get("p13", 0)
        self._raycast7 = observation_dict.get("p14", 0)
        self._raycast8 = observation_dict.get("p15", 0)

        # Flags
        self._is_done = observation_dict.get("p16", 0)
        self._goal_reached = observation_dict.get("p17", 0)
        self._moving_left = observation_dict.get("p18", 0)


    def reset(self, seed=None, options=None):
        """Reset the environment by sending a reset signal to Godot and receiving an initial observation."""
        # Send reset command to Godot and get new initial observation
        observation_dict = self.tcp_client.reset()

        # Update state
        self._update_state(observation_dict)

        self._previous_distance_traveled = self._distance_traveled
        self._previous_linear_velocity_x = self._linear_velocity_x

        return self._get_obs(), {}
    

    def step(self, action):
        """Send an action to Godot and receive the next observation."""

        move = self._action_to_inputs[action] 
        #print(f"Action selected: {action} → Move sent to Godot: {move}")

        # Send action and wait for new observation
        observation_dict = self.tcp_client.step(move)

        # Update internal state
        self._update_state(observation_dict)

        # Compute reward and termination
        terminated = truncated = self._is_done == 1

        self._delta_distance = self._distance_traveled - self._previous_distance_traveled
        self._previous_distance_traveled = self._distance_traveled

        self._delta_velocity_x = self._linear_velocity_x - self._previous_linear_velocity_x
        self._previous_linear_velocity_x = self._linear_velocity_x



        if self._is_done == 1:
            terminated = 1
            truncated = 1

        reward = self.compute_reward()
            
        return self._get_obs(), reward, terminated, truncated, {}
    
    def compute_reward(self):
        reward = 0.0

        # Reward based on delta distance
        reward += 5.0 * self._delta_distance

        # Penalty for moving left
        if self._delta_distance < 0:
            reward += 3.0 * self._delta_distance  # note: delta is negative, so this subtracts
            

        # Bonus reward for increasing velocity to the right
        if self._delta_velocity_x > -0.4 and not self._moving_left:
            reward += 1.0 * self._delta_velocity_x

        # Crash penalty
        if self._is_done and not self._goal_reached:
            reward -= 20.0

        # Goal reward
        if self._goal_reached:
            reward += 100.0

        return reward

    
    
    def close(self):
        """Ensure the connection to Godot is closed properly."""
        self.tcp_client.print_avg_step_time()
        self.tcp_client.close()