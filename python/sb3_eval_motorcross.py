import numpy as np

from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env

from eval_plot_utils import plot_reward_distribution

from godot_gym_envs.motorcycle_env import MotorcycleEnv


# Evaluation environment setup
eval_env = make_vec_env(MotorcycleEnv, 1)
eval_env.training = False  # Important: Turn off training to prevent stats updates

model_file_name = "PPO_godot_motorcycle_agent"
model_path = f"./python/ppo_motorcycle/trained_models/{model_file_name}.zip"

# Load model
model = PPO.load(model_path, env=eval_env)

# Evaluate the model deterministically (i.e., no entropy/randomness)
n_eval_episodes = 50

# Episodes data
rewards = []
goal_reached_counter = 0

for ep in range(n_eval_episodes):
    if ep % 10 == 0: print(f"ep: {ep} / {n_eval_episodes}") # Print eval progress for longer evals
    
    obs = eval_env.reset()
    done = False
    total_reward = 0
    steps = 0

    while not done:
        action, _states = model.predict(obs, deterministic=True)
        obs, reward, done, info = eval_env.step(action)
        total_reward += reward[0]
        steps += 1
    
    rewards.append(total_reward.item())
    
    goal_reached = int(info[0]["terminal_observation"]["goal_reached"])
    if goal_reached:
        goal_reached_counter += 1
        
eval_env.close()

# % of episodes where agent made it to goal without crashing or timout
success_rate = goal_reached_counter / n_eval_episodes * 100

# Simple eval print
print(f"\nEpisodes run: {n_eval_episodes}")
print(f"\tAvg episode reward: {np.mean(rewards):.2f}")

print(f"\n\tMax episode reward:  {np.max(rewards):.2f}")
print(f"\tMin episode reward:  {np.min(rewards):.2f}")

print(f"\n\tGoal reached: {success_rate:.1f}% ({goal_reached_counter}/{n_eval_episodes})")

print(f"\n\tEP rewards (SORTED): {sorted([round(rew, 1) for rew in rewards])}")

# Plot rewards histogram
plot_reward_distribution(rewards, save_path="motocross_eval_plt")



