extends Node
class_name MoraleDeckManager

signal deck_empty

var deck : Array[PlayerCard]

func shufle() -> void:
	deck.shuffle()

func draw_card() -> PlayerCard:
	var card = deck.pop_front()
	if card == null:
		deck_empty.emit()
	return card
	
func put_at_botton(card: PlayerCard) -> void:
	deck.push_back(card)

func put_at_top(card :PlayerCard) -> void:
	deck.push_front(card)

func load_cards():
	pass

func get_total_cards() -> int:
	return deck.size()
	
