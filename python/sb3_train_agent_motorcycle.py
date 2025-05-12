import os
from stable_baselines3 import PPO
from godot_gym_envs.motorcycle_env import MotorcycleEnv


# Tensor board log
tensorboard_log_dir = "./python/ppo_motorcycle/tensorboard/ppo_motorcycle_tensorboard/"

# Define model filename
model_file_name = "PPO_godot_motorcycle_agent"
model_path = "./python/ppo_motorcycle/trained_models/PPO_godot_motorcycle_agent"
model_path_zip = model_path + ".zip"

# Create the environment with rendering enabled
env = MotorcycleEnv(render_mode="human")

# Make sure tensorboard log directory exists or is made
if not os.path.exists(tensorboard_log_dir):
    os.makedirs(tensorboard_log_dir)
    print(f"Created log directory: {tensorboard_log_dir}")
else:
    print(f"Log directory already exists: {tensorboard_log_dir}")

# Load existing model if available, otherwise initialize a new one
if os.path.exists(model_path_zip):
    print("Loading existing model...")
    model = PPO.load(model_path_zip, env=env, tensorboard_log= tensorboard_log_dir)  # Load with the same environment
else:
    print("No existing model found. Creating new one...")
    model = PPO("MultiInputPolicy", env, verbose=1, tensorboard_log= tensorboard_log_dir)

# Train the model (continue training if loaded)
num_iterations = 1
timesteps_per_iter = 2048 * 1

for i in range(num_iterations):
    # Train the model (continue training if loaded)
    print(f"Training iteration {i+1}/{num_iterations}...")
    model.learn(total_timesteps=timesteps_per_iter, reset_num_timesteps=False,  tb_log_name=model_file_name)
    
    # Save the trained model
    model.save(model_path)
    print("Model saved successfully.")

# Close the environment
env.close()
