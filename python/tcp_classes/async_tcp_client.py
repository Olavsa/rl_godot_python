import asyncio
import json
from packet import Packet
import socket

TIMEOUT = 10  # Timeout for receiving data

class AsyncTCPClient:
    """
    Handles low-level TCP communication with Godot asynchronously.
    """

    def __init__(self, host = "127.0.0.1", port = 8888):
        self.host = host
        self.port = port
        self.reader = None
        self.writer = None

    async def connect(self):
        """Establishes a connection to the Godot server."""
        self.reader, self.writer = await asyncio.open_connection(self.host, self.port)
        print(f"Connected to Godot at {self.host}:{self.port}")
        
        # Disable Nagle's Algorithm
        sock = self.writer.get_extra_info("socket")
        if sock is not None:
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    async def send_packet_and_receive_response(self, packet):
        """
        Sends packet to Godot and returns corouting waiting for the response.
        :param packet: Packet object
        :return: Received response (dict) or None if disconnected
        """
        if self.writer is None:
            raise ConnectionError("No active connection to Godot.")

        # Send packet
        #print(f"to godot: {packet}")
        self.writer.write(packet.__bytes__())
        await self.writer.drain()

        # Receive the response
        return await self.receive_response()

    async def receive_response(self):
        """Receives and decodes tcp response packet from Godot."""
        try:
            # Read the first 4 bytes to get message length
            header = await asyncio.wait_for(self.reader.read(4), timeout=TIMEOUT)
            if not header:
                print("Disconnected from Godot.")
                return None

            message_length = int.from_bytes(header, "little")

            # Read the actual message
            data = await asyncio.wait_for(self.reader.read(message_length), timeout=TIMEOUT)
            if not data:
                print("Disconnected from Godot.")
                return None

            # Decode JSON message
            data_json_str = data.decode("utf-8")
            data_dict = json.loads(data_json_str)
            #print(f"Received {data_dict}")
            
            return data_dict

        except asyncio.TimeoutError:
            print("Timeout: No data received from Godot.")
            return None

    async def close_connection(self):
        """Sends a disconnect command and closes the TCP connection."""
        if self.writer:
            try: 
                disconnect_packet = Packet("disconnect")  # Create a disconnect packet
                self.writer.write(disconnect_packet.__bytes__())
                await self.writer.drain()
                print("Sent disconnect command to Godot.")
            finally:
                # Close connection
                self.writer.close()
                await self.writer.wait_closed()
                print("Connection to Godot closed.")