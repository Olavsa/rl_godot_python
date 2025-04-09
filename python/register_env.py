from gymnasium.envs.registration import register

register(
    id="mvpEnv-v0",
    entry_point="game_env:GameEnv"
)