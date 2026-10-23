extends Node2D
## The coast at night, drawn fresh every frame from what the keeper owns. Positions are in game
## pixels; `pixel` screen pixels make one game pixel, and each tier makes game pixels smaller.

signal thundered

const MAX_SHIPS_SHOWN_PER_MINUTE := 20.0
const SHIP_SPEED := Vector2(6, 11) # game pixels per second, slowest to fastest
const BEAM_TURN_SPEED := 0.9 # radians per second

var economy: Economy
var pixel := 1
var size := Vector2i.ZERO
var view_height := 0 # game pixels above the shop panel
var storming := false
var fade := 0.0 # tier-up ceremony: 0 clear, 1 black
var ships := []
var popups := []
var _time := 0.0
var _flash := 0.0
var _lightning := 0.0
var _ships_due := 0.0
var _stars := []
var _rng := RandomNumberGenerator.new()


func configure(new_pixel: int, screen_size: Vector2, shop_top: float) -> void:
	pixel = new_pixel
	size = Vector2i(ceili(screen_size.x / pixel), ceili(screen_size.y / pixel))
	view_height = ceili(shop_top / pixel)
	ships.clear()
	popups.clear()
	_rng.seed = 7 # the same sky every time
	_stars.clear()
	for i in 60:
		_stars.append(Vector2i(_rng.randi_range(0, size.x), _rng.randi_range(0, horizon() - 2)))
	_rng.randomize()


func horizon() -> int:
	return int(view_height * 0.4)


func shore() -> int:
	return view_height - 30


func tower_x() -> int:
	return int(size.x * 0.2)


func tower_base() -> int:
	return shore() + 6


func tower_height() -> int:
	return 24 + 3 * mini(_owned("gallery"), 6)


func lamp() -> Vector2i:
	return Vector2i(tower_x(), tower_base() - tower_height() - 3)


func flash() -> void:
	_flash = 0.3


func popup(at: Vector2, text: String, color: Color) -> void:
	popups.append({"x": at.x, "y": at.y, "text": text, "color": color, "age": 0.0})


func send_distressed_ship() -> void:
	_launch(true, 0)


func distressed_ship_near(point: Vector2) -> Dictionary:
	for ship in ships:
		if ship.distressed and Vector2(ship.x, ship.y).distance_to(point) < 10:
			return ship
	return {}


func tick(delta: float) -> void:
	_time += delta
	_flash = maxf(0, _flash - delta)
	_lightning = maxf(0, _lightning - delta)
	if storming and _rng.randf() < delta * 0.12:
		_lightning = 0.12
		thundered.emit()
	_bring_ships(delta)
	_move_ships(delta)
	for each in popups:
		each.age += delta
		each.y -= delta * 8
	popups = popups.filter(func(each): return each.age < 1.2)
	queue_redraw()


func _bring_ships(delta: float) -> void:
	var shown_per_minute := minf(economy.ships_per_minute(), MAX_SHIPS_SHOWN_PER_MINUTE)
	_ships_due += shown_per_minute / 60 * delta
	while _ships_due >= 1:
		_ships_due -= 1
		# Each ship shown stands for all the ships that pass while it crosses
		_launch(false, economy.ship_income_per_second() * 60 / shown_per_minute)


func _launch(distressed: bool, pay: float) -> void:
	var heading := 1 if _rng.randf() < 0.5 else -1
	ships.append({
		"x": -8.0 if heading > 0 else size.x + 8.0,
		"y": float(_rng.randi_range(horizon() + 4, shore() - 6)),
		"heading": heading,
		"speed": _rng.randf_range(SHIP_SPEED.x, SHIP_SPEED.y) * (0.5 if distressed else 1.0),
		"pay": pay,
		"paid": distressed, # a ship in trouble pays only when rescued
		"distressed": distressed,
	})


func _move_ships(delta: float) -> void:
	for ship in ships:
		ship.x += ship.heading * ship.speed * delta
		if not ship.paid and (ship.x - tower_x()) * ship.heading >= 0:
			ship.paid = true
			popup(Vector2(ship.x, ship.y - 8), "+" + Economy.format(ship.pay), Palette.LAMP)
	ships = ships.filter(func(ship): return ship.x > -10 and ship.x < size.x + 10)


