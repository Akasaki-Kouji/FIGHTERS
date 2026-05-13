class_name CharacterData
extends Resource

@export var display_name: String = ""
@export var max_hp: int = 100
@export var walk_f_speed: float = 120.0
@export var walk_b_speed: float = 90.0
@export var jump_power: float = 420.0
@export var gravity: float = 1200.0

# 画面表示スケール（AI 生成スプライトが巨大なため縮小用）
@export var display_scale: float = 1.0

@export_dir var sprite_dir: String = "res://assets/sprites/leon/"
# キー = アニメ名, 値 = { file:String, frames:int, fps:float, loop:bool }
# モード判定:
#   - <sprite_dir>/<anim_name>/00.png が存在すれば per-frame モード
#       → <anim_name>/00.png ... <NN>.png を frames 枚ロード
#   - 存在しなければ sheet モード（"file" 指定の単一 PNG をスライス）
@export var animations: Dictionary = {}

@export var attacks: Dictionary = {}

func build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	for anim_name in animations.keys():
		var cfg: Dictionary = animations[anim_name]
		var key := StringName(anim_name)
		sf.add_animation(key)
		sf.set_animation_loop(key, cfg.get("loop", true))
		sf.set_animation_speed(key, cfg.get("fps", 8.0))
		var count: int = int(cfg.get("frames", 1))
		var per_frame_first: String = sprite_dir.path_join(String(anim_name)).path_join("00.png")
		if FileAccess.file_exists(per_frame_first):
			_load_per_frame(sf, key, count)
		elif cfg.has("file"):
			_load_sheet(sf, key, cfg, count)
		else:
			push_warning("No sprites found for animation: %s" % anim_name)
	return sf

func _load_per_frame(sf: SpriteFrames, key: StringName, count: int) -> void:
	var dir: String = sprite_dir.path_join(String(key))
	for i in count:
		var path: String = dir.path_join("%02d.png" % i)
		var tex: Texture2D = load(path)
		if tex == null:
			push_warning("Per-frame texture not found: %s" % path)
			continue
		sf.add_frame(key, tex)

func _load_sheet(sf: SpriteFrames, key: StringName, cfg: Dictionary, count: int) -> void:
	var tex_path: String = sprite_dir.path_join(cfg["file"])
	var tex: Texture2D = load(tex_path)
	if tex == null:
		push_warning("Sheet texture not found: %s" % tex_path)
		return
	var frame_w: float = float(tex.get_width()) / float(count)
	var frame_h: float = float(tex.get_height())
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0.0, frame_w, frame_h)
		sf.add_frame(key, atlas)

# 各 (anim, frame) について Vector2(center_x, feet_y) を返す（フレーム内座標, top-left=0）
func compute_anchor_data(sf: SpriteFrames) -> Dictionary:
	var result: Dictionary = {}
	for anim_name in sf.get_animation_names():
		var arr := PackedVector2Array()
		var count: int = sf.get_frame_count(anim_name)
		for i in count:
			var tex: Texture2D = sf.get_frame_texture(anim_name, i)
			arr.append(_find_anchor(tex))
		result[StringName(anim_name)] = arr
	return result

# Texture2D / AtlasTexture どちらでも対応
static func _find_anchor(tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2.ZERO
	var frame_w: float = float(tex.get_width())
	var frame_h: float = float(tex.get_height())
	var fallback := Vector2(frame_w * 0.5, frame_h)

	var img: Image = _extract_frame_image(tex)
	if img == null:
		return fallback

	var used: Rect2i = img.get_used_rect()
	if used.size.y <= 0 or used.size.x <= 0:
		return fallback

	var feet_y: float = float(used.position.y + used.size.y)

	# 下端 20% 帯のみで水平中心を割り出す（腕伸ばし攻撃でブレにくい）
	var band_h: int = maxi(1, int(round(used.size.y * 0.2)))
	var band_top: int = used.position.y + used.size.y - band_h
	var band_rect := Rect2i(0, band_top, img.get_width(), band_h)
	band_rect = band_rect.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var center_x: float
	if band_rect.size.x > 0 and band_rect.size.y > 0:
		var band_sub: Image = img.get_region(band_rect)
		if band_sub:
			var band_used: Rect2i = band_sub.get_used_rect()
			if band_used.size.x > 0:
				center_x = float(band_used.position.x) + float(band_used.size.x) * 0.5
			else:
				center_x = float(used.position.x) + float(used.size.x) * 0.5
		else:
			center_x = float(used.position.x) + float(used.size.x) * 0.5
	else:
		center_x = float(used.position.x) + float(used.size.x) * 0.5

	return Vector2(center_x, feet_y)

# AtlasTexture なら region を切り出した sub-image、それ以外は素の Image を返す
static func _extract_frame_image(tex: Texture2D) -> Image:
	if tex is AtlasTexture:
		var atlas := tex as AtlasTexture
		if atlas.atlas == null:
			return null
		var src: Image = atlas.atlas.get_image()
		if src == null:
			return null
		var region_int := Rect2i(
			int(atlas.region.position.x), int(atlas.region.position.y),
			int(atlas.region.size.x), int(atlas.region.size.y)
		)
		region_int = region_int.intersection(Rect2i(0, 0, src.get_width(), src.get_height()))
		if region_int.size.x <= 0 or region_int.size.y <= 0:
			return null
		return src.get_region(region_int)
	return tex.get_image()
