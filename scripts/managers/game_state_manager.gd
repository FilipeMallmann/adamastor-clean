extends Node
class_name GameStateManager

enum GameState { Setup, Sunrise, Action, Event, Sundown, GameOver }

var actual_state := GameState.Setup
var _weather_service : WeatherManager
var _trauma_service : TraumaManager
var _event_service : EventManager


func _init() -> void:
	_trauma_service = TraumaManager.new()
	_weather_service = WeatherManager.new()
	_event_service = EventManager.new()
	

func game_loop() -> void:
	pass

func advance_state() -> void:
	match actual_state:
		GameState.Setup:
			actual_state = GameState.Sunrise
		GameState.Sunrise:
			actual_state = GameState.Action
		GameState.Action:
			actual_state = GameState.Event
		GameState.Event:
			actual_state = GameState.Sundown
		GameState.Sundown:
			actual_state = GameState.Sunrise
