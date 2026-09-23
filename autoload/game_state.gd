extends Node
## Run state outlives rooms. This prototype deliberately has no disk saves.
signal changed
signal message_requested(text: String)
var has_key: bool = false
var door_unlocked: bool = false
var victory: bool = false
var room_index: int = 0

func collect_key() -> void:
	if has_key:
		return
	has_key = true
	changed.emit()
	message_requested.emit("EMBER KEY FOUND  /  The sealed gate will now open.")

func try_unlock_door() -> bool:
	if not has_key and not door_unlocked:
		message_requested.emit("SEALED  /  Find the ember key in the Lantern Well.")
		return false
	door_unlocked = true
	changed.emit()
	return true

func reset_run() -> void:
	has_key = false
	door_unlocked = false
	victory = false
	room_index = 0
	changed.emit()
