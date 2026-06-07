## SetupState — Inicializa o jogo e transita imediatamente para Sunrise.
extends State

func enter() -> void:
	if GameStateManager.game_over_pending or GameStateManager.game_won_pending:
		transition_to(GameStateManager.GameState.GameOver)
		return

	var nav = GameStateManager.navigation_service
	var deck = GameStateManager.morale_deck_service
	var queue = GameStateManager.queue_service
	var hand = GameStateManager.hand_service

	# Limpar estado anterior
	queue.clear()
	hand.clear()
	GameStateManager.gained_skills.clear()
	GameStateManager.trauma_service.clear_traumas()

	# Configurar mapa
	nav.setup_map(GameStateManager.difficulty, GameStateManager.is_historical)

	# Baralhar as 40 Player Cards
	deck.initialize()

	# Comprar 3 cartas → Adventure Row
	for i in 3:
		var card = deck.draw_top()
		if card:
			queue.add_card(card)

	# Comprar 3 cartas → mão inicial
	for i in 3:
		var card = deck.draw_top()
		if card:
			hand.add(card)

	GameStateManager.is_first_round = true
	GameStateManager.current_day = 1
	print("[Setup] Mapa configurado. Deck: %d cartas. Adventure Row: %d. Mão: %d." % [
		deck.get_deck_size(), queue.get_size(), hand.get_size()
	])

	transition_to(GameStateManager.GameState.Sunrise)
