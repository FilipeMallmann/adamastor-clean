extends Node
class_name QueueManager

var queue : Array[PlayerCard]

func sort_queue():
	pass
func drop_smallest():
	pass
func get_total_trauma():
	pass
func get_weather():
	pass
func swap_card():
	print("card swapped between queue and hand")
	
	pass
func add_card(card:PlayerCard) -> void:
	queue.append(card)
	sort_queue()
	print("card added in queue")
