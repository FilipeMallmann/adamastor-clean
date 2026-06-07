## CardData — Resource que representa uma Player Card do Adamastor.
## Carregar a partir do JSON em cards_db/player_cards.json.
extends Resource

class_name CardData

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum WeatherIcon {
	SUN,         # ☀ — contribui para tempo bom
	CLOUD,       # ☁ — nuvem normal
	BLACK_CLOUD, # ⛈ — nuvem negra (contribui para tempestade)
}

enum ThreatIcon {
	NONE,
	UNREST,   # 🔥 — descontentamento da tripulação
	DISEASE,  # 💀 — doença
	FATIGUE,  # 💧 — fadiga
}

enum SkillType {
	NONE,
	LAND_BONUS_PLUS_1_CARD,       # +1 carta ao entrar em ilha
	NAVIGATION_PLUS_1,            # +1 ponto de navegação por acção Navigate
	DRAW_ACTION_DRAW2_KEEP1,      # Acção Draw: comprar 2, guardar 1
	IGNORE_1_BLACK_CLOUD,         # Tratar 1 nuvem negra como normal
	IGNORE_1_FATIGUE_IN_PLAY,     # Ignorar 1 ícone fatigue em jogo
	IGNORE_1_DISEASE_IN_PLAY,     # Ignorar 1 ícone disease em jogo
	IGNORE_1_UNREST_IN_PLAY,      # Ignorar 1 ícone unrest em jogo
	IGNORE_1_ANY_IN_PLAY,         # Ignorar 1 ícone (qualquer) em jogo
	PLUS_1_ACTION,                # +1 acção por ronda
	EACH_SKILL_MINUS_1_COST,      # Learn a Skill precisa 1 menos motivation
}

enum LandBonusType {
	NONE,
	DESOLATED,            # Nada acontece
	FRESH_FOOD,           # +3 Moral
	BEAUTIFUL_LANDSCAPES, # +2 Moral
	SAND_BEACHES,         # +1 Moral
	MOUNTAIN_PEAK,        # Revelar todas as Map Cards viradas para baixo
	FRESH_WATER,          # Remover 1 trauma de disease
	FRIENDLY_NATIVES,     # Remover 1 trauma de unrest
	DAY_OFF,              # Remover 1 trauma de fatigue
	BEACH_CAMP,           # Remover 1 trauma (à escolha)
	NATIVE_GUIDE,         # Comprar X cartas
}

# ---------------------------------------------------------------------------
# Propriedades exportadas
# ---------------------------------------------------------------------------

@export var id: int = 0
@export var title: String = ""

@export var weather_icon: WeatherIcon = WeatherIcon.CLOUD
@export var threat_icon: ThreatIcon = ThreatIcon.NONE
@export var has_motivation_icon: bool = false

@export var nav_value: int = 1

@export var has_trauma: bool = false
@export var trauma_type: ThreatIcon = ThreatIcon.NONE

@export var has_skill: bool = false
@export var skill_type: SkillType = SkillType.NONE
@export var skill_cost: int = 0

@export var land_bonus_type: LandBonusType = LandBonusType.NONE
@export var land_bonus_morale: int = 0
@export var land_bonus_draw_cards: int = 0
@export var land_bonus_remove_trauma: ThreatIcon = ThreatIcon.NONE
@export var land_bonus_description: String = ""

# ---------------------------------------------------------------------------
# Factory — criar CardData a partir de um Dictionary (do JSON)
# ---------------------------------------------------------------------------

