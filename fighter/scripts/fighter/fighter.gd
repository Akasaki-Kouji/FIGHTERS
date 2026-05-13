class_name Fighter
extends CharacterBody2D

@export var character_data: CharacterData
@export var player_id: int = 1
@export var facing: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var input: InputBuffer = $InputBuffer
@onready var state_machine: StateMachine = $StateMachine

# {anim_name: PackedVector2Array of (center_x, feet_y) per frame}
var _anchors: Dictionary = {}
# {anim_name: scale_float}  アニメ毎の表示スケール（キャンバス高さ差を吸収）
var _per_anim_scale: Dictionary = {}

func _ready() -> void:
	if character_data:
		sprite.sprite_frames = character_data.build_sprite_frames()
		_anchors = character_data.compute_anchor_data(sprite.sprite_frames)
		_per_anim_scale = _compute_per_anim_scale()
		var s: float = character_data.display_scale
		sprite.scale = Vector2(s, s)
		sprite.animation_changed.connect(_on_anim_changed)
		sprite.frame_changed.connect(_align_sprite_to_floor)
	input.setup(player_id)
	state_machine.setup(self)
	_apply_facing()
	call_deferred("_on_anim_changed")

func _physics_process(delta: float) -> void:
	input.tick()
	state_machine.physics_update(delta)
	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y > 0.0:
			velocity.y = 0.0
	else:
		velocity.y += character_data.gravity * delta

func play_anim(anim_name: StringName) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing:
		return
	facing = sign(dir)
	_apply_facing()

func _apply_facing() -> void:
	sprite.flip_h = facing < 0

# アニメ毎のキャンバス高さを基に、表示時のキャラ高さが揃うようスケール係数を計算
func _compute_per_anim_scale() -> Dictionary:
	var result: Dictionary = {}
	var sf := sprite.sprite_frames
	if sf == null:
		return result
	var ref_h: float = 0.0
	if sf.has_animation(&"idle") and sf.get_frame_count(&"idle") > 0:
		var t := sf.get_frame_texture(&"idle", 0)
		if t:
			ref_h = float(t.get_height())
	if ref_h <= 0.0:
		for anim in sf.get_animation_names():
			if sf.get_frame_count(anim) <= 0:
				continue
			var t2 := sf.get_frame_texture(anim, 0)
			if t2:
				ref_h = float(t2.get_height())
				break
	if ref_h <= 0.0:
		return result
	var base: float = character_data.display_scale
	for anim in sf.get_animation_names():
		if sf.get_frame_count(anim) <= 0:
			continue
		var t3 := sf.get_frame_texture(anim, 0)
		if t3 == null:
			continue
		var h := float(t3.get_height())
		if h <= 0.0:
			continue
		result[StringName(anim)] = base * (ref_h / h)
	return result

func _on_anim_changed() -> void:
	var anim: StringName = sprite.animation
	if anim != StringName() and _per_anim_scale.has(anim):
		var s: float = _per_anim_scale[anim]
		sprite.scale = Vector2(s, s)
	_align_sprite_to_floor()

# 各フレームのキャラの (足元中心 x, 下端 y) が原点(=床)に来るよう sprite.position を補正
func _align_sprite_to_floor() -> void:
	if sprite.sprite_frames == null:
		return
	var anim: StringName = sprite.animation
	if anim == StringName():
		return
	var anchor_arr: PackedVector2Array = _anchors.get(anim, PackedVector2Array())
	var frame_idx: int = sprite.frame
	if frame_idx < 0 or frame_idx >= anchor_arr.size():
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, frame_idx)
	if tex == null:
		return
	var frame_w: float = float(tex.get_width())
	var frame_h: float = float(tex.get_height())
	var anchor: Vector2 = anchor_arr[frame_idx]
	var s: float = sprite.scale.y
	# centered=true 前提：sprite.position はテクスチャ中心
	# キャラのアンカーピクセル(center_x, feet_y) をワールド原点(0,0)に持ってくる
	sprite.position = Vector2(
		s * (frame_w * 0.5 - anchor.x),
		s * (frame_h * 0.5 - anchor.y)
	)
