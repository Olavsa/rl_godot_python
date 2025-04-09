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
# observation format: [dist_to_obstacle, distance_traveled, is_finished]
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
        self._raycast9 = 0
        self._raycast10 = 0
        self._raycast11 = 0
        self._raycast12 = 0
        self._raycast13 = 0
        self._raycast14 = 0
        
        # Wheels
        self._wheel_1_linear_velocity_x = 0
        self._wheel_1_linear_velocity_y = 0
        self._wheel_2_linear_velocity_x = 0
        self._wheel_2_linear_velocity_y = 0

        self._wheel_1_angular_velocity = 0
        self._wheel_2_angular_velocity = 0

        self._wheel_1_rotation = 0
        self._wheel_2_rotation = 0

        # Flags
        self._is_truncated = 0
        self._goal_reached = 0
        self._hit_head = 0
        self._is_finished = 0



        # Define observation space
        self.observation_space = gym.spaces.Dict(
            {
                "_distance_traveled": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
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
                "raycast9": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast10": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast11": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast12": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast13": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "raycast14": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),

                "wheel_1_linear_velocity_x": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "wheel_1_linear_velocity_y": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "wheel_2_linear_velocity_x": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "wheel_2_linear_velocity_y": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),

                "wheel_1_angular_velocity": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "wheel_2_angular_velocity": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),

                "wheel_1_rotation": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                "wheel_2_rotation": gym.spaces.Box(-1.1, 10000.0, shape=(1,), dtype=np.float32),
                
                "is_truncated": gym.spaces.Discrete(2),
                "_goal_reached": gym.spaces.Discrete(2),
                "hit_head": gym.spaces.Discrete(2),
                "is_finished": gym.spaces.Discrete(2)
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
                "_distance_traveled": np.array([self._distance_traveled], dtype=np.float32),
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
                "raycast9": np.array([self._raycast9], dtype=np.float32),
                "raycast10": np.array([self._raycast10], dtype=np.float32),
                "raycast11": np.array([self._raycast11], dtype=np.float32),
                "raycast12": np.array([self._raycast12], dtype=np.float32),
                "raycast13": np.array([self._raycast13], dtype=np.float32),
                "raycast14": np.array([self._raycast14], dtype=np.float32),

                "wheel_1_linear_velocity_x": np.array([self._wheel_1_linear_velocity_x], dtype=np.float32),
                "wheel_1_linear_velocity_y": np.array([self._wheel_1_linear_velocity_y], dtype=np.float32),
                "wheel_2_linear_velocity_x": np.array([self._wheel_2_linear_velocity_x], dtype=np.float32),
                "wheel_2_linear_velocity_y": np.array([self._wheel_2_linear_velocity_y], dtype=np.float32),

                "wheel_1_angular_velocity": np.array([self._wheel_1_angular_velocity], dtype=np.float32),
                "wheel_2_angular_velocity": np.array([self._wheel_2_angular_velocity], dtype=np.float32),

                "wheel_1_rotation": np.array([self._wheel_1_rotation], dtype=np.float32),
                "wheel_2_rotation": np.array([self._wheel_2_rotation], dtype=np.float32),
                
                "is_truncated": int(self._is_truncated),
                "_goal_reached": int(self._goal_reached),
                "hit_head": int(self._hit_head),
                "is_finished": int(self._is_finished),
            }
    
    
    def _update_state(self, observation_dict):
        """Update internal environment state based on received observation."""

        self._distance_to_box = observation_dict.get("p1", 1000.0)
        self._distance_traveled = observation_dict.get("p2", 0.0)
        self._position_x = observation_dict.get("p3", 0)
        self._position_y = observation_dict.get("p4", 0)
        self._linear_velocity_x = observation_dict.get("p5", 0)
        self._linear_velocity_y = observation_dict.get("p6", 0)
        self._angular_velocity = observation_dict.get("p7", 0)
        self._bike_rotation = observation_dict.get("p8", 0)

        # Raycasts
        self._raycast1 = observation_dict.get("p9", 0)
        self._raycast2 = observation_dict.get("p10", 0)
        self._raycast3 = observation_dict.get("p11", 0)
        self._raycast4 = observation_dict.get("p12", 0)
        self._raycast5 = observation_dict.get("p13", 0)
        self._raycast6 = observation_dict.get("p14", 0)
        self._raycast7 = observation_dict.get("p15", 0)
        self._raycast8 = observation_dict.get("p16", 0)
        self._raycast9 = observation_dict.get("p17", 0)
        self._raycast10 = observation_dict.get("p18", 0)
        self._raycast11 = observation_dict.get("p19", 0)
        self._raycast12 = observation_dict.get("p20", 0)
        self._raycast13 = observation_dict.get("p21", 0)
        self._raycast14 = observation_dict.get("p22", 0)

        # Wheels - linear velocities
        self._wheel_1_linear_velocity_x = observation_dict.get("p23", 0)
        self._wheel_1_linear_velocity_y = observation_dict.get("p24", 0)
        self._wheel_2_linear_velocity_x = observation_dict.get("p25", 0)
        self._wheel_2_linear_velocity_y = observation_dict.get("p26", 0)

        # Wheels - angular velocities
        self._wheel_1_angular_velocity = observation_dict.get("p27", 0)
        self._wheel_2_angular_velocity = observation_dict.get("p28", 0)

        # Wheels - rotation
        self._wheel_1_rotation = observation_dict.get("p29", 0)
        self._wheel_2_rotation = observation_dict.get("p30", 0)

        # Flags
        self._is_truncated = observation_dict.get("p31", 0)
        self._goal_reached = observation_dict.get("p32", 0)
        self._hit_head = observation_dict.get("p33", 0)
        self._is_finished = observation_dict.get("p34", 0)


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
        print(f"Action selected: {action} → Move sent to Godot: {move}")

        # Send action and wait for new observation
        observation_dict = self.tcp_client.step(move)

        # Update internal state
        self._update_state(observation_dict)

        # Compute reward and termination
        terminated = self._is_finished == 1
        truncated = self._is_truncated == 1
        hit_head = self._hit_head == 1


        reward = 0.02 * self._distance_traveled

        if (self._is_finished or self._is_truncated or hit_head) and not self._goal_reached:
            reward = -1
        return self._get_obs(), reward, terminated, truncated, {}
    
    
    def close(self):
        """Ensure the connection to Godot is closed properly."""
        self.tcp_client.print_avg_step_time()
        self.tcp_client.close()