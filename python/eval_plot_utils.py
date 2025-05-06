import numpy as np
import matplotlib.pyplot as plt

def plot_reward_distribution(rewards, save_path=None, bins=20, range=(-20, 1300)):
    """
    Plots a histogram of episode rewards.
    """
    rewards = np.array(rewards)
    mean_reward = np.mean(rewards)
    median_reward = np.median(rewards)

    plt.figure(figsize=(10, 6))
    plt.hist(rewards, bins=bins, range=range, color='skyblue', edgecolor='black')
    plt.axvline(mean_reward, color='red', linestyle='dashed', linewidth=1.5, label=f'Mean: {mean_reward:.1f}')
    plt.axvline(median_reward, color='green', linestyle='dashed', linewidth=1.5, label=f'Median: {median_reward:.1f}')
    
    plt.title('Episode Reward Distribution')
    plt.xlabel('Reward')
    plt.ylabel('Frequency')
    plt.legend()

    if save_path:
        plt.savefig(save_path, bbox_inches='tight')
        print(f"Plot saved to {save_path}")
    
    plt.show()
