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

func _create_card(card_info : CardData) -> PlayerCard:
	var card = PlayerCard.new()
	card.card_data = card_info
	return card

func load_cards(path) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
				deck.append(_create_card(file_name as CardData))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	shufle()

func get_total_cards() -> int:
	return deck.size()
	
