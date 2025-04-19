import numpy as np

from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.vec_env import VecNormalize

from parking_env import ParkingEnv

# Evaluation environment setup (fresh env for eval, with rendering enabled if needed)
eval_env = make_vec_env(ParkingEnv, 1)
eval_env = VecNormalize.load("./python/ppo_parking/trained_models/vec_normalize.pkl", eval_env)
eval_env.training = False  # Important: Turn off training to prevent stats updates
eval_env.norm_reward = False  # Optional: Keep rewards in original scale

model_file_name = "tmp_ppo_agent"
model_path = f"./python/ppo_parking/trained_models/{model_file_name}.zip"

# Load model
model = PPO.load(model_path, env=eval_env)

# Evaluate the model deterministically (i.e., no entropy/randomness)
n_eval_episodes = 10

for ep in range(n_eval_episodes):
    obs = eval_env.reset()
    done = False
    total_reward = 0
    steps = 0

    while not done:
        action, _states = model.predict(obs, deterministic=True)
        obs, reward, done, info = eval_env.step(action)
        total_reward += reward
        steps += 1
eval_env.close()