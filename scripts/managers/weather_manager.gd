extends Node
class_name WeatherManager

enum WeatherType {Sun, Cloud, Storm}

## check the weather and then, return the number of actions
func check_weather_actions() -> int:
	## go to game queue, check the weather
	var game_queue_weather = [WeatherType.Sun, WeatherType.Cloud, WeatherType.Cloud]
	
	var total_storm: int = game_queue_weather.count(WeatherType.Storm)
	if total_storm == 3:
		return 1
	if total_storm == 2:
		return 2 
	return 3

func check_weather_navigation_cost() -> int:
	
	var game_queue_weather = [WeatherType.Sun, WeatherType.Cloud, WeatherType.Cloud]
	
	var total_cloud: int = game_queue_weather.count(WeatherType.Cloud)
	var total_sun: int = game_queue_weather.count(WeatherType.Sun)
	
	if total_sun == 2 or total_cloud == 2:
		return 0
	return 1