func _owned(id: String) -> int:
	return economy.owned.get(id, 0)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(pixel, pixel))
	_draw_sky()
	_draw_sea()
	_draw_harbour()
	for ship in ships:
		_draw_ship(ship)
	_draw_beams()
	_draw_land()
	_draw_back_row()
	_draw_tower()
	_draw_front_row()
	_draw_air()
	for each in popups:
		_draw_popup(each)
	if storming:
		_draw_rain()
	if fade > 0:
		_box(0, 0, size.x, size.y, Color(Palette.NIGHT, fade))


func _box(x: float, y: float, width: float, height: float, color: Color) -> void:
	draw_rect(Rect2(int(x), int(y), int(width), int(height)), color)


func _draw_sky() -> void:
	var sky := Palette.MIST if _lightning > 0 else (Palette.DEEP if storming else Palette.NIGHT)
	_box(0, 0, size.x, horizon(), sky)
	if storming:
		return
	for i in _stars.size():
		if (i * 7 + int(_time * 1.5)) % 11 != 0: # a few blink off at a time
			_box(_stars[i].x, _stars[i].y, 1, 1, Palette.BONE if i % 4 == 0 else Palette.MIST)
	if economy.tier >= 1:
		_draw_moon()
	if economy.tier >= 2:
		_box(0, horizon() - 6, size.x, 4, Palette.DUSK)
		_box(0, horizon() - 2, size.x, 2, Palette.ROSE)
		_draw_shooting_star()


func _moon() -> Vector2i:
	return Vector2i(int(size.x * 0.78), int(view_height * 0.12))


func _draw_moon() -> void:
	var widths := [3, 5, 5, 5, 3]
	for row in widths.size():
		_box(_moon().x - widths[row] / 2, _moon().y - 2 + row, widths[row], 1, Palette.FOAM)


func _draw_shooting_star() -> void:
	const EVERY := 9.0
	var phase := fmod(_time, EVERY)
	if phase > 0.6:
		return
	var which := int(_time / EVERY)
	var start := Vector2((which * 53) % maxi(1, size.x / 2) + 10, 6 + (which * 17) % maxi(1, horizon() / 2))
	for trail in 5:
		var at := start + Vector2(phase * 80 - trail * 2, phase * 25 - trail * 0.6)
		_box(at.x, at.y, 1, 1, Palette.WHITE if trail == 0 else Palette.MIST)


func _draw_sea() -> void:
	_box(0, horizon(), size.x, shore() - horizon() + 4, Palette.DEEP)
	_box(0, horizon(), size.x, 1, Palette.SEA)
	for y in range(horizon() + 3, shore(), 5):
		var drift := int(_time * (2 + y % 3)) + y * 7
		var length := 2 + (y - horizon()) / 12 # nearer waves are longer
		for x in range(-16, size.x, 16):
			var crest_x := x + posmod(drift, 16)
			_box(crest_x, y, length, 1, Palette.SEA)
			if economy.tier >= 1 and (x / 16 + y) % 3 == 0:
				_box(crest_x + length, y, 1, 1, Palette.FOAM)
	if economy.tier >= 2 and not storming:
		# The moon's reflection, shimmering on the water below it
		for y in range(horizon() + 2, shore(), 3):
			var width := 1 + (int(_time * 3) + y) % 3
			_box(_moon().x - width / 2 + int(sin(_time + y) * 1.5), y, width, 1, Palette.FOAM if (y / 3) % 2 == 0 else Palette.MIST)


