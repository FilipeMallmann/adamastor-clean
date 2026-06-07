## MoraleDeckManager — Gere o deck, o discard pile e a moral da tripulação.
## A moral é representada pelo número de cartas no deck.
## Funde DeckManager + MoraleSystem da referência num único serviço.
extends Node

class_name MoraleDeckManager

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal card_drawn(card: CardData)
signal deck_empty()
signal deck_size_changed(new_size: int)
signal discard_pile_size_changed(new_size: int)
signal morale_changed(new_value: int)
signal morale_depleted()

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var _deck: Array = []         # Array[CardData] — topo = índice 0
var _discard_pile: Array = [] # Array[CardData] — topo = último índice

const CARDS_DB_PATH = "res://cards_db/player_cards.json"

# ---------------------------------------------------------------------------
# Inicialização
# ---------------------------------------------------------------------------

## Inicializa o deck com as 40 Player Cards, baralhadas.
func initialize() -> void:
	_deck.clear()
	_discard_pile.clear()
	_load_and_shuffle_cards()


func _load_and_shuffle_cards() -> void:
	var file = FileAccess.open(CARDS_DB_PATH, FileAccess.READ)
	if not file:
		push_error("MoraleDeckManager: Não foi possível abrir %s" % CARDS_DB_PATH)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("MoraleDeckManager: Erro ao parsear JSON: %s" % json.get_error_message())
		return

	var data = json.get_data()
	var cards_array = data.get("cards", [])

	for card_dict in cards_array:
		var card = CardData.from_dict(card_dict)
		_deck.append(card)

	_deck.shuffle()
	deck_size_changed.emit(_deck.size())
	morale_changed.emit(_deck.size())


# ---------------------------------------------------------------------------
# Operações de deck
# ---------------------------------------------------------------------------

## Comprar a carta do topo do deck.
func draw_top() -> CardData:
	if _deck.is_empty():
		deck_empty.emit()
		morale_depleted.emit()
		return null

	var card: CardData = _deck.pop_front()
	deck_size_changed.emit(_deck.size())
	card_drawn.emit(card)
	morale_changed.emit(_deck.size())
	return card


## Colocar uma carta no discard pile.
func discard(card: CardData) -> void:
	if card == null:
		return
	_discard_pile.append(card)
	discard_pile_size_changed.emit(_discard_pile.size())


# ---------------------------------------------------------------------------
# Operações de moral
# ---------------------------------------------------------------------------

## Perder X pontos de moral: descarta X cartas do topo do deck.
func lose_morale(amount: int) -> int:
	var discarded = 0
	for i in amount:
		if _deck.is_empty():
			deck_empty.emit()
			morale_depleted.emit()
			break
		var card = _deck.pop_front()
		_discard_pile.append(card)
		discarded += 1
	deck_size_changed.emit(_deck.size())
	discard_pile_size_changed.emit(_discard_pile.size())
	morale_changed.emit(_deck.size())
	if _deck.is_empty():
		morale_depleted.emit()
	return discarded


## Ganhar X pontos de moral: move X cartas do topo do discard pile para o fundo do deck.
func gain_morale(amount: int) -> int:
	var recovered = 0
	for i in amount:
		if _discard_pile.is_empty():
			break
		var card = _discard_pile.pop_back()
		_deck.append(card)
		recovered += 1
	deck_size_changed.emit(_deck.size())
	discard_pile_size_changed.emit(_discard_pile.size())
	morale_changed.emit(_deck.size())
	return recovered


# ---------------------------------------------------------------------------
# Getters
# ---------------------------------------------------------------------------

func get_deck_size() -> int:
	return _deck.size()

func get_discard_size() -> int:
	return _discard_pile.size()

func is_deck_empty() -> bool:
	return _deck.is_empty()

func peek_top() -> CardData:
	if _deck.is_empty():
		return null
	return _deck[0]

## Variante Less Luck: carta à direita do deck usada no Sunrise.
func peek_right_side_card() -> CardData:
	if _deck.is_empty():
		return null
	return _deck.back()

func draw_right_side_card() -> CardData:
	if _deck.is_empty():
		deck_empty.emit()
		return null
	var card = _deck.pop_back()
	deck_size_changed.emit(_deck.size())
	card_drawn.emit(card)
	return card
