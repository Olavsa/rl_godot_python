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
n_eval_episodes = 50

# Episode data
rewards = []

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
        
    rewards.append(total_reward.item())
eval_env.close()


parking_success = sum(rew > 20 for rew in rewards)
success_rate = parking_success / n_eval_episodes * 100

# Simple eval print
print(f"Episodes run: {n_eval_episodes}")
print(f"\tEpisode reward mean: {np.mean(rewards):.2f}")
print(f"\tMax episode reward:  {np.max(rewards):.2f}")
print(f"\tMin episode reward:  {np.min(rewards):.2f}")
print(f"\tParked: {success_rate:.1f}% ({parking_success}/{n_eval_episodes})")
print(f"\tEP rewards (sorted): {sorted([round(rew, 1) for rew in rewards])}")