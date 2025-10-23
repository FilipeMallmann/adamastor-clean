extends Resource
class_name CardData


@export var name := 'Test'
@export var number := 0
@export var navigation := 0
@export var weather : WeatherManager.WeatherType
@export var traumas : Array[TraumaManager.TraumaType]
@export var permanent_trauma : TraumaManager.TraumaType
@export var skill : Array[String]
@export var island_resource : String
