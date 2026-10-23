extends Node2D
## Runs the game: the clock, taps, storms, story log, saving, and fitting pixels to the phone.

const VERSION := "V0.1"
const UI_TARGET_WIDTH := 180.0
const SHOP_TOP_FRACTION := 0.5
const AUTOSAVE_SECONDS := 10.0
const WELCOME_BACK_SECONDS := 60.0
const LOG_LINES := 3
const DRAG_THRESHOLD := 12.0 # screen pixels; a press that moves further is a scroll, not a tap
const STORM_SECONDS := 40.0
const STORM_GAP_SECONDS := Vector2(300, 480)
const DISTRESS_EVERY_SECONDS := 6.0
const AMBIENT_LINE_SECONDS := Vector2(150, 240)
const RESCUE_INCOME_SECONDS := 30.0

@onready var world := $World
@onready var ui := $Ui
@onready var sfx := $Sfx

var economy := Economy.new()
var speed := 1.0 # dev time multiplier for the economy; animation always runs in real time
var muted := false
var cards := []
var log_lines := []
var dev_open := false
var _last_tick := 0.0 # unix seconds
var _autosave_in := AUTOSAVE_SECONDS
var _storm_in := 0.0
var _storm_left := 0.0
var _distress_in := 0.0
var _ambient_in := 0.0
var _ui_redraw_in := 0.0
var _press := {}
var _version_taps := []
var _asked_to_persist := false
var _visibility_callback: JavaScriptObject
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	speed = _speed_from_url()
	_last_tick = Time.get_unix_time_from_system()
	world.economy = economy
	ui.game = self
	world.thundered.connect(sfx.play.bind("thunder"))
	get_viewport().size_changed.connect(_layout)
	_storm_in = _rng.randf_range(STORM_GAP_SECONDS.x, STORM_GAP_SECONDS.y)
	_ambient_in = _rng.randf_range(AMBIENT_LINE_SECONDS.x, AMBIENT_LINE_SECONDS.y)
	cards.append({"title": "LIGHTHOUSE KEEPER", "text": "Tap to light the lamp.", "on_close": sfx.start_sea})
	var save := SaveGame.read()
	if save.is_empty():
		for line in Content.OPENING_LINES:
			say(line)
	else:
		_load(save)
	_layout()
	_listen_for_hidden_page()
	# Baking takes a moment; let the title card show first
	await get_tree().process_frame
	sfx.bake()


func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	var elapsed := now - _last_tick
	_last_tick = now
	# Android stops a hidden page's frames; a long gap means the player was away
	if elapsed > 2.0:
		_welcome_back(elapsed)
	else:
		economy.advance(elapsed * speed)
	_reveal_nearly_affordable()
	_tick_storm(delta)
	_tick_ambient_lines(delta)
	_autosave_in -= delta
	if _autosave_in <= 0:
		_save()
	world.storming = _storm_left > 0
	world.tick(delta)
	_ui_redraw_in -= delta
	if _ui_redraw_in <= 0:
		_ui_redraw_in = 0.1
		ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = {"at": event.position, "scroll": ui.scroll, "dragging": false}
		elif not _press.is_empty():
			if not _press.dragging:
				_tap(event.position)
			_press = {}
	elif event is InputEventMouseMotion and not _press.is_empty() and ui.in_list(_press.at):
		if _press.dragging or event.position.distance_to(_press.at) > DRAG_THRESHOLD:
			_press.dragging = true
			ui.scroll_to(_press.scroll - (event.position.y - _press.at.y) / ui.pixel)


func _tap(at: Vector2) -> void:
	if ui.tap(at):
		return
	var ship: Dictionary = world.distressed_ship_near(at / world.pixel)
	if ship.is_empty():
		_flash()
	else:
		_rescue(ship)


func _flash() -> void:
	var value := economy.flash_value()
	economy.earn(value)
	world.flash()
	world.popup(Vector2(world.lamp()) + Vector2(0, -8), "+" + Economy.format(value), Palette.LAMP)
	sfx.play("flash")


