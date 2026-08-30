class_name FishData
extends RefCounted

var name: String
var value: int
var sequence_length: int
var input_time_window: float
var body_color: Color
var fin_color: Color
var scale_factor: Vector2
var tail_length: float

func _init(
	p_name: String, 
	p_val: int, 
	p_seq: int, 
	p_time: float, 
	p_body: Color = Color.ORANGE, 
	p_fin: Color = Color.YELLOW, 
	p_scale: Vector2 = Vector2(1.5, 0.9), 
	p_tail: float = 18.0
) -> void:
	name = p_name
	value = p_val
	sequence_length = p_seq
	input_time_window = p_time
	body_color = p_body
	fin_color = p_fin
	scale_factor = p_scale
	tail_length = p_tail
