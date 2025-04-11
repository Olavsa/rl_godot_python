import os
from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env
from parking_env import ParkingEnv  # Ensure you import your environment correctly

# Create the environment with rendering enabled
env = ParkingEnv(render_mode="human")

# Check the environment for compatibility
#check_env(env, warn=True)

# Define model filename
model_file_name = "ppo_parking_agent"
model_path = f"{model_file_name}.zip"

# Load existing model if available, otherwise initialize a new one
if os.path.exists(model_path):
    print("Loading existing model...")
    model = PPO.load(model_path, env=env)  # Load with the same environment
else:
    print("No existing model found. Creating new one...")
    model = PPO("MultiInputPolicy", env, verbose=1)

num_iterations = 10
timesteps_per_iter = 2048 * 15

for i in range(num_iterations):
    # Train the model (continue training if loaded)
    print(f"Training iteration {i+1}/{num_iterations}...")
    model.learn(total_timesteps=timesteps_per_iter, reset_num_timesteps=False)
    # Save the trained model
    model.save(model_file_name)
    print("Model saved successfully.")

# Close the environment
env.close()
