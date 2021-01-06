extends Node

#
# Este script pertenece a la escena con el mismo nombre. Es la clase
# que orquesta la integracion con el IRC y la autenticacion OAUTH.
#

signal connected
signal channel_not_found
signal disconnected
signal message_received
signal oauth_canceled

export(int)    var max_connection_retries : int = 3
export(String) var username : String = ""
export(String) var channel  : String = ""

onready var irc_message_factory  = $TwitchChatManagerMessageFactory
onready var irc_controller       = $TwitchChatManagerIrcController
onready var oauth_controller     = $TwitchChatManagerOauthController

onready var connection_retries : int = 0

func connect_to_server():
	irc_controller.username = username
	irc_controller.channel = channel
	irc_controller.connect_to_server()

func disconnect_from_server():
	irc_controller.disconnect_from_server()

func send_msg(text : String):
	irc_controller.send_msg(text)

func _on_TwitchChatManagerIrcController_chan_joined(channel):
	emit_signal("connected")
	connection_retries = 0

func _on_TwitchChatManagerIrcController_chan_not_found():
	emit_signal("channel_not_found")

func _on_TwitchChatManagerIrcController_disconnected():
	emit_signal("disconnected")

func _on_TwitchChatManagerIrcController_connection_dropped():
	connection_retries += 1
	if connection_retries > max_connection_retries:
		emit_signal("disconnected")
	else:
		yield(get_tree().create_timer(1.0), "timeout")
		irc_controller.connect_to_server()

func _on_TwitchChatManagerIrcController_msg_received(user, message):
	emit_signal("message_received", irc_message_factory.create(user, message))

func _on_TwitchChatManagerIrcController_login_failed():
	irc_controller.disconnect_from_server()
	oauth_controller.start()
	oauth_controller.open_url()

func _on_TwitchChatManagerIrcController_not_oauth_token_found():
	oauth_controller.start()
	oauth_controller.open_url()

func _on_TwitchChatManagerOauthController_token_captured():
	irc_controller.connect_to_server()

func _on_TwitchChatManagerOauthController_canceled():
	emit_signal("oauth_canceled")