func _draw_harbour() -> void:
	if _owned("jetty") > 0:
		var x := int(size.x * 0.62)
		var length := 6 + 3 * mini(_owned("jetty"), 6)
		_box(x - 1, shore() - length, 3, length + 1, Palette.WOOD)
		for y in range(shore() - length, shore(), 3):
			_box(x - 2, y, 1, 2, Palette.ROCK)
		if _owned("lifeboat") > 0:
			_box(x + 3, shore() - length + 1, 5, 2, Palette.RED)
			_box(x + 4, shore() - length, 3, 1, Palette.BONE)
	if _owned("breakwater") > 0:
		var start := int(size.x * 0.78)
		_box(start, shore() - 16, size.x - start, 3, Palette.MIST)
		for x in range(start, size.x, 4):
			_box(x, shore() - 16, 2, 1, Palette.ROCK)
		if int(_time * 2) % 2 == 0:
			_box(start, shore() - 18, 1, 2, Palette.RED)
	if _owned("tug") > 0:
		var x := int(size.x * (0.45 + 0.2 * (1 + sin(_time * 0.15))))
		var y := shore() - 7
		_box(x - 4, y, 8, 2, Palette.ROCK)
		_box(x - 1, y - 2, 3, 2, Palette.BONE)
		_box(x + 1, y - 4, 1, 2, Palette.RED)
		_draw_smoke(Vector2i(x + 1, y - 5))
	if _owned("dry_dock") > 0:
		var x := int(size.x * 0.9)
		_box(x - 7, shore() - 3, 14, 1, Palette.WOOD)
		for i in 5:
			_box(x - 5 + i * 2, shore() - 7, 1, 4, Palette.BONE)


func _draw_ship(ship: Dictionary) -> void:
	var x := int(ship.x)
	var y := int(ship.y)
	var hull := Palette.RED if ship.distressed and int(_time * 4) % 2 == 0 else Palette.MIST
	_box(x - 3, y, 7, 2, hull)
	_box(x - 2, y + 2, 5, 1, hull)
	_box(x, y - 5, 1, 5, Palette.MIST)
	_box(x + 1 if ship.heading > 0 else x - 2, y - 4, 2, 3, Palette.BONE)
	_box(x, y - 6, 1, 1, Palette.LAMP)
	if ship.distressed:
		PixelFont.draw(self, Vector2(x - 1, y - 13), "!", Palette.RED)


func _draw_beams() -> void:
	if _owned("wick") == 0:
		if _flash > 0:
			_draw_glow(lamp(), 7)
		return
	var angle := _time * BEAM_TURN_SPEED if _owned("clockwork") > 0 else 0.0
	_draw_beam(lamp(), _beam_length(), angle, Palette.WHITE if _owned("electric") > 0 else Palette.LAMP)
	if _owned("second_light") > 0:
		_draw_beam(_second_lamp(), _beam_length() * 0.6, angle + PI, Palette.LAMP)
	_draw_glow(lamp(), 2 + int(_flash * 20))


func _beam_length() -> float:
	var length := 30.0 + 8.0 * log(1.0 + economy.ships_per_minute()) / log(10.0)
	if _owned("fresnel") > 0:
		length *= 1.4
	if _owned("electric") > 0:
		length *= 1.3
	return minf(length, size.x * 1.2)


## Seen from the side, a turning beam sweeps out to one side, shortens as it turns toward or
## away from us, then sweeps out to the other side.
func _draw_beam(origin: Vector2i, length: float, angle: float, core: Color) -> void:
	var facing := cos(angle)
	var side := 1 if facing >= 0 else -1
	for step in int(length * absf(facing)):
		var x := origin.x + side * (step + 2)
		var spread := minf(1.0 + step * 0.12, 12.0)
		for dy in range(-int(spread), int(spread) + 1):
			var in_core := absf(dy) <= spread * 0.3
			if in_core or posmod(x + dy, 2) == 0:
				_box(x, origin.y + dy, 1, 1, core if in_core else Palette.LAMP)
	if absf(facing) < 0.3 and sin(angle) > 0: # turned toward us, the lamp flares
		_draw_glow(origin, 6)


