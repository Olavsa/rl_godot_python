import os
from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env
from stable_baselines3.common.monitor import Monitor
from parking_env import ParkingEnv  # Ensure you import your environment correctly
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.vec_env import VecNormalize, VecMonitor

# Create the environment with rendering enabled
#env = ParkingEnv(render_mode="human")

env = make_vec_env(ParkingEnv, n_envs=1)
env = VecNormalize(env, norm_obs=True, norm_reward=True)

tensorboard_log_dir = "./python/ppo_parking/tensorboard/ppo_parking_tensorboard_3/"
# Define model filename
model_file_name = "ppo_4_reward_normalization"

model_path = f"./python/ppo_parking/trained_models/{model_file_name}.zip"
tmp_model_path = f"./python/ppo_parking/trained_models/tmp_ppo_agent.zip"

# Wrap with monitor for logging
env = VecMonitor(env, filename=tensorboard_log_dir)

policy_kwargs = dict(
    net_arch=[dict(pi=[256, 256], vf=[256, 256])]
)
# Check the environment for compatibility
#check_env(env, warn=True)


if not os.path.exists(tensorboard_log_dir):
    os.makedirs(tensorboard_log_dir)
    print(f"Created log directory: {tensorboard_log_dir}")
else:
    print(f"Log directory already exists: {tensorboard_log_dir}")

# Load existing model if available, otherwise initialize a new one
if os.path.exists(model_path):
    print("Loading existing model...")
    model = PPO.load(model_path, env=env, tensorboard_log= tensorboard_log_dir)  # Load with the same environment
    model.target_kl = 0.3

elif os.path.exists(tmp_model_path): # load model from previous model on new runs
    print("Loading backup model")
    model = PPO.load(tmp_model_path, env=env, tensorboard_log= tensorboard_log_dir)
else:
    print("No existing model found. Creating new one...")
    model = PPO("MultiInputPolicy", env, policy_kwargs=policy_kwargs, verbose=1, tensorboard_log= tensorboard_log_dir)


# Load VecNormalize stats before starting training
norm_pkl_path = f"./python/ppo_parking/trained_models/{model_file_name}_vec_normalize.pkl"
backup_norm_pkl_path = f"./python/ppo_parking/trained_models/vec_normalize.pkl"
if os.path.exists(norm_pkl_path):
    print("Loading VecNormalize stats...")
    env = VecNormalize.load(norm_pkl_path, env)
elif os.path.exists(backup_norm_pkl_path):
    print("Loading BACKUP VecNormalize stats...")
    env = VecNormalize.load(backup_norm_pkl_path, env)

num_iterations = 30
timesteps_per_iter = 2048 * 5
for i in range(num_iterations):
    # Train the model (continue training if loaded)
    print(f"Training iteration {i+1}/{num_iterations}...")
    result = model.learn(total_timesteps=timesteps_per_iter, reset_num_timesteps=False, tb_log_name=model_file_name)
    print(result)
    # Save the trained model
    model.save(f"./python/ppo_parking/trained_models/{model_file_name}")
    print("Model saved successfully.")
    # Save backup model
    model.save(tmp_model_path)
    print("Backup model saved successfully.")
    
    env.save(norm_pkl_path)
    env.save(backup_norm_pkl_path)
    print("VecNormalize stats saved.")

# Close the environment
env.close()
