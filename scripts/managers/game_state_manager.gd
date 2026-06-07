## GameStateManager — Service locator e coordenador central do jogo Adamastor.
## Instancia e expõe todos os serviços via static vars (acessíveis como GameStateManager.servico).
## Deve estar na cena principal como Node filho. Os estados FSM acedem aos serviços por aqui.
extends Node

class_name GameStateManager

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum GameState { Setup, Sunrise, Action, Event, Sundown, GameOver, GameWon }
enum Difficulty { Easy, Normal, Hard }
enum GameOverReason { MoraleDepleted, Riot }

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal state_changed(new_state: GameState)
signal game_won()
signal game_over(reason: GameOverReason)
signal actions_updated(remaining: int)

# ---------------------------------------------------------------------------
# Serviços (static vars — acessíveis como GameStateManager.servico)
# ---------------------------------------------------------------------------

static var weather_service: WeatherManager
static var trauma_service: TraumaManager
static var event_service: EventManager
static var queue_service: QueueManager
static var hand_service: HandManager
static var morale_deck_service: MoraleDeckManager
static var navigation_service: NavigationManager

# ---------------------------------------------------------------------------
# Estado de jogo (static — partilhado por todos os estados FSM)
# ---------------------------------------------------------------------------

static var actual_state: GameState = GameState.Setup
static var difficulty: Difficulty = Difficulty.Normal
static var is_historical: bool = false
static var is_first_round: bool = true
static var actions_remaining: int = 0
static var gained_skills: Array = []  # Array[CardData]

static var game_over_pending: bool = false
static var game_over_reason: GameOverReason = GameOverReason.MoraleDepleted
static var game_won_pending: bool = false
static var current_day: int = 1

# ---------------------------------------------------------------------------
# Godot lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	morale_deck_service = MoraleDeckManager.new()
	weather_service = WeatherManager.new()
	event_service = EventManager.new()
	queue_service = QueueManager.new()
	hand_service = HandManager.new()
	trauma_service = TraumaManager.new()
	navigation_service = NavigationManager.new()

	add_child(morale_deck_service)
	add_child(weather_service)
	add_child(event_service)
	add_child(queue_service)
	add_child(hand_service)
	add_child(trauma_service)
	add_child(navigation_service)

	morale_deck_service.morale_depleted.connect(_on_morale_depleted)
	navigation_service.destination_reached.connect(_on_destination_reached)


# ---------------------------------------------------------------------------
# Arranque do jogo
# ---------------------------------------------------------------------------

func start_game(p_difficulty: Difficulty = Difficulty.Normal,
		p_historical: bool = false) -> void:
	difficulty = p_difficulty
	is_historical = p_historical
	is_first_round = true
	game_over_pending = false
	game_won_pending = false
	gained_skills.clear()
	current_day = 1


# ---------------------------------------------------------------------------
# Contagem de ícones em jogo (Adventure Row + Traumas, com modificadores de skill)
# Usa get_threat_as_string() para evitar o bug enum-vs-string da referência.
# ---------------------------------------------------------------------------

static func count_icons_in_play() -> Dictionary:
	var icons = {"unrest": 0, "disease": 0, "fatigue": 0, "motivation": 0}

	if queue_service:
		var queue_counts = queue_service.get_icon_counts()
		for key in queue_counts:
			icons[key] = icons.get(key, 0) + queue_counts[key]

	if trauma_service:
		icons["unrest"] = icons.get("unrest", 0) + trauma_service.count_unrest()
		icons["disease"] = icons.get("disease", 0) + trauma_service.count_disease()
		icons["fatigue"] = icons.get("fatigue", 0) + trauma_service.count_fatigue()

	if event_service:
		icons = event_service.apply_skill_modifiers(icons, gained_skills)

	return icons


# ---------------------------------------------------------------------------
# Bónus de navegação por skills activas
# ---------------------------------------------------------------------------

static func get_navigation_bonus() -> int:
	var bonus = 0
	for skill_card in gained_skills:
		if skill_card.skill_type == CardData.SkillType.NAVIGATION_PLUS_1:
			bonus += 1
	return bonus


# ---------------------------------------------------------------------------
# Fim do jogo
# ---------------------------------------------------------------------------

static func trigger_game_over(reason: GameOverReason) -> void:
	if game_over_pending or game_won_pending:
		return
	game_over_pending = true
	game_over_reason = reason


static func trigger_game_won() -> void:
	if game_over_pending or game_won_pending:
		return
	game_won_pending = true


func _on_morale_depleted() -> void:
	GameStateManager.trigger_game_over(GameOverReason.MoraleDepleted)
	game_over.emit(GameOverReason.MoraleDepleted)


func _on_destination_reached() -> void:
	GameStateManager.trigger_game_won()
	game_won.emit()


# ---------------------------------------------------------------------------
# Avanço de estado (legacy — a FSM usa transition_to() nos estados)
# ---------------------------------------------------------------------------

func advance_state() -> void:
	match actual_state:
		GameState.Setup:    actual_state = GameState.Sunrise
		GameState.Sunrise:  actual_state = GameState.Action
		GameState.Action:   actual_state = GameState.Event
		GameState.Event:    actual_state = GameState.Sundown
		GameState.Sundown:  actual_state = GameState.Sunrise
