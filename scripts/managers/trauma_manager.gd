extends Node
class_name TraumaManager

enum TraumaType {Unrest, Disease, Fatigue, Motivation}

var permanent_traumas : Array[TraumaType]

func check_total_unrest() -> int:
	return 0
func check_total_disease() -> int:
	return 0
func check_total_fatigue() -> int:
	return 0
func check_total_motivation() -> int:
	return 0
