import json
import enum

# Code adapted from:
#   https://github.com/tristanbatchler/official-godot-python-mmo/blob/main/server/packet.py

class Action(enum.Enum):
    pass

class Packet:
    """
    Defines the packet structure for packets sent to Godot over TCP.
    Offers methods to encode and decode packets.
    """
    def __init__(self, action: str, *payloads):
        self.action: str = action
        self.payloads: tuple = payloads
    
        """ Example:
        {
            'a' : "train",
            "p1" : 123123,
            "p2" : 123.233
        }
        """
    def __str__(self) -> str:
        serialize_dict = {'a': self.action}
        for i in range(len(self.payloads)):
            serialize_dict[f'p{i}'] = self.payloads[i]
        data = json.dumps(serialize_dict, separators=(',', ':'))
        return data
    
    def __bytes__(self) -> bytes:
        return str(self).encode('utf-8')
    
    
def from_json(json_str: str) -> Packet:
    """Converts packet data from JSON string into a Packet instance.

    Args:
        json_str (str)

    Returns:
        Packet: Packet instance from provided json string
    """
    obj_dict = json.loads(json_str)
    
    action = None
    payloads = []
    
    for key, value in obj_dict.items():
        if key == 'a':
            action = value
        elif key[0] == 'p':
            index = int(key[1:])
            payloads.insert(index, value)
    
    
    class_name = action + "Packet"
    try:
        constructor: type = globals()[class_name]
        return constructor(*payloads)
    except KeyError as e:
        print(
            f"{class_name} is not a valid packet name. Stack trace: {e}")
    except TypeError:
        print(
            f"{class_name} can't handle arguments {tuple(payloads)}.")
    