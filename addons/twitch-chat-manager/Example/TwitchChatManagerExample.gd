extends Control

func _on_Connect_pressed():
	$TwitchChatManager.connect_to_server()


func _on_Disconnect_pressed():
	$TwitchChatManager.disconnect_from_server()

func _on_SendText_pressed():
	$TwitchChatManager.send_msg("Hi World!")


func _on_TwitchChatManager_connected():
	print("Connected")


func _on_TwitchChatManager_disconnected():
	print("Disconnected")


func _on_TwitchChatManager_message_received(msg_object):
	if msg_object is TwitchChatManagerMessageFactory.TwitchChatManagerDefaultIrcMessage:
		print("Message Received: ", msg_object)
	else:
		print("Command Received: ", msg_object)
	var label = Label.new()
	label.text = str(msg_object)
	$Incomming.add_child(label)


func _on_TwitchChatManager_oauth_canceled():
	print("Auth OAuth canceled")

