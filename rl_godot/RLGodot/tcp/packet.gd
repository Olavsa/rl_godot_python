extends Object


class_name Packet
## Defines methods for the default packet structure to be sent over TCP.
#var action: String
#var payloads: Array

static func toString(action, payloads) -> String:
	if len(payloads) == 0:
		print("PAYLOAD LENGTH WAS 0")
	var serialize_dict: Dictionary = {"a": action}
	for i in range(len(payloads)):
		serialize_dict["p%d" % (i+1)] = payloads[i]
	var data: String = JSON.stringify(serialize_dict)
	return data
	

static func json_to_action_payloads(json_str: String) -> Dictionary:
	var action: String
	var payloads: Array = []
	var obj_dict: Dictionary = JSON.parse_string(json_str)

	#print(obj_dict)
	return obj_dict
"""	
	for key in obj_dict.keys():
		var value = obj_dict[key]
		if key == "a":
			action = value
		elif key[0] == "p":
			var idx: int = key.split_floats("p", true)[1]
			payloads.insert(idx, value)
		
	return {
		"action": action,
		"payloads": payloads
	}
"""
