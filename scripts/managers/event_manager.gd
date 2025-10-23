extends Node
class_name EventManager

enum EventResult { LearnSkill, TiredTripulation, SpreadDescease, Revolt, GameOver, Win }

func check_envents() -> EventResult:
	return EventResult.LearnSkill
