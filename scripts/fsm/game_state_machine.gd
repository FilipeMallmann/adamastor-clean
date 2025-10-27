# res://scripts/fsm/GameStateMachine.gd
extends Node
class_name GameStateMachine

var current_state: State


var states := {}

func _ready() -> void:
	# Instantiate and register all states
	states[GameStateManager.GameState.Setup] = preload("res://scripts/fsm/setup_state.gd").new()
	#states["SunRise"] = preload("res://scripts/fsm/SunRiseState.gd").new()
	#states["Actions"] = preload("res://scripts/fsm/ActionsState.gd").new()
	#states["Event"] = preload("res://scripts/fsm/EventState.gd").new()
	#states["SunDown"] = preload("res://scripts/fsm/SunDownState.gd").new()

	# Assign parent references
	for s in states.values():
		add_child(s)
		s.state_machine = self
		s.visible = false

	change_state(GameStateManager.GameState.Setup)

func change_state(new_state_name: GameStateManager.GameState) -> void:
	if current_state:
		current_state.exit()
		current_state.visible = false

	current_state = states.get(new_state_name)
	if not current_state:
		push_warning("Unknown state: %s" % new_state_name)
		return

	current_state.visible = true
	current_state.enter()
	print("State changed to: ", new_state_name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
