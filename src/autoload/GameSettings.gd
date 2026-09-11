extends Node

enum ControlScheme {
	MODERN,
	RETRO,
}

enum NetworkRelay {
	AUTO = OnlineMatch.NetworkRelay.AUTO,
	FORCED = OnlineMatch.NetworkRelay.FORCED,
	DISABLED = OnlineMatch.NetworkRelay.DISABLED,
	FALLBACK,
	FORCED_FALLBACK,
}

var art_style := "res://mods/core/art/classic.tres":
	set = set_art_style
var sound_volume := 1.0:
	set = set_sound_volume
var music_volume := 1.0:
	set = set_music_volume
var tank_engine_sounds := true:
	set = set_tank_engine_sounds
var use_full_screen := false:
	set = set_use_full_screen
var use_screenshake := true
var use_network_relay := 0:
	set = set_use_network_relay
var use_detailed_logging := false
var control_scheme: int = ControlScheme.MODERN
var joy_id := 0:
	set = set_joy_id
var joy_name := "":
	set = set_joy_name
var language := "":
	set = set_language

const SETTINGS_KEYS = [
	'art_style',
	'music_volume',
	'sound_volume',
	'tank_engine_sounds',
	'use_full_screen',
	'language',
	'use_screenshake',
	'use_network_relay',
	'use_detailed_logging',
	'control_scheme',
	'joy_name',
]

const SETTINGS_FILENAME = 'user://settings.json'

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	joy_name = Input.get_joy_name(joy_id)
	load_settings()

	if language == '':
		set_language('default')
	elif language == 'default':
		update_language()

func set_art_style(_art_style: String) -> void:
	art_style = _art_style
	Globals.art.load_art_style(art_style)

func set_music_volume(_music_volume: float) -> void:
	music_volume = _music_volume

	var bus_index = AudioServer.get_bus_index("Music (User)")
	if music_volume < 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(music_volume))

func set_sound_volume(_sound_volume: float) -> void:
	sound_volume = _sound_volume

	var bus_index = AudioServer.get_bus_index("Sound (User)")
	if sound_volume < 0.05:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(sound_volume))

func set_tank_engine_sounds(_tank_engine_sounds: bool) -> void:
	tank_engine_sounds = _tank_engine_sounds
	var bus_index = AudioServer.get_bus_index("Tank Engine")
	AudioServer.set_bus_mute(bus_index, !_tank_engine_sounds)

func set_use_full_screen(_use_full_screen: bool) -> void:
	use_full_screen = _use_full_screen
	if use_full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_use_network_relay(_use_network_relay: int) -> void:
	use_network_relay = _use_network_relay
	match use_network_relay:
		NetworkRelay.AUTO, NetworkRelay.FORCED, NetworkRelay.DISABLED:
			OnlineMatch.use_network_relay = use_network_relay
		NetworkRelay.FALLBACK:
			OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.AUTO
		NetworkRelay.FORCED_FALLBACK:
			OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.FORCED

func set_joy_id(_joy_id: int) -> void:
	if joy_id != _joy_id:
		joy_id = _joy_id

		for action in InputMap.get_actions():
			for event in InputMap.action_get_events(action):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					event.device = joy_id

		joy_name = Input.get_joy_name(joy_id)

func set_joy_name(_joy_name: String) -> void:
	if joy_name != _joy_name:
		for jid in Input.get_connected_joypads():
			if Input.get_joy_name(jid) == _joy_name:
				set_joy_id(jid)
				return

		set_joy_id(0)

func set_language(_lang_code: String) -> void:
	if language != _lang_code:
		language = _lang_code
		update_language()

func update_language() -> void:
	var locale = language
	if language == 'default':
		if SteamManager.use_steam:
			var steam_language = SteamManager.Steam.getCurrentGameLanguage()
			match steam_language:
				"english":
					locale = "en"
				"spanish", "latam":
					locale = "es"
				"german":
					locale = "de"
				"polish":
					locale = "pl"
				"ukrainian":
					locale = "uk"
				"russian":
					locale = "ru"
				"japanese":
					locale = "ja"
				"schinese":
					locale = "zh_CN"
				"tchinese":
					locale = "zh_TW"
				_:
					locale = OS.get_locale_language()
		else:
			locale = OS.get_locale_language()

	if TranslationServer.get_locale() != locale:
		TranslationServer.set_locale(locale)
		get_node("/root").propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		set_joy_id(device)
	elif joy_id == device:
		set_joy_id(0)

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_FILENAME):
		var file = FileAccess.open(SETTINGS_FILENAME, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var result = JSON.parse_string(json_text)
			if result is Dictionary:
				if not result.has("control_scheme"):
					result['control_scheme'] = ControlScheme.RETRO

				for k in result:
					if k in SETTINGS_KEYS:
						set(k, result[k])

func save_settings() -> void:
	var settings := {}
	for k in SETTINGS_KEYS:
		settings[k] = get(k)

	var file = FileAccess.open(SETTINGS_FILENAME, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(settings))
		file.close()
