import time
from tcp.sync_tcp_client import SyncTCPClient
from godot_gym_envs.game_env import GameEnv

def get_action_tcp_test(observation_dict):
    """
    Dummy action logic based on observations from Godot.
    Agent should get to the goal with these actions."""
    
    # observation format: [dist_to_obstacle, distance_traveled, is_finished, goal_reached]
    dist_to_obstacle = observation_dict.get("p1", 0)
    is_finished = observation_dict.get("p3", False)

    if 0 <= dist_to_obstacle <= 150:
        return (1, 1)  # Jump and move right
    elif is_finished:
        return (0, 0)  # Stop moving
    else:
        return (0, 1)  # Move right
    
def get_action_gym_test(observation_dict):
    """
    Dummy action logic based on observations from Godot and gymnasium.
    Agent should get to the goal with these actions."""
    
    dist_to_obstacle = observation_dict["distance_to_box"]

    if 0 <= dist_to_obstacle <= 150:
        return 1  # Jump and move right
    else:
        return 0  # Move right


def test_agent_gym_env():
    """Tests agent behavior with gym environment."""
    env = GameEnv("human")
    
    episode_count = 0
    max_episodes = 1  # Run multiple episodes

    while episode_count < max_episodes:
        print(f"\n\n==== Starting Episode {episode_count+1} ====")

        # Reset environment at the start of each episode
        observation = env.reset()[0]
        print(f"Initial Observation: {observation}")

        step_count = 0
        done = False
        while not done:
            action = get_action_gym_test(observation)
            print(f"Step {step_count+1}: Sending action {action}")
            
            observation = env.step(action)[0]
            done = observation["is_finished"]
            print(f"Observation: {observation}, Done: {done}")

            if done:
                print("Game finished! Resetting environment...")
                break  # Reset next loop iteration

            step_count += 1

        episode_count += 1

    print("Test completed successfully.")



def test_agent_tcp():
    """Tests agent behavior with reset support in Godot."""
    
    with SyncTCPClient() as client:
        print("Client connected successfully.")

        episode_count = 0
        max_episodes = 1  # Run multiple episodes

        while episode_count < max_episodes:
            print(f"\n\n==== Starting Episode {episode_count+1} ====")

            # Reset environment at the start of each episode
            observation = client.reset()
            print(f"Initial Observation: {observation}")

            step_count = 0
            done = False
            while not done:
                action = get_action_tcp_test(observation)
                print(f"Step {step_count+1}: Sending action {action}")
                
                observation = client.step(action)
                done = observation["p3"]
                print(f"Observation: {observation}, Done: {done}")

                if done:
                    print("Game finished! Resetting environment...")
                    break  # Reset next loop iteration

                step_count += 1

            episode_count += 1

    print("Test completed successfully.")

if __name__ == "__main__":
    test_agent_tcp()
    #test_agent_gym_env()