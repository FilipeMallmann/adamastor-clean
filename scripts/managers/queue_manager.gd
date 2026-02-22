extends Node
class_name QueueManager

var queue : Array[PlayerCard] = []

func sort_queue() -> void:
	queue.sort_custom(func(a: PlayerCard, b: PlayerCard) -> bool:
		if a == null or a.card_data == null:
			return false
		if b == null or b.card_data == null:
			return true
		return a.card_data.number < b.card_data.number
	)

func drop_smallest() -> PlayerCard:
	if queue.is_empty():
		return null
	sort_queue()
	return queue.pop_front()

func get_total_trauma() -> Dictionary:
	var trauma_total := {
		TraumaManager.TraumaType.Unrest: 0,
		TraumaManager.TraumaType.Disease: 0,
		TraumaManager.TraumaType.Fatigue: 0,
		TraumaManager.TraumaType.Motivation: 0,
	}

	for card in queue:
		if card == null or card.card_data == null:
			continue
		for trauma in card.card_data.traumas:
			if trauma_total.has(trauma):
				trauma_total[trauma] += 1

	return trauma_total

func get_weather() -> Array[WeatherManager.WeatherType]:
	var queue_weather : Array[WeatherManager.WeatherType] = []
	for card in queue:
		if card == null or card.card_data == null:
			continue
		queue_weather.append(card.card_data.weather)
	return queue_weather

func swap_card() -> void:
	print("card swapped between queue and hand")

func add_card(card:PlayerCard) -> void:
	queue.append(card)
	sort_queue()
	print("card added in queue")
