extends State

var actions_left := 4

func enter() -> void:
	print("[Actions] Begin player actions.")
	actions_left = 4

func update(delta: float) -> void:
	if actions_left > 0:
		_perform_action()
	else:
		transition_to(GameStateManager.GameState.Event)

func _perform_action() -> void:
	var possible_actions = ["draw", "swap", "navigate"]
	var choice = possible_actions.pick_random()
	match choice:
		"draw": _draw()
		"swap": _swap()
		"navigate": _navigate()
	actions_left -= 1
	print("Actions left: %d" % actions_left)

func _draw(): print("Player drew a card (cost 1 action).")
func _swap(): print("Player swapped cards (cost 1 action).")
func _navigate(): print("Player navigated (cost 1-4 actions).")
