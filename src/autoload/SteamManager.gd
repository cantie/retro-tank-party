extends Node

var Steam = null
var use_steam := false
var steam_app_id := 1568570

func _ready() -> void:
	if Engine.has_singleton("Steam"):
		Steam = Engine.get_singleton("Steam")
		use_steam = true
	
	if Globals.arguments.get('disable-steam', false):
		use_steam = false
	
	if use_steam:
		if not _initialize_steam():
			use_steam = false
			set_process(false)
	else:
		set_process(false)

func _initialize_steam() -> bool:
	if Steam == null:
		return false
	
	if Steam.restartAppIfNecessary(steam_app_id):
		get_tree().quit()
		return false

	var init: Dictionary = Steam.steamInit(false)
	if init['status'] != 1:
		push_warning("Steam init failed: " + init['verbal'] + " (%s)" % init['status'])
		return false

	if not Steam.isSubscribed():
		push_warning("User does not own this game on Steam")
		return false

	return true

func _process(_delta: float) -> void:
	if use_steam and Steam != null:
		Steam.run_callbacks()
