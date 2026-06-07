## GameTable — Controlador principal da UI do jogo Adamastor.
## Liga os nós da cena aos sistemas de jogo e processa input do jogador.
extends Control

# ---------------------------------------------------------------------------
# Referências a nós
# ---------------------------------------------------------------------------

@onready var day_label: Label        = $HUD/VBox/DayLabel
@onready var actions_label: Label    = $HUD/VBox/ActionsLabel
@onready var morale_label: Label     = $HUD/VBox/MoraleLabel
@onready var remaining_label: Label  = $HUD/VBox/RemainingLabel
@onready var weather_label: Label    = $HUD/VBox/WeatherLabel
@onready var phase_label: Label      = $HUD/VBox/PhaseLabel
@onready var trauma_label: Label     = $HUD/VBox/TraumaLabel
@onready var skills_label: Label     = $HUD/VBox/SkillsLabel
@onready var position_label: Label   = $HUD/VBox/PositionLabel

@onready var adventure_row: HBoxContainer = $CenterPanel/AdventureRow
@onready var hand_row: HBoxContainer      = $CenterPanel/HandRow

@onready var draw_btn: Button     = $ActionButtons/DrawBtn
@onready var swap_btn: Button     = $ActionButtons/SwapBtn
@onready var navigate_btn: Button = $ActionButtons/NavigateBtn
@onready var end_turn_btn: Button = $ActionButtons/EndTurnBtn

@onready var gsm: GameStateManager    = $GameStateManager
@onready var fsm: GameStateMachine    = $GameStateMachine

# ---------------------------------------------------------------------------
# Estado interno de interacção
# ---------------------------------------------------------------------------

var adventure_slots: Array = []
var hand_slots: Array      = []

var _swap_mode: bool          = false
var _selected_hand_idx: int   = -1
var _navigate_mode: bool      = false
var _navigate_hand_indices: Array = []

# ---------------------------------------------------------------------------
# Godot lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_collect_card_slots()
	_connect_game_signals()
	_wire_buttons()
	_refresh_ui()


func _collect_card_slots() -> void:
	for i in range(3):
		var slot = adventure_row.get_child(i)
		adventure_slots.append(slot)
		slot.gui_input.connect(_on_slot_input.bind("adventure", i))

	for i in range(5):
		var slot = hand_row.get_child(i)
		hand_slots.append(slot)
		slot.gui_input.connect(_on_slot_input.bind("hand", i))


func _connect_game_signals() -> void:
	GameStateManager.queue_service.queue_changed.connect(_on_queue_changed)
	GameStateManager.hand_service.hand_changed.connect(_on_hand_changed)
	GameStateManager.morale_deck_service.morale_changed.connect(_on_morale_changed)
	GameStateManager.morale_deck_service.deck_size_changed.connect(_on_deck_size_changed)
	GameStateManager.event_service.skill_gain_available.connect(_on_skill_gain_available)
	gsm.game_over.connect(_on_game_over)
	gsm.game_won.connect(_on_game_won)
	fsm.state_changed.connect(_on_state_changed)


func _wire_buttons() -> void:
	draw_btn.pressed.connect(_on_draw)
	swap_btn.pressed.connect(_on_swap)
	navigate_btn.pressed.connect(_on_navigate)
	end_turn_btn.pressed.connect(_on_end_turn)
	$MapArea/RestartBtn.pressed.connect(_on_restart)
	$MapArea/MainMenuBtn.pressed.connect(_on_main_menu)

# ---------------------------------------------------------------------------
# Handlers de botões de acção
# ---------------------------------------------------------------------------

func _on_draw() -> void:
	_cancel_modes()
	var action_state = _get_action_state()
	if action_state:
		action_state.perform_draw()
	_refresh_ui()


func _on_swap() -> void:
	if _swap_mode:
		_cancel_modes()
	else:
		_cancel_modes()
		_swap_mode = true
		swap_btn.text = "Cancel Swap"
		_update_slot_highlights()


