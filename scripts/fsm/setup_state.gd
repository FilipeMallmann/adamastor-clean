extends State

func enter() -> void:
	print("[Setup] Adding 3 cards, positioning ship, drawing 3 cards...")
	_add_cards(3)
	_position_ship()
	_draw_cards(3)
	transition_to(GameStateManager.GameState.Action)

func _add_cards(count: int): print("Added %d cards to queue." % count)
func _position_ship(): print("Ship positioned.")
func _draw_cards(count: int): print("Drew %d cards." % count)
