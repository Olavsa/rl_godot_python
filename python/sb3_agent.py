import os
from stable_baselines3 import DQN
from stable_baselines3.common.env_checker import check_env
from motorcycle_env import MotorcycleEnv  # Ensure you import your environment correctly

# Create the environment with rendering enabled
env = MotorcycleEnv(render_mode="human")

# Check the environment for compatibility
#check_env(env, warn=True)

# Define model filename
model_path = "DQN_godot_motorcycle_agent.zip"

# Load existing model if available, otherwise initialize a new one
if os.path.exists(model_path):
    print("Loading existing model...")
    model = DQN.load(model_path, env=env)  # Load with the same environment
else:
    print("No existing model found. Creating new one...")
    model = DQN("MultiInputPolicy", env, verbose=1)

# Train the model (continue training if loaded)
model.learn(total_timesteps=2048*200)

# Save the trained model
model.save("DQN_godot_motorcycle_agent")
print("Model saved successfully.")

# Close the environment
env.close()
