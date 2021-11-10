extends PopupDialog

onready var progress_bar = $ProgressBar

func setup_progress(max_value: float) -> void:
	progress_bar.value = 0.0
	progress_bar.max_value = max_value

func update_progress(value: float) -> void:
	progress_bar.value = value
