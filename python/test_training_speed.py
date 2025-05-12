
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env

from godot_gym_envs.parking_env import ParkingEnv
from godot_gym_envs.motorcycle_env import MotorcycleEnv


import time



def training_test(env, save_path, timesteps):
    policy_kwargs = dict(
        net_arch=[dict(pi=[256, 256], vf=[256, 256])]
    )

    model = PPO("MultiInputPolicy", env, policy_kwargs=policy_kwargs, verbose=1)


    print("Starting timer")
    t1 = time.time_ns()
    result = model.learn(total_timesteps=timesteps, reset_num_timesteps=False)
    t2 = time.time_ns()

    time_taken = t2-t1
    print(f"Total time taken: {time_taken} ns")

    env.close()

    if save_path != None and len(save_path) > 0:
        model.save(save_path)


env = make_vec_env(MotorcycleEnv, n_envs=1)
model_save_path = "test_ppo_motorcycle"
timesteps = 2048 * 50


training_test(env, None, timesteps)


# -- Parking Environment ---------
# With rendering. 20480 steps: 314.444726500 s

# Without rendering. 20480 steps:
#   Total training time: 184.554459900 s
#   Time spent in TCP and Godot: 105.5 s (57%)
#   Time spent in Python (sb3): 79.0 s  (43%)
#   Average time per environment step: 5.151425122070312 ms

# Without rendering. 102400 steps:
#   Total training time: 928.069472400 s = 15m 28s
#   Time spent in TCP and Godot: 555 s (60%)
#   Time spent in Python (sb3): 373 s (40%)
#   Average time per environment step: 5.420130905273454 ms


# -- Motorcross Environment --------
# Without rendering. 102400 steps:
#   Total training time: 1346.126657800 s = 22m 46s
#   Time spent in TCP and Godot: 454 s (66%)
#   Time spent in Python (sb3): 373 s (34%)  
#   Average time per environment step: 8.715442057617098 ms


