extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")

onready var hiding_sound := $HidingSound
onready var showing_sound := $ShowingSound
onready var rng := $RandomNumberGenerator

const TANK_DIMENSION = 8388608 # 128
const SCALE_INCREMENT := 8192
const SCALE_FRAME_COUNT := 8
const MOVE_FRAME_COUNT := 30

var game

var detector
var map_rect: Rect2


enum ZapStage {
	NONE,
	HIDING,
	MOVING,
	SHOWING,
}

var zap_stage = ZapStage.NONE
var frame_counter := 0
var destination: SGFixedVector2
var move_increment: SGFixedVector2

func attach_ability() -> void:
	game = tank.game
	map_rect = game.map.get_map_rect()
	detector = game.create_free_space_detector(rng)
	rng.set_seed(game.generate_random_seed())
	tank.hooks.subscribe("gather_input", self, "_hook_tank_gather_input", 10)

func detach_ability() -> void:
	detector.queue_free()
	tank.hooks.unsubscribe("gather_input", self, "_hook_tank_gather_input")

func use_ability() -> void:
	# It *should* be OK to convert from floats here because the values are
	# actually all integers, and floats should have full precision at the
	# sort of values we're using here.
	var area_top_left = SGFixed.from_float_vector2(map_rect.position)
	var area_bottom_right = SGFixed.from_float_vector2(map_rect.position + map_rect.size)
	destination = detector.detect_free_space(area_top_left, area_bottom_right, SGFixed.vector2(TANK_DIMENSION, TANK_DIMENSION))
	
	move_increment = destination.sub(tank.get_global_fixed_position()).div(MOVE_FRAME_COUNT*65536)
	
	tank.collision_shape.disabled = true
	
	if not tank.is_network_master():
		tank.player_info_node.visible = false
	
	hiding_sound.play()
	
	tank.fixed_scale = SGFixed.vector2(65536, 65536)
	_change_stage(ZapStage.HIDING, SCALE_FRAME_COUNT)

func _change_stage(new_stage, frame_count) -> void:
	zap_stage = new_stage
	frame_counter = frame_count

func _save_state() -> Dictionary:
	return {
		zap_stage = zap_stage,
		frame_counter = frame_counter,
	}

func _load_state(state: Dictionary) -> void:
	zap_stage = state['zap_stage']
	frame_counter = state['frame_counter']

func _network_process(delta: float, input: Dictionary) -> void:
	if zap_stage == ZapStage.NONE:
		return
	
	if frame_counter > 0:
		if zap_stage == ZapStage.HIDING:
			if tank.fixed_scale.x > SCALE_INCREMENT and tank.fixed_scale.y > SCALE_INCREMENT:
				tank.fixed_scale.isub(SCALE_INCREMENT)
		elif zap_stage == ZapStage.MOVING:
			tank.fixed_position.iadd(move_increment)
		elif zap_stage == ZapStage.SHOWING:
			if tank.fixed_scale.x < 65536 and tank.fixed_scale.y < 65536:
				tank.fixed_scale.iadd(SCALE_INCREMENT)
			tank.sync_to_physics_engine()
		frame_counter -= 1
	else:
		if zap_stage == ZapStage.HIDING:
			tank.visible = false
			_change_stage(ZapStage.MOVING, MOVE_FRAME_COUNT)
		elif zap_stage == ZapStage.MOVING:
			tank.set_global_fixed_position(destination)
			tank.fixed_scale = SGFixed.vector2(SCALE_INCREMENT, SCALE_INCREMENT)
			tank.visible = true
			tank.player_info_node.visible = true
			tank.collision_shape.disabled = false
			tank.sync_to_physics_engine()
			showing_sound.play()
			_change_stage(ZapStage.SHOWING, SCALE_FRAME_COUNT)
		elif zap_stage == ZapStage.SHOWING:
			tank.fixed_scale = SGFixed.vector2(65536, 65536)
			tank.sync_to_physics_engine()
			_change_stage(ZapStage.NONE, 0)
			mark_finished()

func _hook_tank_gather_input(event: Tank.GatherInputEvent) -> void:
	if zap_stage != ZapStage.NONE:
		event.input.erase(Tank.PlayerInput.INPUT_VECTOR)
		event.input.erase(Tank.PlayerInput.SHOOTING)
		event.input.erase(Tank.PlayerInput.USING_ABILITY)
