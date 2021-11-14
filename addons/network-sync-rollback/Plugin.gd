tool
extends EditorPlugin

const LogInspector = preload("res://addons/network-sync-rollback/log_inspector/LogInspector.tscn")

var log_inspector

func _enter_tree() -> void:
	add_custom_type("NetworkTimer", "Node", preload("res://addons/network-sync-rollback/NetworkTimer.gd"), null)
	add_custom_type("NetworkAnimationPlayer", "AnimationPlayer", preload("res://addons/network-sync-rollback/NetworkAnimationPlayer.gd"), null)
	add_autoload_singleton("SyncManager", "res://addons/network-sync-rollback/SyncManager.gd")
	
	log_inspector = LogInspector.instance()
	get_editor_interface().get_base_control().add_child(log_inspector)
	add_tool_menu_item("Log inspector...", self, "open_log_inspector")

func open_log_inspector(ud) -> void:
	log_inspector.popup_centered_ratio()

func _exit_tree() -> void:
	remove_custom_type("NetworkTimer")
	remove_custom_type("NetworkAnimationPlayer")
	remove_autoload_singleton("SyncManager")
	
	remove_tool_menu_item("Log inspector...")
	if log_inspector:
		log_inspector.free()
		log_inspector = null
