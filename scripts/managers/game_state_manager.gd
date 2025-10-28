extends Node
class_name GameStateManager

enum GameState { Setup, Sunrise, Action, Event, Sundown, GameOver }

var actual_state := GameState.Setup
static var weather_service : WeatherManager
static var trauma_service : TraumaManager
static var event_service : EventManager
static var queue_service : QueueManager
static var morale_deck_service : MoraleDeckManager

func _init() -> void:
	trauma_service = TraumaManager.new()
	weather_service = WeatherManager.new()
	event_service = EventManager.new()
	queue_service = QueueManager.new()
	morale_deck_service = MoraleDeckManager.new()
	
func game_loop() -> void:
	pass

func advance_state() -> void:
	match actual_state:
		GameState.Setup:
			actual_state = GameState.Action
		GameState.Sunrise:
			actual_state = GameState.Action
		GameState.Action:
			actual_state = GameState.Event
		GameState.Event:
			actual_state = GameState.Sundown
		GameState.Sundown:
			actual_state = GameState.Sunrise
