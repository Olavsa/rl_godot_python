# Reinforcement Learning in Godot

This project connects reinforcement learning (RL) in Python with interactive simulations in the Godot game engine. It uses **Stable Baselines 3** for RL and supports custom environments built in Godot. Communication between Python and Godot occurs over TCP using a JSON-based protocol.

## Previous Work

- [godot_rl_agents (Beeching, 2021)](https://github.com/edbeeching/godot_rl_agents)  
  This project provides a general-purpose framework for connecting Godot with reinforcement learning agents in Python. It supports multiple RL algorithms and environments using a more abstract and generalized approach. Our project is meant as a complementary solution, offering a playground for experimentation, new functionality, and possible optimizations.

- [YouTube Demo by Lucy Lavend](https://www.youtube.com/watch?v=nPX9MrnvNLo&t=71s&ab_channel=LucyLavend)  
  This video served as creative inspiration for the design and assets used in the 2D motorcycle simulation environment.



## Features

- **Reinforcement Learning** via Stable Baselines 3 (PPO & DQN)
- **Custom environments** built in Godot (2D motorcycle and 3D parking simulator)
- **Gymnasium-compatible** Python environments
- Asynchronous/synchronous TCP communication (via asyncio)
- Adjustable simulation speeds and headless option

## System Architecture

The system is structured as two parallel processes:

- The Python client handles agent training and environment interfacing.
- The Godot server handles simulation logic and agent interactions.

These processes communicate over TCP using a structured JSON protocol. Each Gymnasium-compatible environment in Python owns a TCP client instance that sends step/reset commands to the Godot server, which returns observations and rewards.

### Communication Flow (Example: One Step)

1. SB3 computes the next action and sends it via Gymnasium env → SyncTCPClient → AsyncTCPClient.
2. AsyncTCPClient sends the action over TCP to Godot.
3. Godot's TCP server passes the action to the GameProcess.
4. GameProcess invokes the agent, updates simulation, and returns observations.
5. Godot sends observations back to Python.
6. Python parses the JSON and updates the Gym environment.

## Folder Structure

### Python (rl_godot_python/python)

- Scripts for training/evaluating agents
- Environments defined in `godot_gym_envs/`
- TCP clients in `tcp/`
- Trained models in `ppo_motorcycle/` and `ppo_parking/`

### Godot (rl_godot_python/rl_godot)

- `game/`: Contains 2D/3D environments (motorcycle/parking)
- `RLGodot/`: RL core scripts (agent, simulation, GameProcess)
- `tcp/`: TCP server implementation
- `test_tools/`: Includes performance tests

## Requirements

### Software

- [Godot Engine 4.4.1](https://godotengine.org/)
- [Python 3.12](https://www.python.org/)  
  (Note: Python 3.13 is not fully compatible with TensorBoard as of May 2025)
  
Asyncio is included as a dependency.

### Python Packages

```bash
pip install gymnasium
pip install stable-baselines3
pip install tensorboard
```
## Installation & Running

1. Clone/download this repository
2. Open `rl_godot_python/python` in your IDE
3. Set up a virtual environment and install the python packages
4. Open Godot Engine → Import `rl_godot` from `rl_godot_python/rl_godot`

## Running the Motorcycle Environment

### Without RL Agent

- Open `motorcycle_env.tscn` under `game/game_envs/2d_motorcycle_env/`
- Select the Main node
- Enable `Human Mode` and `Should Render`
- Click `Run Current Scene`

### With RL Agent

- Same as above, but disable `Human Mode`
- Click `Run Current Scene`, this should now wait for a Python Client to connect
- In Pyton, run `sb3_eval_motorcross.py` or `sb3_train_agent_motorcycle.py` depending if you want to train or evaluate an agent

## Running the Parking Simulator

### Without RL Agent

- Open `rl_parking_game.tscn` under `game/game_envs/parking_simulator_3d/rl_scene/`
- Select the `RLParkingGame` node
- Enable `Human Mode`
- Run `Current Scene`

### With RL Agent

- Disable `Human Mode` in `RLParkingGame`
- Click `Run Current Scene`, this should now wait for a Python Client to connect
- Run `sb3_eval_parking.py` or `sb3_train_agent_parking3d.py` depending if you want to train or evaluate an agent

## Configuring Simulation Randomness in the Motorcycle Environment

- Open the `Terrain` node in `motorcycle_env.tscn`
- Adjust randomness parameters (e.g. wind, oil patches) in the Inspector

## Configuring Simulation Randomness in the Parking Environment
For random parking spot:
- Open the `Level_2` node in `rl_parking_game.tscn` which is found under `RLParkingGame/GameProcess/Level_2/hatchback_car/Agent`
- Toggle Random Taregt in the Inspector

For random starting position:
- Open the `Agent` node in `rl_parking_game.tscn` which is found under `RLParkingGame/GameProcess/Level_2`
- Toggle Random Pos in the Inspector

## Testing

- Functional testing of SB3 training scripts
- Integration testing between Python and Godot (e.g. `test_integration_godot_tcp_mvp.py`)
- Performance benchmarking via `test_training_speed.py`

## Security

This system runs locally and does not handle user data. All communication occurs via local TCP loopback (127.0.0.1), so no encryption or hashing is used.