func _draw_glow(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius and posmod(dx + dy, 2) == 0:
				_box(center.x + dx, center.y + dy, 1, 1, Palette.LAMP)


func _draw_land() -> void:
	_box(0, shore(), size.x, size.y - shore(), Palette.ROCK)
	_box(tower_x() - 8, shore() - 3, 16, 3, Palette.ROCK)
	_box(tower_x() - 5, shore() - 5, 9, 2, Palette.ROCK)
	if economy.tier >= 1:
		_box(0, shore(), size.x, 2, Palette.GRASS)
		for x in range(0, size.x, 6): # surf where the sea meets the shore
			if (x / 6 + int(_time * 2)) % 3 != 0:
				_box(x + 2, shore() - 1, 3, 1, Palette.FOAM)
	if economy.tier >= 2:
		_box(0, view_height - 5, size.x, 1, Palette.MIST) # the quay's edge


func _draw_tower() -> void:
	var x := tower_x()
	var base := tower_base()
	var top := base - tower_height()
	_box(x - 3, top, 6, tower_height(), Palette.BONE)
	for y in range(top + 3, base - 2, 7):
		_box(x - 3, y, 6, 3, Palette.RED)
	_box(x - 1, base - 4, 2, 4, Palette.DEEP)
	_box(x - 5, top - 1, 10, 1, Palette.MIST)
	_box(x - 2, top - 5, 4, 4, Palette.LAMP if _owned("wick") > 0 else Palette.DEEP)
	_box(x - 3, top - 6, 6, 1, Palette.LAMP if _owned("polish") > 0 else Palette.MIST)
	_box(x - 3, top - 7, 6, 1, Palette.RED)
	_box(x - 2, top - 8, 4, 1, Palette.RED)
	_box(x - 1, top - 9, 2, 1, Palette.RED)
	if _owned("flags") > 0:
		for i in 7:
			var at := Vector2(x + 3, top).lerp(Vector2(x + 18, base), i / 6.0)
			_box(at.x, at.y, 1, 2, [Palette.RED, Palette.LAMP, Palette.BONE][i % 3])
	if _owned("foghorn") > 0:
		_box(x + 3, top + 2, 3, 2, Palette.MIST)
		var ring := fmod(_time, 10.0)
		if ring < 1.5:
			_draw_ring(Vector2i(x + 6, top + 3), int(ring * 12))
	_draw_cottage(x + 9, base)


func _draw_ring(center: Vector2i, radius: int) -> void:
	for i in 16:
		var angle := i / 16.0 * TAU
		if cos(angle) > -0.2:
			_box(center.x + cos(angle) * radius, center.y + sin(angle) * radius, 1, 1, Palette.MIST)


func _draw_cottage(x: int, base: int) -> void:
	_box(x - 4, base - 5, 8, 5, Palette.BONE)
	_box(x - 5, base - 7, 10, 2, Palette.RED)
	_box(x + 1, base - 4, 2, 2, Palette.LAMP if _owned("logbook") > 0 else Palette.DEEP)
	if _owned("kettle") > 0:
		_box(x + 3, base - 9, 1, 2, Palette.ROCK)
		_draw_smoke(Vector2i(x + 3, base - 10))


func _draw_smoke(chimney: Vector2i) -> void:
	for i in 3:
		var rise := fmod(_time * 3 + i * 3.0, 9.0)
		_box(chimney.x + int(rise / 3), chimney.y - int(rise), 1, 1, Palette.MIST)


func _draw_back_row() -> void:
	var base := shore() + 12
	if _owned("net_loft") > 0:
		var x := int(size.x * 0.45)
		_box(x - 5, base - 7, 10, 7, Palette.WOOD)
		_box(x - 6, base - 9, 12, 2, Palette.ROCK)
		_box(x + 6, base - 6, 1, 6, Palette.WOOD)
		_box(x + 14, base - 6, 1, 6, Palette.WOOD)
		for i in 4:
			_box(x + 7 + i * 2, base - 5 + i % 2, 1, 1, Palette.MIST)
	if _owned("customs") > 0:
		var x := int(size.x * 0.6)
		_box(x - 8, base - 10, 16, 10, Palette.BONE)
		_box(x - 9, base - 12, 18, 2, Palette.DUSK)
		for row in 2:
			for column in 4:
				_box(x - 6 + column * 4, base - 8 + row * 4, 2, 2, Palette.WINDOW)
	if _owned("bank") > 0:
		var x := int(size.x * 0.78)
		_box(x - 6, base - 8, 12, 8, Palette.MIST)
		for column in 4:
			_box(x - 5 + column * 3, base - 7, 1, 7, Palette.BONE)
		_box(x - 7, base - 10, 14, 2, Palette.BONE)
		_box(x - 4, base - 11, 8, 1, Palette.BONE)


func _draw_front_row() -> void:
	var base := shore() + 22
	for i in mini(_owned("hut"), 5):
		var x := int(size.x * (0.36 + i * 0.07))
		_box(x - 3, base - 4, 6, 4, Palette.WOOD)
		_box(x - 4, base - 6, 8, 2, Palette.ROCK)
		_box(x + 1, base - 3, 1, 1, Palette.WINDOW)
		_box(x - 2, base - 2, 1, 2, Palette.NIGHT)
	if _owned("smokehouse") > 0:
		var x := int(size.x * 0.74)
		_box(x - 4, base - 6, 8, 6, Palette.ROCK)
		_box(x - 5, base - 8, 10, 2, Palette.WOOD)
		_box(x + 2, base - 11, 2, 3, Palette.ROCK)
		_draw_smoke(Vector2i(x + 2, base - 12))
	if _owned("market") > 0:
		var x := int(size.x * 0.86)
		_box(x - 4, base - 3, 8, 3, Palette.WOOD)
		for i in 8:
			_box(x - 4 + i, base - 7, 1, 2, Palette.RED if i % 2 == 0 else Palette.BONE)
		_box(x - 4, base - 5, 1, 2, Palette.WOOD)
		_box(x + 3, base - 5, 1, 2, Palette.WOOD)
	if _owned("second_light") > 0:
		var x := _second_lamp().x
		var top := _second_lamp().y + 2
		_box(x - 2, top, 4, shore() + 4 - top, Palette.BONE)
		for y in range(top + 2, shore() + 2, 5):
			_box(x - 2, y, 4, 2, Palette.RED)
		_box(x - 1, top - 3, 2, 3, Palette.LAMP)
		_box(x - 2, top - 4, 4, 1, Palette.RED)
	for i in mini(_owned("gas_lamps"), 12):
		var x := int(size.x * (0.3 + 0.65 * i / 11.0))
		var y := view_height - 5
		_box(x, y - 4, 1, 4, Palette.MIST)
		_box(x, y - 5, 1, 1, Palette.WINDOW)
		if (i + int(_time * 2)) % 4 != 0:
			_box(x - 1, y - 6, 1, 1, Palette.WINDOW)
			_box(x + 1, y - 4, 1, 1, Palette.WINDOW)


func _second_lamp() -> Vector2i:
	return Vector2i(int(size.x * 0.94), shore() - 14)


## Life in the air arrives with the hamlet: gulls and the breeze; the port adds lantern motes.
func _draw_air() -> void:
	if economy.tier < 1 or storming:
		return
	for i in 5:
		var x := posmod(int(_time * (10 + i * 3)) + i * 61, size.x + 30) - 15
		var y := 8 + (i * 23) % maxi(1, horizon() - 10)
		for dash in range(0, 6 + i % 3 * 2, 2):
			_box(x + dash, y, 1, 1, Palette.MIST)
	for i in 3:
		var x := posmod(int(_time * (6 + i * 2)) + i * 97, size.x + 20) - 10
		var y := 12 + (i * 17) % maxi(1, horizon() - 4) + int(sin(_time * 2 + i) * 2)
		var lift := 1 if int(_time * 4 + i) % 2 == 0 else 0
		_box(x - 2, y - lift, 2, 1, Palette.BONE)
		_box(x + 1, y - lift, 2, 1, Palette.BONE)
		_box(x, y, 1, 1, Palette.BONE)
	if economy.tier >= 2:
		for i in 8:
			var x := posmod(int(_time * 2) + i * 29, size.x)
			var y := shore() + 2 + int(sin(_time + i * 1.7) * 3) - (i * 5) % 10
			if (i + int(_time * 3)) % 3 != 0:
				_box(x, y, 1, 1, Palette.WINDOW)


func _draw_rain() -> void:
	for i in 70:
		var y := posmod(int(i * 53 + _time * 110), view_height)
		var x := posmod(i * 37 + int(_time * 30) - y / 3, size.x)
		_box(x, y, 1, 3, Palette.MIST)


func _draw_popup(each: Dictionary) -> void:
	if each.age > 0.9 and int(each.age * 20) % 2 == 0:
		return
	var at := Vector2(int(each.x - PixelFont.width(each.text) / 2.0), int(each.y))
	PixelFont.draw(self, at + Vector2.ONE, each.text, Palette.NIGHT)
	PixelFont.draw(self, at, each.text, each.color)
