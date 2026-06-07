## NavigationManager — Gere o mapa, espaços marinhos e movimento do peão.
## Mantém NavigationHexagonType (nome original) para compatibilidade com map_hexagon.tscn.
extends Node

class_name NavigationManager

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

## Tipos de espaço marinho. Nomes originais mantidos para compatibilidade de cena.
enum NavigationHexagonType {
	Clear,           # Espaço vazio — custo 2
	Fog,             # Nevoeiro — custo 3
	Island,          # Ilha — custo 3
	AgainstTide,     # Corrente contra — custo 4
	OnTide,          # Corrente a favor — custo 1
	FinalDestination # Destino final
}

enum MapCardType {
	REGULAR,
	END_DESTINATION,
	HISTORICAL,
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal pawn_moved(space_id: int)
signal land_reached(space_id: int, draw_count: int)
signal destination_reached()
signal map_card_revealed(card_id: int)

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var map_cards: Array = []    # Array[Dictionary]
var pawn_position: int = 0
var _weather_modifier: int = 0

# ---------------------------------------------------------------------------
# Setup do mapa
# ---------------------------------------------------------------------------

func setup_map(difficulty: int, historical: bool) -> void:
	map_cards.clear()
	if historical:
		_setup_historical_map()
	else:
		_setup_custom_map(difficulty)
	pawn_position = _get_starting_space()


func _setup_custom_map(difficulty: int) -> void:
	var regular_count: int
	match difficulty:
		0: regular_count = 2  # EASY
		1: regular_count = 3  # NORMAL
		2: regular_count = 4  # HARD
		_: regular_count = 3
	for i in regular_count:
		map_cards.append(_generate_regular_map_card(i))
	map_cards.append(_generate_end_map_card(regular_count))
	map_cards[0]["is_revealed"] = true


func _setup_historical_map() -> void:
	for i in 3:
		map_cards.append(_generate_historical_map_card(i))
	map_cards[0]["is_revealed"] = true


# ---------------------------------------------------------------------------
# Navegação
# ---------------------------------------------------------------------------

func set_weather_modifier(modifier: int) -> void:
	_weather_modifier = modifier


## Calcula o custo total para uma lista de IDs de espaços a percorrer.
func calculate_path_cost(space_ids: Array) -> int:
	var total = 0
	for space_id in space_ids:
		var space = _get_space_by_id(space_id)
		if space.is_empty():
			continue
		total += _get_space_cost(space) + _weather_modifier
	return total


func _get_space_cost(space: Dictionary) -> int:
	match space.get("type", NavigationHexagonType.Clear):
		NavigationHexagonType.Clear: return 2
		NavigationHexagonType.Island: return 3
		NavigationHexagonType.Fog: return 3
		NavigationHexagonType.OnTide: return 1
		NavigationHexagonType.AgainstTide: return 4
		NavigationHexagonType.FinalDestination: return 2
		_: return 2


## Move o peão pelos espaços indicados. Retorna true se alcançou o destino final.
func move_to_spaces(space_ids: Array) -> bool:
	for space_id in space_ids:
		var space = _get_space_by_id(space_id)
		if space.is_empty():
			continue
		pawn_position = space_id
		pawn_moved.emit(space_id)
		if space.get("is_right_edge", false):
			_reveal_next_map_card()
		if _is_final_destination(space_id):
			destination_reached.emit()
			return true
	return false


## Verifica e processa o Land Bonus ao entrar em espaço com ilha.
func check_land_bonus() -> void:
	var space = _get_space_by_id(pawn_position)
	if space.is_empty():
		return
	if space.get("type") == NavigationHexagonType.Island:
		var draw_count = space.get("land_bonus_draw", 1)
		land_reached.emit(pawn_position, draw_count)


## Número de nuvens negras no espaço actual (para cálculo meteorológico).
func get_current_space_black_clouds() -> int:
	var space = _get_space_by_id(pawn_position)
	if space.is_empty():
		return 0
	return space.get("black_clouds", 0)


# ---------------------------------------------------------------------------
# Gestão de cartas de mapa
# ---------------------------------------------------------------------------

func _reveal_next_map_card() -> void:
	for card in map_cards:
		if not card.get("is_revealed", false):
			card["is_revealed"] = true
			map_card_revealed.emit(card["id"])
			break


func reveal_all_map_cards() -> void:
	for card in map_cards:
		if not card.get("is_revealed", false):
			card["is_revealed"] = true
			map_card_revealed.emit(card["id"])


func _is_final_destination(space_id: int) -> bool:
	var space = _get_space_by_id(space_id)
	if space.is_empty():
		return false
	return space.get("is_final_destination", false)


func _get_starting_space() -> int:
	if map_cards.is_empty():
		return 0
	var first_card = map_cards[0]
	for space in first_card.get("spaces", []):
		if space.get("is_left_edge", false):
			return space.get("id", 0)
	return 0


func _get_space_by_id(space_id: int) -> Dictionary:
	for card in map_cards:
		for space in card.get("spaces", []):
			if space.get("id") == space_id:
				return space
	return {}


# ---------------------------------------------------------------------------
# Geradores de cartas de mapa (placeholder — substituir por carregamento de ficheiro)
# ---------------------------------------------------------------------------

func _generate_regular_map_card(index: int) -> Dictionary:
	return {
		"id": index,
		"type": MapCardType.REGULAR,
		"is_revealed": false,
		"spaces": _generate_spaces_for_card(index * 10, false)
	}


func _generate_end_map_card(index: int) -> Dictionary:
	return {
		"id": index,
		"type": MapCardType.END_DESTINATION,
		"is_revealed": false,
		"spaces": _generate_spaces_for_card(index * 10, true)
	}


func _generate_historical_map_card(index: int) -> Dictionary:
	return {
		"id": 100 + index,
		"type": MapCardType.HISTORICAL,
		"is_revealed": false,
		"spaces": _generate_spaces_for_card((100 + index) * 10, index == 2)
	}


func _generate_spaces_for_card(base_id: int, has_final: bool) -> Array:
	var spaces = []
	var types = [
		NavigationHexagonType.OnTide,
		NavigationHexagonType.Clear,
		NavigationHexagonType.Clear,
		NavigationHexagonType.Fog,
		NavigationHexagonType.Island,
		NavigationHexagonType.AgainstTide
	]
	for i in types.size():
		var space = {
			"id": base_id + i,
			"type": types[i],
			"black_clouds": 0,
			"land_bonus_draw": 0,
			"is_left_edge": i == 0,
			"is_right_edge": i == types.size() - 1,
			"is_final_destination": has_final and i == types.size() - 1,
		}
		if types[i] == NavigationHexagonType.Island:
			space["land_bonus_draw"] = randi_range(1, 3)
		spaces.append(space)
	return spaces
