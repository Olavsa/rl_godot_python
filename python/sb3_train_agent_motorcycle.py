import os
from stable_baselines3 import PPO
from motorcycle_env import MotorcycleEnv

# Create the environment with rendering enabled
env = MotorcycleEnv(render_mode="human")

# Define model filename
model_path = "PPO_godot_motorcycle_agent.zip"

# Load existing model if available, otherwise initialize a new one
if os.path.exists(model_path):
    print("Loading existing model...")
    model = PPO.load(model_path, env=env)  # Load with the same environment
else:
    print("No existing model found. Creating new one...")
    model = PPO("MultiInputPolicy", env, verbose=1)

# Train the model (continue training if loaded)
num_iterations = 1
timesteps_per_iter = 2048 * 1

for i in range(num_iterations):
    # Train the model (continue training if loaded)
    print(f"Training iteration {i+1}/{num_iterations}...")
    model.learn(total_timesteps=timesteps_per_iter, reset_num_timesteps=False)
    
    # Save the trained model
    model.save("PPO_godot_motorcycle_agent")
    print("Model saved successfully.")

# Close the environment
env.close()
