## SunriseState — Compra carta para Adventure Row, calcula meteorologia, define acções.
extends State

func enter() -> void:
	if GameStateManager.game_over_pending:
		transition_to(GameStateManager.GameState.GameOver)
		return
	if GameStateManager.game_won_pending:
		transition_to(GameStateManager.GameState.GameWon)
		return

	var deck = GameStateManager.morale_deck_service
	var queue = GameStateManager.queue_service
	var weather = GameStateManager.weather_service
	var nav = GameStateManager.navigation_service

	# Na primeira ronda não se compra carta
	if not GameStateManager.is_first_round:
		var new_card = deck.draw_top()
		if new_card:
			queue.add_card(new_card)
	else:
		GameStateManager.is_first_round = false

	# Calcular meteorologia com base na Adventure Row + nuvens negras no espaço actual
	var calculated = weather.calculate_weather(queue.queue,
		nav.get_current_space_black_clouds())

	# Determinar número de acções e modificador de navegação
	GameStateManager.actions_remaining = weather.get_actions_for_weather(calculated)
	nav.set_weather_modifier(weather.get_navigation_cost_modifier(calculated))

	print("[Sunrise] Tempo: %s. Acções: %d." % [
		weather.get_weather_name(calculated), GameStateManager.actions_remaining
	])

	transition_to(GameStateManager.GameState.Action)
