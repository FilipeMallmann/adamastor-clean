extends State

func enter() -> void:
	print("[SunRise] Adding a card, checking weather...")
	_add_card()
	_check_weather()
	transition_to(GameStateManager.GameState.Action)

func _add_card(): 
	var card = GameStateManager.morale_deck_service.draw_card()
	GameStateManager.queue_service.add_card(card)

func _check_weather(): 
	print("Weather checked.")