static func from_dict(data: Dictionary) -> CardData:
	var card = CardData.new()
	card.id = data.get("id", 0)
	card.title = data.get("title", "")
	card.nav_value = data.get("nav_value", 1)
	card.has_motivation_icon = data.get("motivation_icon", false)
	card.has_trauma = data.get("has_trauma", false)
	card.has_skill = data.get("has_skill", false)
	card.skill_cost = data.get("skill_cost", 0)

	# Weather icon
	var wi_str: String = data.get("weather_icon", "cloud")
	match wi_str:
		"sun": card.weather_icon = WeatherIcon.SUN
		"black_cloud": card.weather_icon = WeatherIcon.BLACK_CLOUD
		_: card.weather_icon = WeatherIcon.CLOUD

	# Threat icon
	var ti_str: String = data.get("threat_icon", "")
	match ti_str:
		"unrest": card.threat_icon = ThreatIcon.UNREST
		"disease": card.threat_icon = ThreatIcon.DISEASE
		"fatigue": card.threat_icon = ThreatIcon.FATIGUE
		_: card.threat_icon = ThreatIcon.NONE

	# Trauma type
	var trauma_str: String = str(data.get("trauma_type", "")) if data.get("trauma_type") != null else ""
	match trauma_str:
		"unrest": card.trauma_type = ThreatIcon.UNREST
		"disease": card.trauma_type = ThreatIcon.DISEASE
		"fatigue": card.trauma_type = ThreatIcon.FATIGUE
		_: card.trauma_type = ThreatIcon.NONE

	# Skill type
	var skill_str: String = str(data.get("skill_type", "")) if data.get("skill_type") != null else ""
	match skill_str:
		"land_bonus_plus_1_card": card.skill_type = SkillType.LAND_BONUS_PLUS_1_CARD
		"navigation_plus_1": card.skill_type = SkillType.NAVIGATION_PLUS_1
		"draw_action_draw2_keep1": card.skill_type = SkillType.DRAW_ACTION_DRAW2_KEEP1
		"ignore_1_black_cloud": card.skill_type = SkillType.IGNORE_1_BLACK_CLOUD
		"ignore_1_fatigue_in_play": card.skill_type = SkillType.IGNORE_1_FATIGUE_IN_PLAY
		"ignore_1_disease_in_play": card.skill_type = SkillType.IGNORE_1_DISEASE_IN_PLAY
		"ignore_1_unrest_in_play": card.skill_type = SkillType.IGNORE_1_UNREST_IN_PLAY
		"ignore_1_any_in_play": card.skill_type = SkillType.IGNORE_1_ANY_IN_PLAY
		"plus_1_action": card.skill_type = SkillType.PLUS_1_ACTION
		"each_skill_minus_1_cost": card.skill_type = SkillType.EACH_SKILL_MINUS_1_COST
		_: card.skill_type = SkillType.NONE

	# Land bonus
	var lb = data.get("land_bonus", {})
	var lb_type_str: String = lb.get("type", "none")
	match lb_type_str:
		"desolated": card.land_bonus_type = LandBonusType.DESOLATED
		"fresh_food":
			card.land_bonus_type = LandBonusType.FRESH_FOOD
			card.land_bonus_morale = lb.get("morale_gain", 0)
		"beautiful_landscapes":
			card.land_bonus_type = LandBonusType.BEAUTIFUL_LANDSCAPES
			card.land_bonus_morale = lb.get("morale_gain", 0)
		"sand_beaches":
			card.land_bonus_type = LandBonusType.SAND_BEACHES
			card.land_bonus_morale = lb.get("morale_gain", 0)
		"mountain_peak": card.land_bonus_type = LandBonusType.MOUNTAIN_PEAK
		"fresh_water":
			card.land_bonus_type = LandBonusType.FRESH_WATER
			card.land_bonus_remove_trauma = ThreatIcon.DISEASE
		"friendly_natives":
			card.land_bonus_type = LandBonusType.FRIENDLY_NATIVES
			card.land_bonus_remove_trauma = ThreatIcon.UNREST
		"day_off":
			card.land_bonus_type = LandBonusType.DAY_OFF
			card.land_bonus_remove_trauma = ThreatIcon.FATIGUE
		"beach_camp": card.land_bonus_type = LandBonusType.BEACH_CAMP
		"native_guide":
			card.land_bonus_type = LandBonusType.NATIVE_GUIDE
			card.land_bonus_draw_cards = lb.get("draw_cards", 0)
		_: card.land_bonus_type = LandBonusType.NONE

	card.land_bonus_description = lb.get("description", "")
	return card


# ---------------------------------------------------------------------------
# Utilitários
# ---------------------------------------------------------------------------

func is_weather_black_cloud() -> bool:
	return weather_icon == WeatherIcon.BLACK_CLOUD

func is_weather_normal_cloud() -> bool:
	return weather_icon == WeatherIcon.CLOUD

func get_threat_as_string() -> String:
	match threat_icon:
		ThreatIcon.UNREST: return "unrest"
		ThreatIcon.DISEASE: return "disease"
		ThreatIcon.FATIGUE: return "fatigue"
		_: return "none"

func get_trauma_as_string() -> String:
	match trauma_type:
		ThreatIcon.UNREST: return "unrest"
		ThreatIcon.DISEASE: return "disease"
		ThreatIcon.FATIGUE: return "fatigue"
		_: return "none"

func _to_string() -> String:
	return "Card[%d: %s | nav:%d | skill:%s]" % [id, title, nav_value, SkillType.keys()[skill_type]]
