extends Node

#
# Este script permite TRANSFORMAR el texto que envian los usuarios a traves
# de IRC, en clases mas utiles para el desarrollador.
#

class_name TwitchChatManagerMessageFactory

class TwitchChatManagerDefaultIrcMessage:
	var user      : String
	var message   : String
	func _to_string():
		return "<" + user + "> " + message

class TwitchChatManagerDefaultIrcCommandMessage:
	var user      : String
	var command   : String
	var arguments : Array
	func _to_string():
		return "<" + user + "> " + "(" + command + ") " + str(arguments)

func create(user : String, text : String) -> TwitchChatManagerDefaultIrcMessage:
	if text.begins_with("!"):
		return _create_command(user, text)
	else:
		return _create_message(user, text)

func _create_command(user : String, text : String):
	var r = TwitchChatManagerDefaultIrcCommandMessage.new()
	var spl = text.split(" ")
	r.user = user
	r.command = spl[0].substr(1)
	r.arguments = spl
	r.arguments.remove(0)
	return r

func _create_message(user : String, text : String):
	var r = TwitchChatManagerDefaultIrcMessage.new()
	r.user = user
	r.message = text
	return r
