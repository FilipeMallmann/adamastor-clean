extends Node
class_name NavigationManager

signal reach_destination
enum NavigationHexagonType { Clear, Fog, Island, AgainstTide, OnTide, FinalDestination}

func navigate() -> void:
	pass

func calculate_navigation_cost(terrain: NavigationHexagonType) -> int:
	return 0
