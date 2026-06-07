## HandManager — Gere a mão do jogador (máximo 3 cartas no final do Sunset).
extends Node

class_name HandManager

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal hand_changed(hand: Array)

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var hand: Array = []  # Array[CardData]
const MAX_HAND_SIZE: int = 3

# ---------------------------------------------------------------------------
# Operações
# ---------------------------------------------------------------------------

func add(card: CardData) -> void:
	if card == null:
		return
	hand.append(card)
	hand_changed.emit(hand)


func discard(card: CardData) -> void:
	hand.erase(card)
	hand_changed.emit(hand)


func discard_at(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		return null
	var card = hand[index]
	hand.remove_at(index)
	hand_changed.emit(hand)
	return card


## Remove cartas da mão até ao máximo, descartando-as para o deck_manager.
## Retorna as cartas descartadas.
func discard_to_limit(deck_manager: MoraleDeckManager) -> Array:
	var discarded: Array = []
	while hand.size() > MAX_HAND_SIZE:
		var card = hand.pop_back()
		deck_manager.discard(card)
		discarded.append(card)
	hand_changed.emit(hand)
	return discarded


func has_card(card: CardData) -> bool:
	return hand.has(card)


## Cartas na mão com skill (elegíveis para Learn a Skill)
func get_skill_cards() -> Array:
	var result: Array = []
	for card in hand:
		if card.has_skill:
			result.append(card)
	return result


## Contagem de ícones de motivation nas cartas da mão
func get_motivation_count() -> int:
	var count = 0
	for card in hand:
		if card.has_motivation_icon:
			count += 1
	return count


func clear() -> void:
	hand.clear()
	hand_changed.emit(hand)


func get_size() -> int:
	return hand.size()
