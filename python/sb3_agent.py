import os
from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env
from game_env import GameEnv  # Ensure you import your environment correctly

# Create the environment with rendering enabled
env = GameEnv(render_mode="human")

# Check the environment for compatibility
#check_env(env, warn=True)

# Define model filename
model_path = "ppo_godot_agent.zip"

# Load existing model if available, otherwise initialize a new one
if os.path.exists(model_path):
    print("Loading existing model...")
    model = PPO.load(model_path, env=env)  # Load with the same environment
else:
    print("No existing model found. Creating new one...")
    model = PPO("MultiInputPolicy", env, verbose=1)

# Train the model (continue training if loaded)
model.learn(total_timesteps=2048)

# Save the trained model
model.save("ppo_godot_agent")
print("Model saved successfully.")

# Close the environment
env.close()
