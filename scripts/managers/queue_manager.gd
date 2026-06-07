## QueueManager — Gere a Adventure Row (fila de 3 cartas).
## Ordenada por id decrescente: maior à esquerda [0], menor à direita [-1].
extends Node

class_name QueueManager

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal queue_changed(queue: Array)

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var queue: Array = []  # Array[CardData], máximo 3 cartas

# ---------------------------------------------------------------------------
# Operações
# ---------------------------------------------------------------------------

func add_card(card: CardData) -> void:
	if card == null:
		return
	queue.append(card)
	sort_queue()
	queue_changed.emit(queue)


func swap_card(queue_index: int, hand_card: CardData) -> CardData:
	if queue_index < 0 or queue_index >= queue.size():
		return null
	var removed = queue[queue_index]
	queue[queue_index] = hand_card
	sort_queue()
	queue_changed.emit(queue)
	return removed


## Remove e retorna a carta de menor id (rightmost). Retorna null se vazia.
func drop_smallest() -> CardData:
	if queue.is_empty():
		return null
	# Após sort, a última posição tem o menor id
	var card = queue.pop_back()
	queue_changed.emit(queue)
	return card


func get_smallest() -> CardData:
	if queue.is_empty():
		return null
	return queue.back()


## Ordena por id decrescente (maior à esquerda).
func sort_queue() -> void:
	queue.sort_custom(func(a, b): return a.id > b.id)


# ---------------------------------------------------------------------------
# Contagem de ícones em jogo
# ---------------------------------------------------------------------------

## Retorna dicionário com totais de ícones de ameaça e motivation na Adventure Row.
func get_icon_counts() -> Dictionary:
	var counts = {"unrest": 0, "disease": 0, "fatigue": 0, "motivation": 0}
	for card in queue:
		var threat = card.get_threat_as_string()
		if threat != "none":
			counts[threat] = counts.get(threat, 0) + 1
		if card.has_motivation_icon:
			counts["motivation"] = counts.get("motivation", 0) + 1
	return counts


func clear() -> void:
	queue.clear()
	queue_changed.emit(queue)


func get_size() -> int:
	return queue.size()