func _rescue(ship: Dictionary) -> void:
	var reward := maxf(economy.income_per_second() * RESCUE_INCOME_SECONDS, 10) * economy.storm_multiplier()
	economy.earn(reward)
	ship.distressed = false
	world.popup(Vector2(ship.x, ship.y - 8), "SAVED +" + Economy.format(reward), Palette.BONE)
	sfx.play("horn")


func buy(item: Dictionary, amount: int) -> void:
	if not economy.can_buy(item, amount):
		return
	var first := economy.count(item) == 0
	economy.buy(item, amount)
	sfx.play("buy")
	if first:
		say(item.line)
	match item.kind:
		"tier_up":
			_tier_up()
		"ending":
			sfx.play("bell")
			cards.append({"title": Content.ENDING_TITLE, "text": Content.ENDING_LETTER})
	# Ask the browser not to evict the save, once the player has something worth keeping
	if not _asked_to_persist and OS.has_feature("web"):
		_asked_to_persist = true
		JavaScriptBridge.eval("navigator.storage && navigator.storage.persist()")
	_save()


func say(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > LOG_LINES:
		log_lines.pop_front()
	ui.queue_redraw()


func close_card() -> void:
	var card: Dictionary = cards.pop_front()
	if card.has("on_close"):
		card.on_close.call()


func toggle_sound() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	_save()


func export_code() -> void:
	_save()
	var code := SaveGame.encode(_snapshot())
	DisplayServer.clipboard_set(code)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.prompt('Your save code. It is also on your clipboard; keep it somewhere safe.', %s)" % JSON.stringify(code))
	say("Save code copied.")


func import_code() -> void:
	var pasted = JavaScriptBridge.eval("window.prompt('Paste a save code:')") if OS.has_feature("web") else DisplayServer.clipboard_get()
	if pasted == null or pasted.strip_edges() == "":
		return
	var save = SaveGame.decode(pasted)
	if save is String:
		cards.append({"title": "THAT CODE DID NOT WORK", "text": save})
		return
	_load(save)
	_layout()
	say("Save loaded.")
	_save()


func version_tapped() -> void:
	var now := Time.get_ticks_msec()
	_version_taps.append(now)
	_version_taps = _version_taps.filter(func(tapped): return now - tapped < 3000)
	if _version_taps.size() >= 5:
		_version_taps.clear()
		dev_open = true


func set_speed(new_speed: float) -> void:
	speed = new_speed


## Plays out an absence of `game_seconds` exactly as a real one would be.
func dev_away(game_seconds: float) -> void:
	_welcome_back(game_seconds / speed)


func dev_coins() -> void:
	economy.earn(maxf(economy.coins * 9, 100))


func dev_wipe() -> void:
	SaveGame.erase()
	get_tree().reload_current_scene()


func _load(save: Dictionary) -> void:
	economy = Economy.from_dict(save.economy)
	world.economy = economy
	muted = save.muted
	AudioServer.set_bus_mute(0, muted)
	ui.tab = economy.tier
	_last_tick = Time.get_unix_time_from_system()
	_welcome_back(_last_tick - save.saved_at)


func _welcome_back(real_seconds: float) -> void:
	var game_seconds := real_seconds * speed
	var coins_before := economy.coins
	var credited := economy.away(game_seconds)
	if real_seconds < WELCOME_BACK_SECONDS:
		return
	var lines := [
		"%s passed." % _duration(game_seconds),
		"%s ships guided." % Economy.format(economy.ships_per_minute() / 60 * credited),
		"+%s coin." % Economy.format(economy.coins - coins_before),
	]
	if credited < game_seconds:
		lines.append("\nYour watch only covers %s. Buy more away time in the shop." % _duration(economy.away_cap_seconds()))
	cards.append({"title": "WHILE YOU WERE AWAY", "text": "\n".join(lines)})
	# About one return in three finds a storm brewing
	if real_seconds > 600 and _rng.randf() < 0.33:
		_storm_in = 5.0


func _tier_up() -> void:
	var tier: Dictionary = Content.TIERS[economy.tier]
	sfx.play("bell")
	ui.tab = economy.tier
	ui.scroll = 0
	cards.append({"title": tier.letter_from, "text": tier.letter})
	say("The %s." % tier.name.to_lower())
	# Fade out, change to the finer pixel grid while it is dark, then fade back in
	var ceremony := create_tween()
	ceremony.tween_property(world, "fade", 1.0, 0.8)
	ceremony.tween_callback(_layout)
	ceremony.tween_property(world, "fade", 0.0, 0.8)


func _tick_storm(delta: float) -> void:
	if _storm_left > 0:
		_storm_left -= delta
		_distress_in -= delta
		if _distress_in <= 0:
			_distress_in = DISTRESS_EVERY_SECONDS
			world.send_distressed_ship()
		if _storm_left <= 0:
			say("The storm passes.")
			sfx.stop_rain()
			_storm_in = _rng.randf_range(STORM_GAP_SECONDS.x, STORM_GAP_SECONDS.y)
	elif economy.ships_per_minute() > 0 and cards.is_empty():
		_storm_in -= delta
		if _storm_in <= 0:
			_storm_left = STORM_SECONDS
			_distress_in = 1.0
			say("A storm! Tap the ships in trouble.")
			sfx.start_rain()


func _tick_ambient_lines(delta: float) -> void:
	_ambient_in -= delta
	if _ambient_in <= 0:
		_ambient_in = _rng.randf_range(AMBIENT_LINE_SECONDS.x, AMBIENT_LINE_SECONDS.y)
		var lines: Array = Content.AMBIENT_LINES[economy.tier]
		say(lines[_rng.randi() % lines.size()])


## Items show their name once the player has half their price.
func _reveal_nearly_affordable() -> void:
	for item in Content.ITEMS:
		if item.tier <= economy.tier and economy.coins >= economy.unit_cost(item) / 2:
			economy.revealed[item.id] = true


func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	ui.configure(maxi(1, floori(screen.x / UI_TARGET_WIDTH)), screen, SHOP_TOP_FRACTION)
	world.configure(_world_pixel(screen.x), screen, ui.shop_top_on_screen())
	ui.queue_redraw()


## Whole-number pixels stay crisp, so each tier uses the largest pixel that still reaches its
## target width, and always a smaller one than the tier before so the step up is visible.
func _world_pixel(screen_width: float) -> int:
	var pixel := 1 << 20
	for tier in economy.tier + 1:
		pixel = mini(pixel - 1, floori(screen_width / Content.TIERS[tier].target_width))
	return maxi(1, pixel)


func _save() -> void:
	_autosave_in = AUTOSAVE_SECONDS
	SaveGame.write(_snapshot())


func _snapshot() -> Dictionary:
	return {
		"version": SaveGame.VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"muted": muted,
		"economy": economy.to_dict(),
	}


## Saving when the page is hidden matters most on Android, where a backgrounded tab can be
## killed without warning.
func _listen_for_hidden_page() -> void:
	if not OS.has_feature("web"):
		return
	_visibility_callback = JavaScriptBridge.create_callback(_on_visibility_change)
	JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _visibility_callback)


func _on_visibility_change(_arguments: Array) -> void:
	if JavaScriptBridge.eval("document.hidden"):
		_save()


func _speed_from_url() -> float:
	if not OS.has_feature("web"):
		return 1.0
	var value = JavaScriptBridge.eval("new URLSearchParams(location.search).get('speed')")
	return float(value) if value else 1.0


func _duration(seconds: float) -> String:
	var minutes := floori(seconds / 60)
	if minutes < 60:
		return "%dm" % minutes
	if minutes < 24 * 60:
		return "%dh %dm" % [minutes / 60, minutes % 60]
	return "%dd %dh" % [minutes / 1440, minutes % 1440 / 60]
