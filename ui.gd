extends Node2D
## The counters, story log, shop, cards and dev panel, on their own fixed pixel grid so tap
## targets stay the same size when the world's resolution changes at a tier-up.
## Buttons are registered while drawing, so what you can tap is exactly what you can see.

const ROW_HEIGHT := 22
const BAR_HEIGHT := 14
const BUY_AMOUNTS := [1, 10, 0] # 0 buys as many as you can afford
const SPEEDS := [1.0, 10.0, 100.0, 1000.0]

var game # main.gd, which owns the state and acts on taps
var pixel := 1
var size := Vector2i.ZERO
var shop_top := 0
var tab := 0
var buy_amount := 1
var scroll := 0.0
var _buttons := []


func configure(new_pixel: int, screen_size: Vector2, shop_fraction: float) -> void:
	pixel = new_pixel
	size = Vector2i(floori(screen_size.x / pixel), ceili(screen_size.y / pixel))
	shop_top = int(size.y * shop_fraction)


func shop_top_on_screen() -> float:
	return shop_top * pixel


## Runs the button under a tap. Returns whether the tap belonged to the UI rather than the world.
func tap(screen_point: Vector2) -> bool:
	var point := screen_point / pixel
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].rect.has_point(point):
			_buttons[i].action.call()
			queue_redraw()
			return true
	return point.y >= shop_top


func in_list(screen_point: Vector2) -> bool:
	return _list_rect().has_point(screen_point / pixel)


func scroll_to(offset: float) -> void:
	var overflow := _rows(tab).size() * ROW_HEIGHT - _list_rect().size.y
	scroll = clampf(offset, 0, maxf(0, overflow))
	queue_redraw()


func _list_rect() -> Rect2:
	return Rect2(0, shop_top + BAR_HEIGHT + 1, size.x, size.y - BAR_HEIGHT * 2 - shop_top - 1)


## The revealed items of a tier, then one silhouette hinting at what comes next.
## Bought one-offs leave the list so it never becomes a wall.
func _rows(tier: int) -> Array:
	var economy: Economy = game.economy
	var rows := []
	for item in Content.ITEMS:
		if item.tier != tier or (not Economy.is_generator(item) and economy.count(item) > 0):
			continue
		if economy.revealed.has(item.id):
			rows.append(item)
		else:
			rows.append(item)
			break
	return rows


func _button(rect: Rect2, action: Callable) -> void:
	_buttons.append({"rect": rect, "action": action})


func _box(x: float, y: float, width: float, height: float, color: Color) -> void:
	draw_rect(Rect2(x, y, width, height), color)


func _outline(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, false, 1.0)


func _text(x: float, y: float, text: String, color: Color, scale := 1) -> void:
	PixelFont.draw(self, Vector2(x, y), text, color, scale)


func _text_right(right: float, y: float, text: String, color: Color) -> void:
	_text(right - PixelFont.width(text), y, text, color)


func _draw() -> void:
	_buttons.clear()
	draw_set_transform(Vector2.ZERO, 0, Vector2(pixel, pixel))
	_draw_counters()
	_draw_log()
	_draw_shop()
	if not game.cards.is_empty():
		_draw_card(game.cards[0])
	elif game.dev_open:
		_draw_dev_panel()


func _draw_counters() -> void:
	var economy: Economy = game.economy
	_box(0, 0, size.x, 18, Palette.NIGHT)
	_text(4, 4, Economy.format(economy.coins), Palette.LAMP, 2)
	_text_right(size.x - 4, 3, "+%s/S" % Economy.format_rate(economy.income_per_second()), Palette.BONE)
	_text_right(size.x - 4, 10, "%s SHIPS/MIN" % Economy.format_rate(economy.ships_per_minute()), Palette.MIST)


func _draw_log() -> void:
	var lines: Array = game.log_lines
	for i in lines.size():
		var y := shop_top - PixelFont.LINE_HEIGHT * (lines.size() - i) - 2
		var color := Palette.BONE if i == lines.size() - 1 else Palette.MIST
		_text(5, y + 1, lines[i], Palette.NIGHT)
		_text(4, y, lines[i], color)


func _draw_shop() -> void:
	_box(0, shop_top, size.x, size.y - shop_top, Palette.NIGHT)
	var list := _list_rect()
	var y := list.position.y - scroll
	for item in _rows(tab):
		if y + ROW_HEIGHT > list.position.y and y < list.end.y:
			_draw_row(item, y, list)
		y += ROW_HEIGHT
	# The bars are drawn after the rows so they cover any row scrolled half out of view
	_draw_tabs()
	_draw_footer()


func _draw_tabs() -> void:
	var economy: Economy = game.economy
	_box(0, shop_top, size.x, BAR_HEIGHT + 1, Palette.NIGHT)
	_box(0, shop_top, size.x, 1, Palette.MIST)
	var x := 2
	for tier in economy.tier + 1:
		var label: String = Content.TIERS[tier].tab
		var width := PixelFont.width(label) + 8
		var selected := tier == tab
		_text(x + 4, shop_top + 4, label, Palette.LAMP if selected else Palette.MIST)
		if selected:
			_box(x + 3, shop_top + 11, width - 6, 1, Palette.LAMP)
		_button(Rect2(x, shop_top + 1, width, BAR_HEIGHT), func():
			tab = tier
			scroll = 0)
		x += width
	var label := "MAX" if buy_amount == 0 else "X%d" % buy_amount
	var button := Rect2(size.x - 26, shop_top + 2, 24, 11)
	_outline(button, Palette.MIST)
	_text(button.position.x + (button.size.x - PixelFont.width(label)) / 2, shop_top + 5, label, Palette.BONE)
	_button(button, func(): buy_amount = BUY_AMOUNTS[(BUY_AMOUNTS.find(buy_amount) + 1) % BUY_AMOUNTS.size()])


