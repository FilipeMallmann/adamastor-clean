## GameStateMachine — Controlador FSM. Regista e transita entre todos os estados do jogo.
extends Node

class_name GameStateMachine

var current_state: State

var states := {}

func _ready() -> void:
	states[GameStateManager.GameState.Setup]   = preload("res://scripts/fsm/setup_state.gd").new()
	states[GameStateManager.GameState.Sunrise] = preload("res://scripts/fsm/sunrise_state.gd").new()
	states[GameStateManager.GameState.Action]  = preload("res://scripts/fsm/action_state.gd").new()
	states[GameStateManager.GameState.Event]   = preload("res://scripts/fsm/event_state.gd").new()
	states[GameStateManager.GameState.Sundown] = preload("res://scripts/fsm/sundown_state.gd").new()
	states[GameStateManager.GameState.GameOver] = preload("res://scripts/fsm/game_over_state.gd").new()
	states[GameStateManager.GameState.GameWon]  = preload("res://scripts/fsm/game_won_state.gd").new()

	for s in states.values():
		add_child(s)
		s.state_machine = self

	change_state(GameStateManager.GameState.Setup)


func change_state(new_state: GameStateManager.GameState) -> void:
	if current_state:
		current_state.exit()

	current_state = states.get(new_state)
	if not current_state:
		push_warning("GameStateMachine: estado desconhecido: %s" % new_state)
		return

	GameStateManager.actual_state = new_state
	current_state.enter()
	print("FSM → %s" % GameStateManager.GameState.keys()[new_state])


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
