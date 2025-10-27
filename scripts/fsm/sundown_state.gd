extends State

func enter() -> void:
	print("[SunDown] Discarding smallest card...")
	_discard_smallest()
	transition_to(GameStateManager.GameState.Sunrise)

func _discard_smallest(): print("Smallest card discarded.")