func _amount_for(item: Dictionary) -> int:
	if not Economy.is_generator(item):
		return 1
	if buy_amount == 0:
		return maxi(1, game.economy.max_affordable(item))
	return buy_amount


func _draw_row(item: Dictionary, y: float, list: Rect2) -> void:
	var economy: Economy = game.economy
	var row := Rect2(2, y + 1, size.x - 4, ROW_HEIGHT - 2)
	if not economy.revealed.has(item.id):
		_box(row.position.x, row.position.y, row.size.x, row.size.y, Palette.NIGHT)
		_outline(row, Palette.DEEP)
		_text(7, y + 8, "? ? ?", Palette.MIST)
		return
	var amount := _amount_for(item)
	var affordable := economy.can_buy(item, amount)
	_box(row.position.x, row.position.y, row.size.x, row.size.y, Palette.DEEP if affordable else Palette.NIGHT)
	_outline(row, Palette.SEA if affordable else Palette.DEEP)
	var title: String = item.name
	if Economy.is_generator(item) and economy.count(item) > 0:
		title += " X%d" % economy.count(item)
	_text(7, y + 5, title, Palette.BONE if affordable else Palette.MIST)
	var price := Economy.format(economy.cost(item, amount))
	if amount > 1:
		price = "%s FOR %d" % [price, amount]
	_text_right(size.x - 7, y + 5, price, Palette.LAMP if affordable else Palette.MIST)
	_text(7, y + 13, _describe(item), Palette.MIST)
	if Economy.is_generator(item):
		var milestone := Economy.next_milestone(economy.count(item))
		if milestone > 0:
			_text_right(size.x - 7, y + 13, "X2 AT %d" % milestone, Palette.SEA)
	_button(row.intersection(list), func(): game.buy(item, _amount_for(item)))


func _describe(item: Dictionary) -> String:
	var each := Economy.format_rate(game.economy.output_each(item)) if Economy.is_generator(item) else ""
	match item.kind:
		"reach":
			return "+%s SHIPS/MIN EACH" % each
		"trade":
			return "+%s COIN/S EACH" % each
	return item.desc


func _draw_footer() -> void:
	var y := size.y - BAR_HEIGHT
	_box(0, y, size.x, BAR_HEIGHT, Palette.NIGHT)
	_box(0, y, size.x, 1, Palette.DEEP)
	var x := 2
	for entry in [
		["SAVE CODE", game.export_code],
		["LOAD CODE", game.import_code],
		["SOUND OFF" if game.muted else "SOUND ON", game.toggle_sound],
	]:
		var button := Rect2(x, y + 2, PixelFont.width(entry[0]) + 8, 11)
		_outline(button, Palette.DEEP)
		_text(x + 4, y + 5, entry[0], Palette.MIST)
		_button(button, entry[1])
		x += button.size.x + 3
	var version: String = game.VERSION
	_text_right(size.x - 4, y + 5, version, Palette.DEEP)
	_button(Rect2(size.x - 24, y, 24, BAR_HEIGHT), game.version_tapped)


func _draw_card(card: Dictionary) -> void:
	_box(0, 0, size.x, size.y, Color(Palette.NIGHT, 0.8))
	var width := size.x - 16
	var lines := PixelFont.wrap(card.text, (width - 12) / PixelFont.ADVANCE)
	var height := 30 + lines.size() * PixelFont.LINE_HEIGHT
	var top := (size.y - height) / 2
	_box(8, top, width, height, Palette.DEEP)
	_outline(Rect2(8, top, width, height), Palette.LAMP)
	_text(8 + (width - PixelFont.width(card.title)) / 2, top + 6, card.title, Palette.LAMP)
	for i in lines.size():
		_text(14, top + 16 + i * PixelFont.LINE_HEIGHT, lines[i], Palette.BONE)
	var hint := "TAP TO CONTINUE"
	_text(8 + (width - PixelFont.width(hint)) / 2, top + height - 9, hint, Palette.MIST)
	_button(Rect2(0, 0, size.x, size.y), game.close_card)


func _draw_dev_panel() -> void:
	var panel := Rect2(8, 30, size.x - 16, 98)
	_button(Rect2(0, 0, size.x, size.y), func(): pass) # the panel is modal
	_box(panel.position.x, panel.position.y, panel.size.x, panel.size.y, Palette.NIGHT)
	_outline(panel, Palette.RED)
	_text(14, 36, "DEV  SPEED %dX" % game.speed, Palette.RED)
	var actions := []
	for speed in SPEEDS:
		actions.append(["%dX" % speed, game.set_speed.bind(speed)])
	actions.append_array([
		["AWAY 1H", game.dev_away.bind(3600.0)],
		["AWAY 1D", game.dev_away.bind(86400.0)],
		["COIN X10", game.dev_coins],
		["WIPE SAVE", game.dev_wipe],
		["CLOSE", func(): game.dev_open = false],
	])
	for i in actions.size():
		var button := Rect2(14 + (i % 2) * ((panel.size.x - 12) / 2), 46 + (i / 2) * 15, (panel.size.x - 18) / 2, 12)
		_outline(button, Palette.MIST)
		_text(button.position.x + 4, button.position.y + 4, actions[i][0], Palette.BONE)
		_button(button, actions[i][1])
