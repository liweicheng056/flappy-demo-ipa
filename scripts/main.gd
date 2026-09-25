extends Node2D
## Flappy Bird demo - tap / click / space to flap.

const GRAVITY := 1400.0
const FLAP := -480.0
const PIPE_SPEED := 180.0
const PIPE_W := 70.0
const PIPE_GAP := 190.0
const SPAWN_INTERVAL := 1.7
const BIRD_X := 130.0
const BIRD_R := 18.0

var bird_y := 400.0
var velocity := 0.0
var pipes: Array = []
var score := 0
var best := 0
var started := false
var game_over := false
var spawn_timer := 0.0
var ground_h := 80.0
var w := 480.0
var h := 800.0


func _ready() -> void:
	w = get_viewport_rect().size.x
	h = get_viewport_rect().size.y
	bird_y = h * 0.5


func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		tapped = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		tapped = true
	if not tapped:
		return
	if game_over:
		_restart()
		return
	if not started:
		started = true
	velocity = FLAP


func _process(delta: float) -> void:
	if not started or game_over:
		queue_redraw()
		return
	velocity += GRAVITY * delta
	bird_y += velocity * delta
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_spawn_pipe()
	for p in pipes:
		p.x -= PIPE_SPEED * delta
		if not p.scored and p.x + PIPE_W < BIRD_X - BIRD_R:
			p.scored = true
			score += 1
	pipes = pipes.filter(func(p): return p.x > -PIPE_W)
	_check_collision()
	queue_redraw()


func _spawn_pipe() -> void:
	var margin := 120.0
	var gap_y := randf_range(margin, h - ground_h - margin)
	pipes.append({"x": w + PIPE_W, "gap_y": gap_y, "scored": false})


func _check_collision() -> void:
	if bird_y - BIRD_R < 0 or bird_y + BIRD_R > h - ground_h:
		_die()
		return
	for p in pipes:
		if BIRD_X + BIRD_R > p.x and BIRD_X - BIRD_R < p.x + PIPE_W:
			if bird_y - BIRD_R < p.gap_y - PIPE_GAP * 0.5 or bird_y + BIRD_R > p.gap_y + PIPE_GAP * 0.5:
				_die()
				return


func _die() -> void:
	game_over = true
	if score > best:
		best = score


func _restart() -> void:
	bird_y = h * 0.5
	velocity = 0.0
	pipes.clear()
	score = 0
	spawn_timer = 0.0
	started = false
	game_over = false


func _draw() -> void:
	# sky
	draw_rect(Rect2(0, 0, w, h), Color(0.45, 0.75, 0.9))
	# pipes
	for p in pipes:
		var top_h: float = p.gap_y - PIPE_GAP * 0.5
		var bot_y: float = p.gap_y + PIPE_GAP * 0.5
		draw_rect(Rect2(p.x, 0, PIPE_W, top_h), Color(0.2, 0.7, 0.25))
		draw_rect(Rect2(p.x, bot_y, PIPE_W, h - ground_h - bot_y), Color(0.2, 0.7, 0.25))
	# ground
	draw_rect(Rect2(0, h - ground_h, w, ground_h), Color(0.85, 0.75, 0.5))
	# bird body + eye + beak
	draw_circle(Vector2(BIRD_X, bird_y), BIRD_R, Color(1.0, 0.85, 0.15))
	draw_circle(Vector2(BIRD_X + 7, bird_y - 6), 4.0, Color.WHITE)
	draw_circle(Vector2(BIRD_X + 8, bird_y - 6), 2.0, Color.BLACK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(BIRD_X + BIRD_R - 2, bird_y),
		Vector2(BIRD_X + BIRD_R + 10, bird_y + 4),
		Vector2(BIRD_X + BIRD_R - 2, bird_y + 8),
	]), Color(1.0, 0.5, 0.1))
	# HUD
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(w * 0.5 - 10, 90), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color.WHITE)
	if not started and not game_over:
		_center_text(font, "点击屏幕开始", h * 0.42, 32, Color.WHITE)
	if game_over:
		_center_text(font, "游戏结束", h * 0.40, 40, Color(0.9, 0.2, 0.2))
		_center_text(font, "得分 %d  最高 %d" % [score, best], h * 0.47, 28, Color.WHITE)
		_center_text(font, "点击重新开始", h * 0.54, 26, Color.WHITE)


func _center_text(font: Font, text: String, y: float, size: int, color: Color) -> void:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((w - tw) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
