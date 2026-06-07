## WeatherManager — Calcula a meteorologia com base na Adventure Row.
## WeatherType é o resultado calculado (6 tipos).
## CardData.WeatherIcon é o ícone impresso em cada carta (SUN/CLOUD/BLACK_CLOUD).
extends Node

class_name WeatherManager

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum WeatherType {
	SUNNY,            # ☀☁⚙ — 3 acções, navegação normal
	CLOUDY,           # ☁☁⚙ — 3 acções, navegação normal
	NO_WIND,          # ⚙⚙⚙ — 3 acções, +1 custo navegação
	TURBULENT_WATERS, # ☁☁☁ — 3 acções, +1 custo navegação
	STORM,            # ⛈⛈  — 2 acções, +1 custo navegação
	BIG_STORM,        # ⛈⛈⛈ — 1 acção,  +1 custo navegação
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal weather_calculated(weather_type: WeatherType)

# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

var current_weather: WeatherType = WeatherType.SUNNY

# ---------------------------------------------------------------------------
# Cálculo principal
# ---------------------------------------------------------------------------

## Calcula a meteorologia para a ronda.
## adventure_row: Array[CardData] com as 3 cartas na Adventure Row
## space_black_clouds: número de nuvens negras no espaço actual do peão
func calculate_weather(adventure_row: Array, space_black_clouds: int) -> WeatherType:
	var black_clouds: int = 0
	var normal_clouds: int = 0
	var suns: int = 0

	for card in adventure_row:
		match card.weather_icon:
			CardData.WeatherIcon.SUN:
				suns += 1
			CardData.WeatherIcon.CLOUD:
				normal_clouds += 1
			CardData.WeatherIcon.BLACK_CLOUD:
				black_clouds += 1

	# Nuvens negras no espaço transformam nuvens normais em negras (nunca sóis)
	var clouds_to_convert = min(space_black_clouds, normal_clouds)
	normal_clouds -= clouds_to_convert
	black_clouds += clouds_to_convert

	var weather: WeatherType

	if black_clouds >= 3:
		weather = WeatherType.BIG_STORM
	elif black_clouds == 2:
		weather = WeatherType.STORM
	elif black_clouds == 0 and normal_clouds == 3:
		weather = WeatherType.TURBULENT_WATERS
	elif suns == 0 and normal_clouds == 0 and black_clouds == 0:
		# Todos os ícones são motivation (⚙) — No Wind
		weather = WeatherType.NO_WIND
	elif suns >= 1:
		weather = WeatherType.SUNNY
	elif normal_clouds >= 2 and suns == 0:
		weather = WeatherType.CLOUDY
	else:
		weather = WeatherType.SUNNY

	current_weather = weather
	weather_calculated.emit(weather)
	return weather


## Número de acções disponíveis para cada tipo de tempo
func get_actions_for_weather(weather: WeatherType) -> int:
	match weather:
		WeatherType.STORM: return 2
		WeatherType.BIG_STORM: return 1
		_: return 3


## Custo extra de navegação por espaço para o tempo actual
func get_navigation_cost_modifier(weather: WeatherType) -> int:
	match weather:
		WeatherType.NO_WIND, WeatherType.TURBULENT_WATERS,\
		WeatherType.STORM, WeatherType.BIG_STORM:
			return 1
		_:
			return 0


func get_current_weather() -> WeatherType:
	return current_weather


func get_weather_name(weather: WeatherType) -> String:
	match weather:
		WeatherType.SUNNY: return "Sunny (3 Actions)"
		WeatherType.CLOUDY: return "Cloudy (3 Actions)"
		WeatherType.NO_WIND: return "No Wind (3 Actions, +1 Nav Cost)"
		WeatherType.TURBULENT_WATERS: return "Turbulent Waters (3 Actions, +1 Nav Cost)"
		WeatherType.STORM: return "Storm (2 Actions, +1 Nav Cost)"
		WeatherType.BIG_STORM: return "Big Storm (1 Action, +1 Nav Cost)"
		_: return "Unknown"
