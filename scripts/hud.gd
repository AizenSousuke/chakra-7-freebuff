class_name Hud
extends Control
## Score, best, level, next piece and star gauge. Drawn directly so the same
## control can be a top bar on phones and a side column on desktop.

const Pal := preload("res://scripts/palette.gd")

const SPECIAL_EVERY := 7

var score := 0
var best := 0
var level := 1
var clears := 0
var special_progress := 0
var special_ready := false
var special_active := false
var next_numbers: Array = [1, 2]
var next_orientation := 0
var next_is_special := false
var landscape := false

var _font: Font
var _preview_styles: Dictionary = {}
var _pip_on: StyleBoxFlat
var _pip_off: StyleBoxFlat


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in Pal.NUMBER_COLORS.size():
		_preview_styles[Pal.NUMBER_COLORS[i]] = _make_style(Pal.NUMBER_COLORS[i], 6)
	_preview_styles[Pal.SPECIAL] = _make_style(Pal.SPECIAL, 6)
	_pip_on = _make_style(Pal.SPECIAL, 5)
	_pip_off = _make_style(Pal.GRID_CELL, 5)


static func _make_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _draw() -> void:
	if _font == null or size.x <= 0.0 or size.y <= 0.0:
		return
	if landscape:
		_draw_column()
	else:
		_draw_bar()


func _draw_bar() -> void:
	var width := size.x
	_text("SCORE", Vector2(0, 13), 11, Pal.DIM)
	_text(str(score), Vector2(0, 42), 27, Pal.TEXT)
	_text("BEST %d  ·  LV %d" % [best, level], Vector2(0, 80), 11, Pal.DIM)

	_text(_gauge_text(), Vector2(width - 150, 80), 11, Pal.SPECIAL if (special_ready or special_active) else Pal.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 150)

	_text("NEXT", Vector2(width - 64, 13), 11, Pal.DIM, HORIZONTAL_ALIGNMENT_RIGHT, 64)
	_draw_preview(Vector2(width - 52, 18), 22.0)


func _draw_column() -> void:
	_text("SCORE", Vector2(0, 18), 14, Pal.DIM)
	_text(str(score), Vector2(0, 60), 40, Pal.TEXT)
	_text("BEST", Vector2(0, 104), 13, Pal.DIM)
	_text(str(best), Vector2(0, 128), 19, Pal.TEXT)
	_text("LEVEL", Vector2(0, 172), 13, Pal.DIM)
	_text(str(level), Vector2(0, 196), 19, Pal.TEXT)
	_text("CLEARS", Vector2(0, 240), 13, Pal.DIM)
	_text(str(clears), Vector2(0, 264), 19, Pal.TEXT)

	_text("NEXT", Vector2(0, 316), 13, Pal.DIM)
	_draw_preview(Vector2(0, 330), 34.0)

	_text("STAR" + _gauge_suffix(), Vector2(0, 452), 13, Pal.SPECIAL if (special_ready or special_active) else Pal.DIM)
	_draw_pips(Vector2(0, 466), 18.0, 26.0)

	var hint_y := size.y - 92.0
	_text("ARROWS   move", Vector2(0, hint_y), 12, Pal.DIM)
	_text("UP / X   rotate", Vector2(0, hint_y + 22), 12, Pal.DIM)
	_text("SPACE    drop", Vector2(0, hint_y + 44), 12, Pal.DIM)
	_text("P        pause", Vector2(0, hint_y + 66), 12, Pal.DIM)


func _gauge_text() -> String:
	if special_active:
		return "STAR ACTIVE"
	if special_ready:
		return "STAR READY"
	return "STAR %d/%d" % [special_progress, SPECIAL_EVERY]


func _gauge_suffix() -> String:
	if special_active:
		return "  ACTIVE"
	if special_ready:
		return "  READY"
	return "  %d/%d" % [special_progress, SPECIAL_EVERY]


func _draw_pips(origin: Vector2, side: float, step: float) -> void:
	for i in SPECIAL_EVERY:
		var style := _pip_on if i < special_progress else _pip_off
		style.draw(get_canvas_item(), Rect2(origin + Vector2(step * i, 0), Vector2(side, side)))


func _draw_preview(corner: Vector2, cell: float) -> void:
	var gap := cell * 0.16
	if next_is_special:
		var rect := Rect2(corner, Vector2(cell, cell))
		_preview_styles[Pal.SPECIAL].draw(get_canvas_item(), rect)
		_star(rect.get_center(), cell * 0.26)
		return
	var facing: Vector2i = Piece.DIRECTIONS[clampi(next_orientation, 0, 3)]
	var shift := Vector2i(maxi(0, -facing.x), maxi(0, -facing.y))
	var slots := [shift, facing + shift]
	var stride := Vector2(cell + gap, cell + gap)
	for i in 2:
		var number := 1
		if i < next_numbers.size():
			number = clampi(next_numbers[i], 1, 7)
		var slot: Vector2i = slots[i]
		var rect := Rect2(corner + Vector2(slot) * stride, Vector2(cell, cell))
		_preview_styles[Pal.NUMBER_COLORS[number - 1]].draw(get_canvas_item(), rect)
		var font_size := int(cell * 0.58)
		var text := str(number)
		var text_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(
			_font,
			Vector2(rect.get_center().x - text_width * 0.5, rect.get_center().y + font_size * 0.36),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Pal.CELL_TEXT
		)


func _star(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.36, -radius * 0.36),
		center + Vector2(radius, 0),
		center + Vector2(radius * 0.36, radius * 0.36),
		center + Vector2(0, radius),
		center + Vector2(-radius * 0.36, radius * 0.36),
		center + Vector2(-radius, 0),
		center + Vector2(-radius * 0.36, -radius * 0.36),
	])
	draw_colored_polygon(points, Pal.CELL_TEXT)


func _text(text: String, pos: Vector2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(_font, pos, text, alignment, width, font_size, color)