func _on_navigate() -> void:
	if _navigate_mode:
		if not _navigate_hand_indices.is_empty():
			var action_state = _get_action_state()
			if action_state:
				var hand = GameStateManager.hand_service.hand
				var total_nav = GameStateManager.get_navigation_bonus()
				for idx in _navigate_hand_indices:
					if idx >= 0 and idx < hand.size():
						total_nav += hand[idx].nav_value
				var path = GameStateManager.navigation_service.get_reachable_path(total_nav)
				if not path.is_empty():
					action_state.perform_navigate(_navigate_hand_indices, path)
		_cancel_modes()
		_refresh_ui()
	else:
		_cancel_modes()
		_navigate_mode = true
		navigate_btn.text = "Confirm Nav"
		_update_slot_highlights()


func _on_end_turn() -> void:
	_cancel_modes()
	var state = GameStateManager.actual_state
	if state == GameStateManager.GameState.Action:
		var action_state = _get_action_state()
		if action_state:
			action_state.end_actions()
	elif state == GameStateManager.GameState.Sundown:
		var sundown = _get_current_state()
		if sundown:
			sundown._finish_sundown()
	_refresh_ui()


func _on_restart() -> void:
	_cancel_modes()
	GameStateManager.game_over_pending = false
	GameStateManager.game_won_pending = false
	GameStateManager.gained_skills.clear()
	fsm.change_state(GameStateManager.GameState.Setup)
	_refresh_ui()


func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu_ui.tscn")

# ---------------------------------------------------------------------------
# Input nos slots de cartas
# ---------------------------------------------------------------------------

