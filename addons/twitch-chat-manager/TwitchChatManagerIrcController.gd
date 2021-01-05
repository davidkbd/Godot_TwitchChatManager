extends Node

#
# Este script es quien implementa la integracion con el IRC
# de Twitch
#

signal msg_received(user, message)
signal chan_joined(channel)
signal disconnected
signal connection_dropped
signal not_oauth_token_found
signal login_failed

export(NodePath) var oauth_controller_path : NodePath = "../TwitchChatManagerOauthController"
export(String)   var username = ""
export(String)   var channel = ""

onready var socket : StreamPeerTCP = null

onready var oauth_controller = get_node(oauth_controller_path)

const connection_timeout : int    = 4
const twitch_irc_host    : String = "irc.chat.twitch.tv"
const twitch_irc_port    : int    = 6667

func connect_to_server():
	if oauth_controller.oauth == "":
		emit_signal("not_oauth_token_found")
		return
	socket = StreamPeerTCP.new()
	var error = socket.connect_to_host(twitch_irc_host, twitch_irc_port)
	if error != OK: return error

	var t = OS.get_system_time_secs()
	while socket.get_status() == StreamPeerTCP.STATUS_CONNECTING\
			or socket.get_status() == HTTPClient.STATUS_RESOLVING:
		var diff = abs(OS.get_system_time_secs() - t)
		if diff > connection_timeout:
			emit_signal("disconnected")
			return
		OS.delay_msec(500)
	if socket.get_status() == StreamPeerTCP.STATUS_ERROR: return 9999
	
	_identify(username, oauth_controller.oauth)
	_join(channel)
	set_process(true)
	return OK

func disconnect_from_server():
	if socket:
		socket.disconnect_from_host()
	socket = null
	emit_signal("disconnected")

func _identify(nickname : String, password : String):
	send("PASS " + password)
	send("NICK " + nickname)

func _join(channel : String):
	send("JOIN #" + channel)

func send(text : String):
#	if text.begins_with("PASS"):
#		print("< PASS xxxx")
#	else:
#		print("< ", text)
	socket.put_data((text + "\n").to_ascii())

func send_msg(text : String):
	send("PRIVMSG #" + channel + " :" + text)

func _process(delta : float):
	if !socket: return
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var bytes = socket.get_available_bytes()
		if bytes > 0:
			var buffer : String = socket.get_utf8_string(bytes)
			for line in buffer.split("\n"):
				var msg = line.split(" ")
				if msg.size() < 2: continue
				elif msg[1] == "PRIVMSG":
					var msg_start_pos = msg[0].length() \
							+ msg[1].length() \
							+ msg[2].length() \
							+ 4
					emit_signal("msg_received",
							msg[0].substr(1, msg[0].find("!") - 1),
							line.substr(msg_start_pos,
									line.length() - 1 - msg_start_pos)
									)
				elif msg[1] == "NOTICE":
					if line.find("Login authentication failed") > -1:
						emit_signal("login_failed")
					elif line.find("auth"):
						emit_signal("login_failed")
				elif msg[0] == "PING":
					send("PONG %s" % msg[1])
				elif msg[1] == "JOIN":
					emit_signal("chan_joined", msg[2])
#				else:
#					print("> ", line)
	else:
		emit_signal("connection_dropped")

func _ready():
	set_process(false)

func _exit_tree():
	disconnect_from_server()
