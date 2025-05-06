from gymnasium.envs.registration import register

# Register custom Gymnasium Environments

register(
    id="mvpEnv-v1",
    entry_point="game_env:GameEnv"
)

register(
    id="parkEnv-v0",
    entry_point="parking_env:ParkingEnv"
)