func _on_slot_input(event: InputEvent, slot_type: String, index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if slot_type == "adventure":
		_on_adventure_slot_clicked(index)
	else:
		_on_hand_slot_clicked(index)


func _on_adventure_slot_clicked(index: int) -> void:
	if _swap_mode and _selected_hand_idx >= 0:
		var action_state = _get_action_state()
		if action_state:
			action_state.perform_swap(_selected_hand_idx, index)
		_cancel_modes()
		_refresh_ui()


func _on_hand_slot_clicked(index: int) -> void:
	if _swap_mode:
		_selected_hand_idx = index
		_update_slot_highlights()
	elif _navigate_mode:
		if index in _navigate_hand_indices:
			_navigate_hand_indices.erase(index)
		else:
			_navigate_hand_indices.append(index)
		_update_slot_highlights()
	elif GameStateManager.actual_state == GameStateManager.GameState.Sundown:
		if GameStateManager.hand_service.get_size() > 3:
			var sundown = _get_current_state()
			if sundown:
				sundown.discard_from_hand(index)
			_refresh_ui()

# ---------------------------------------------------------------------------
# Signal handlers de serviços
# ---------------------------------------------------------------------------

func _on_queue_changed(queue: Array) -> void:
	_update_adventure_row(queue)

func _on_hand_changed(hand: Array) -> void:
	_update_hand(hand)

func _on_morale_changed(new_value: int) -> void:
	morale_label.text = "Morale: %d" % new_value

func _on_deck_size_changed(new_size: int) -> void:
	morale_label.text = "Morale: %d" % new_size

func _on_skill_gain_available(eligible_cards: Array, _motivation_count: int) -> void:
	# Por agora auto-selecciona a primeira carta elegível
	# TODO: mostrar UI de escolha
	if not eligible_cards.is_empty():
		var event_state = _get_current_state()
		if event_state and event_state.has_method("confirm_skill"):
			event_state.confirm_skill(eligible_cards[0])

func _on_game_over(reason: GameStateManager.GameOverReason) -> void:
	_cancel_modes()
	if reason == GameStateManager.GameOverReason.Riot:
		phase_label.text = "GAME OVER — Crew mutinied!"
	else:
		phase_label.text = "GAME OVER — Morale reached 0!"
	_set_buttons_disabled(true)

func _on_game_won() -> void:
	_cancel_modes()
	phase_label.text = "VICTORY! Destination reached!"
	_set_buttons_disabled(true)

func _on_state_changed(_new_state: GameStateManager.GameState) -> void:
	_refresh_ui()

# ---------------------------------------------------------------------------
# Actualização visual
# ---------------------------------------------------------------------------

func _refresh_ui() -> void:
	_update_adventure_row(GameStateManager.queue_service.queue)
	_update_hand(GameStateManager.hand_service.hand)
	day_label.text = "Day %d" % GameStateManager.current_day
	actions_label.text = "Actions: %d" % GameStateManager.actions_remaining
	morale_label.text = "Morale: %d" % GameStateManager.morale_deck_service.get_deck_size()
	remaining_label.text = "Discard: %d" % GameStateManager.morale_deck_service.get_discard_size()
	weather_label.text = "Weather: %s" % _get_weather_text()
	phase_label.text = "Phase: %s" % GameStateManager.GameState.keys()[GameStateManager.actual_state]
	trauma_label.text = "Traumas: %d" % GameStateManager.trauma_service.get_total()
	skills_label.text = "Skills: %d" % GameStateManager.gained_skills.size()
	position_label.text = "Pos: %s" % GameStateManager.navigation_service.get_position_text()
	_update_buttons()
	_update_slot_highlights()


func _get_weather_text() -> String:
	var ws = GameStateManager.weather_service
	if ws:
		return ws.get_weather_name(ws.get_current_weather())
	return "--"


func _update_adventure_row(queue: Array) -> void:
	for i in range(adventure_slots.size()):
		_fill_card_slot(adventure_slots[i], queue[i] if i < queue.size() else null)


func _update_hand(hand: Array) -> void:
	for i in range(hand_slots.size()):
		_fill_card_slot(hand_slots[i], hand[i] if i < hand.size() else null)


func _fill_card_slot(slot: Panel, card: CardData) -> void:
	var vbox = slot.get_child(0)
	var art: TextureRect = vbox.get_node("CardArt")
	var title_lbl: Label  = vbox.get_node("CardTitle")
	var nav_lbl: Label    = vbox.get_node("CardNav")
	if card:
		title_lbl.text = card.title
		nav_lbl.text   = "Nav: %d" % card.nav_value
		art.texture    = _load_card_texture(card.id)
	else:
		title_lbl.text = ""
		nav_lbl.text   = ""
		art.texture    = null


func _load_card_texture(card_id: int) -> Texture2D:
	var path = "res://assets/cards/card_%02d.png" % card_id
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


func _update_buttons() -> void:
	var state     = GameStateManager.actual_state
	var in_action = state == GameStateManager.GameState.Action
	var in_sundown = state == GameStateManager.GameState.Sundown
	draw_btn.disabled     = not in_action
	swap_btn.disabled     = not in_action
	navigate_btn.disabled = not in_action
	end_turn_btn.disabled = not (in_action or in_sundown)


func _set_buttons_disabled(disabled: bool) -> void:
	draw_btn.disabled     = disabled
	swap_btn.disabled     = disabled
	navigate_btn.disabled = disabled
	end_turn_btn.disabled = disabled


func _cancel_modes() -> void:
	_swap_mode    = false
	_selected_hand_idx = -1
	_navigate_mode = false
	_navigate_hand_indices.clear()
	swap_btn.text     = "Swap"
	navigate_btn.text = "Navigate"


func _update_slot_highlights() -> void:
	for i in range(adventure_slots.size()):
		var s: Panel = adventure_slots[i]
		s.modulate = Color(1.3, 1.3, 0.5) if (_swap_mode and _selected_hand_idx >= 0) else Color.WHITE

	for i in range(hand_slots.size()):
		var s: Panel = hand_slots[i]
		if _swap_mode and _selected_hand_idx == i:
			s.modulate = Color(0.5, 1.3, 0.5)
		elif _navigate_mode and i in _navigate_hand_indices:
			s.modulate = Color(0.5, 0.9, 1.3)
		else:
			s.modulate = Color.WHITE

# ---------------------------------------------------------------------------
# Auxiliares FSM
# ---------------------------------------------------------------------------

func _get_action_state():
	if GameStateManager.actual_state != GameStateManager.GameState.Action:
		return null
	return fsm.current_state

func _get_current_state():
	return fsm.current_state
