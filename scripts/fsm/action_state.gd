## ActionState — Fase de acções do jogador. Aguarda input via métodos públicos.
## A UI chama perform_draw(), perform_swap() ou perform_navigate().
## Quando sem acções restantes, transita para Event.
extends State

func enter() -> void:
	if GameStateManager.game_over_pending:
		transition_to(GameStateManager.GameState.GameOver)
		return
	if GameStateManager.game_won_pending:
		transition_to(GameStateManager.GameState.GameWon)
		return

	print("[Action] Fase de acções. Acções restantes: %d." % GameStateManager.actions_remaining)

	# Se não há acções disponíveis (BIG_STORM), avançar directamente
	if GameStateManager.actions_remaining <= 0:
		transition_to(GameStateManager.GameState.Event)


# ---------------------------------------------------------------------------
# Acção A: Comprar 1 carta para a mão
# ---------------------------------------------------------------------------

func perform_draw() -> bool:
	if not _can_act():
		return false
	var card = GameStateManager.morale_deck_service.draw_top()
	if card:
		GameStateManager.hand_service.add(card)
	_consume_action()
	return true


# ---------------------------------------------------------------------------
# Acção B: Trocar carta da mão com carta da Adventure Row
# ---------------------------------------------------------------------------

func perform_swap(hand_index: int, queue_index: int) -> bool:
	if not _can_act():
		return false
	var hand = GameStateManager.hand_service.hand
	if hand_index < 0 or hand_index >= hand.size():
		return false
	var hand_card = hand[hand_index]
	var returned = GameStateManager.queue_service.swap_card(queue_index, hand_card)
	if returned == null:
		return false
	hand[hand_index] = returned
	_consume_action()
	return true


# ---------------------------------------------------------------------------
# Acção C: Navegar — descartar cartas da mão e somar nav_value
# card_indices: índices das cartas da mão a descartar
# target_spaces: lista de IDs de espaços a alcançar
# ---------------------------------------------------------------------------

func perform_navigate(card_indices: Array, target_spaces: Array) -> bool:
	if not _can_act():
		return false

	var hand = GameStateManager.hand_service.hand
	var nav = GameStateManager.navigation_service
	var deck = GameStateManager.morale_deck_service

	var nav_total: int = 0
	var cards_to_discard: Array = []
	for idx in card_indices:
		if idx >= 0 and idx < hand.size():
			nav_total += hand[idx].nav_value
			cards_to_discard.append(hand[idx])

	nav_total += GameStateManager.get_navigation_bonus()

	var cost = nav.calculate_path_cost(target_spaces)
	if nav_total < cost:
		return false

	for card in cards_to_discard:
		GameStateManager.hand_service.discard(card)
		deck.discard(card)

	var reached = nav.move_to_spaces(target_spaces)
	if reached:
		GameStateManager.trigger_game_won()

	nav.check_land_bonus()
	_consume_action()
	return true


## Termina a fase de acções voluntariamente.
func end_actions() -> void:
	if state_machine and state_machine.current_state == self:
		GameStateManager.actions_remaining = 0
		transition_to(GameStateManager.GameState.Event)


# ---------------------------------------------------------------------------
# Internos
# ---------------------------------------------------------------------------

func _can_act() -> bool:
	return GameStateManager.actions_remaining > 0 and \
		not GameStateManager.game_over_pending and \
		not GameStateManager.game_won_pending


func _consume_action() -> void:
	GameStateManager.actions_remaining -= 1
	print("[Action] Acções restantes: %d" % GameStateManager.actions_remaining)
	if GameStateManager.game_won_pending:
		transition_to(GameStateManager.GameState.GameWon)
	elif GameStateManager.actions_remaining <= 0:
		transition_to(GameStateManager.GameState.Event)
