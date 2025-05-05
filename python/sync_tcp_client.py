import asyncio
from async_tcp_client import AsyncTCPClient
#from packet import Packet  # Ensure this matches the format Godot expects
from packet_serializer import PacketSerializer

import time


class SyncTCPClient:
    """Synchronous wrapper for AsyncTCPClient, making it SB3- and gymnasium-compatible."""

    def __init__(self):
        self.client = AsyncTCPClient()
        self.loop = asyncio.get_event_loop()
        self.step_time = 0
        self.step_counter = 0

        # Connect to Godot
        self.loop.run_until_complete(self.client.connect())
        

    def reset(self):
        """Sends a reset command to Godot and gets the new initial observation."""
        reset_packet = PacketSerializer.serialize_reset_command()#Packet("reset")  # Reset the game state in Godot
        self.observation = self.loop.run_until_complete(
            self.client.send_packet_and_receive_response(reset_packet)
        )

        if self.observation is None:
            raise ConnectionError("Failed to receive initial observation after reset.")

        return self.observation



    def step(self, action):
        """
        Sends an action to Godot and receives the next observation.
        :param action: Tuple (jump, move_right) as integers (0 or 1)
        :return: (observation, reward, done, info)
        """
        act_packet = PacketSerializer.serialize_step_command(action)
        #action_packet = Packet("action", action[0], action[1])  # Convert to packet
        print()
        print(act_packet)
        #print(action_packet)
        print()
        t1 = time.time_ns()
        self.observation = self.loop.run_until_complete(
            self.client.send_packet_and_receive_response(act_packet)
        )
        t2 = time.time_ns()
        
        self.step_time += (t2-t1)/1000000
        self.step_counter += 1
        
        if self.step_counter % 1000 == 0:
            if t2-t1 > 0.000000001:
                print(f"training speed: {133.3333/((t2-t1) / 1000000)}")
        

        if self.observation is None:
            raise ConnectionError("Lost connection to Godot.")

        return self.observation
    
    
   # def setup(self, render_mode):
    #    setup_packet = Packet("setup", render_mode)
    #    response = self.loop.run_until_complete(
    #        self.client.send_packet_and_receive_response(setup_packet)
    #    )
        
    #    return response
    
    def close(self):
        """Closes the connection."""
        self.loop.run_until_complete(self.client.close_connection())
        print("Connection closed")


    def print_avg_step_time(self):
        print(f"Average time per environment step: {self.step_time / self.step_counter} ms")


    def _handle_exit(self, signum, frame):
        print("Received termination signal. Closing connection...")
        self.close()
        exit(0)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

