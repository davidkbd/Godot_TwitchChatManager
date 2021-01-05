tool
extends Node

#
# Este script y su escena permiten la integracion con la autenticacion OAUTH
#
#

signal token_captured
signal canceled

export(String) var twitch_auth_url = "https://twitchapps.com/tmi/"
export(bool)   var token_persist : bool = true setget set_token_persist, is_token_persist
export(int)    var timeout_seconds : int = 30

var oauth : String
var timer_countdown : int

func set_token_persist(new_value : bool):
	token_persist = new_value
	if $PopupDialog/VBoxContainer/PersistCheckBox:
		$PopupDialog/VBoxContainer/PersistCheckBox.pressed = token_persist

func is_token_persist() -> bool: return token_persist

func start():
	pass

func stop():
	pass

func open_url():
	var prompt = $PopupDialog
	prompt.popup_centered(Vector2(320, 200))

func _on_GetTokenButton_pressed():
	OS.shell_open(twitch_auth_url)
	$PopupDialog/VBoxContainer/GetTokenButton.hide()
	$PopupDialog/VBoxContainer/Token.show()

func _on_Button_pressed():
	$PopupDialog.hide()
	oauth = $PopupDialog/VBoxContainer/Token.text
	_save_oauth()
	emit_signal("token_captured")

func _on_Button2_pressed():
	$PopupDialog.hide()
	emit_signal("canceled")

func _read_last_oauth():
	if token_persist:
		var st = TwitchChatManagerStorage.new("user://OAUTH.token", "xxxx")
		var resp = st.load_text()
		if resp.result == OK:
			oauth = resp.data

func _save_oauth():
	if token_persist:
		var st = TwitchChatManagerStorage.new("user://OAUTH.token", "xxxx")
		st.store_text(oauth)

func _ready():
	_read_last_oauth()
	set_process(false)

#
# THIS CLASS is a minimal version of StorageManager (check AssetLib)
# https://github.com/davidkbd/Godot_StorageManager
#
# You can delete the next lines and replace by that library.
#

class TwitchChatManagerStorage:
	var file_name : String
	var password  : String
	var is_secret : bool

	# new_file_name param is the file to open (absolute path).
	# new_password param is the password for encrypted files (optional).
	func _init(new_file_name : String, new_password : String = ""):
		file_name = new_file_name
		password = new_password
		is_secret = password != ""

	# Loads a text file.
	func load_text() -> Dictionary:
		return _load()

	func store_text(data : String) -> Dictionary:
		return _store(data)

	func _load():
		var f = File.new()
		if not f.file_exists(file_name):
			return _create_error(ERR_FILE_NOT_FOUND, file_name)
		var err = f.open_encrypted_with_pass(file_name, File.READ, password) \
				if is_secret else f.open(file_name, File.READ)
		if err != OK:
			f.close()
			return _create_error(err, file_name)
		var readed = f.get_as_text()
		f.close()
		if readed: return _create_ok(readed)
		return _create_error(ERR_INVALID_DATA, file_name)

	func _store(data) -> Dictionary:
		var f = File.new()
		var err = f.open_encrypted_with_pass(file_name, File.WRITE, password) \
				if is_secret else f.open(file_name, File.WRITE)
		if err != OK:
			f.close()
			return _create_error(err, file_name)
		f.store_string(data)
		f.close()
		return _create_ok(null)

	func _create_ok(data) -> Dictionary:
		if data:
			return { "result": OK, "data": data }
		return { "result": OK }

	func _create_error(err : int, file_name : String) -> Dictionary:
		match err:
			ERR_INVALID_DATA:
				return _create_error_dictionary(err, "ERR_INVALID_DATA", file_name)
			ERR_FILE_ALREADY_IN_USE:
				return _create_error_dictionary(err, "ERR_FILE_ALREADY_IN_USE", file_name)
			ERR_FILE_BAD_DRIVE:
				return _create_error_dictionary(err, "ERR_FILE_BAD_DRIVE", file_name)
			ERR_FILE_BAD_PATH:
				return _create_error_dictionary(err, "ERR_FILE_BAD_PATH", file_name)
			ERR_FILE_CANT_OPEN:
				return _create_error_dictionary(err, "ERR_FILE_CANT_OPEN", file_name)
			ERR_FILE_CANT_READ:
				return _create_error_dictionary(err, "ERR_FILE_CANT_READ", file_name)
			ERR_FILE_CANT_WRITE:
				return _create_error_dictionary(err, "ERR_FILE_CANT_WRITE", file_name)
			ERR_FILE_CORRUPT:
				return _create_error_dictionary(err, "ERR_FILE_CORRUPT", file_name)
			ERR_FILE_EOF:
				return _create_error_dictionary(err, "ERR_FILE_EOF", file_name)
			ERR_FILE_MISSING_DEPENDENCIES:
				return _create_error_dictionary(err, "ERR_FILE_MISSING_DEPENDENCIES", file_name)
			ERR_FILE_NOT_FOUND:
				return _create_error_dictionary(err, "ERR_FILE_NOT_FOUND", file_name)
			ERR_FILE_NO_PERMISSION:
				return _create_error_dictionary(err, "ERR_FILE_NO_PERMISSION", file_name)
			ERR_FILE_UNRECOGNIZED:
				return _create_error_dictionary(err, "ERR_FILE_UNRECOGNIZED", file_name)
		return _create_error_dictionary(err, "FAILED", file_name)

	func _create_error_dictionary(err, err_name : String, file_name : String) -> Dictionary:
		return { "result": err, "error": err_name, "file": file_name }
