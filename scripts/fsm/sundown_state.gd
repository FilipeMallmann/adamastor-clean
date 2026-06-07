## SundownState — Descarta a carta menor da Adventure Row e limpa a mão até 3.
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
	var trauma = GameStateManager.trauma_service
	var hand = GameStateManager.hand_service

	# Descartar a carta de menor id da Adventure Row
	var lowest = queue.drop_smallest()
	if lowest:
		if lowest.has_trauma:
			trauma.add_trauma(lowest)
		else:
			deck.discard(lowest)
		print("[Sundown] Descartada: %s" % lowest)

	# Descartar da mão até máximo 3
	# Se a mão tem 3 ou menos, avançar directamente
	if hand.get_size() <= 3:
		_finish_sundown()
	# Caso contrário, a UI deve chamar discard_from_hand() até mão <= 3


## Chamado pela UI para descartar uma carta da mão durante o Sundown.
func discard_from_hand(index: int) -> void:
	var card = GameStateManager.hand_service.discard_at(index)
	if card:
		GameStateManager.morale_deck_service.discard(card)
	if GameStateManager.hand_service.get_size() <= 3:
		_finish_sundown()


func _finish_sundown() -> void:
	print("[Sundown] Ronda concluída. Deck: %d cartas." % \
		GameStateManager.morale_deck_service.get_deck_size())
	transition_to(GameStateManager.GameState.Sunrise)
