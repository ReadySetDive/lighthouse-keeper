extends SceneTree
## Balance check: plays the economy like a casual player and prints when the story's beats land.
## Run with: godot --headless --path . --script sim.gd

const STEP := 5.0 # seconds between the simulated player's looks at the shop
const FIRST_SESSION := 1800.0
const CHECK_IN := 480.0
const TAPPING_SECONDS := 600.0 # the player taps for the first ten minutes, then mostly watches
const TAPS_PER_SECOND := 1.0
const SAVE_UP_SECONDS := 600.0 # a key within this much income is worth saving for


func _init() -> void:
	for check_ins in [3, 5]:
		_play(check_ins)
	quit()


func _play(check_ins: int) -> void:
	print("--- %d check-ins a day ---" % check_ins)
	var economy := Economy.new()
	var start := 8.0 * 3600
	var clock := _session(economy, start, FIRST_SESSION, start)
	var day := 0
	while not economy.ended and day < 40:
		print("day %d starts  tier %d  income %s/s" % [day, economy.tier, Economy.format(economy.income_per_second())])
		for i in check_ins:
			var at := (day * 24 + 8.0 + 14.0 * i / (check_ins - 1)) * 3600
			if at <= clock:
				continue
			economy.away(at - clock)
			clock = _session(economy, at, CHECK_IN, start)
			if economy.ended:
				break
		day += 1
	if not economy.ended:
		print("not finished after 40 days; tier %d, %s coin" % [economy.tier, Economy.format(economy.coins)])


func _session(economy: Economy, at: float, length: float, start: float) -> float:
	var elapsed := 0.0
	while elapsed < length:
		economy.advance(STEP)
		var played := at + elapsed - start
		if played < TAPPING_SECONDS:
			economy.earn(economy.flash_value() * TAPS_PER_SECOND * STEP)
		_shop(economy, played)
		elapsed += STEP
	return at + length


func _shop(economy: Economy, played: float) -> void:
	var item = _choose(economy)
	while item != null:
		if economy.count(item) == 0 and (played < 300 or not Economy.is_generator(item)):
			print("%s  %-22s income %s/s" % [_when(played), item.name, Economy.format(economy.income_per_second())])
		economy.buy(item, 1)
		item = _choose(economy)


## Keys are saved for once near; small one-offs are bought on sight; generators and boosts are
## bought by fastest payback, accepting anything within 3x of the best one affordable now.
func _choose(economy: Economy):
	var income := economy.income_per_second()
	var options := []
	var best_payback := INF
	for item in Content.ITEMS:
		if item.tier > economy.tier or (not Economy.is_generator(item) and economy.count(item) > 0):
			continue
		var cost := economy.cost(item, 1)
		match item.kind:
			"tier_up", "ending":
				if cost <= economy.coins + income * SAVE_UP_SECONDS:
					return item if economy.coins >= cost else null
				continue
			"tap", "storm", "away_cap", "away_rate":
				if economy.coins >= cost:
					return item
				continue
		var gain := _income_with(economy, item) - income
		var payback := cost / gain if gain > 0 else INF
		options.append([item, payback, cost])
		best_payback = minf(best_payback, payback)
	options.sort_custom(func(a, b): return a[1] < b[1])
	for option in options:
		if economy.coins >= option[2] and option[1] <= best_payback * 3:
			return option[0]
	return null


func _income_with(economy: Economy, item: Dictionary) -> float:
	var had := economy.count(item)
	economy.owned[item.id] = had + 1
	var income := economy.income_per_second()
	economy.owned[item.id] = had
	return income


func _when(seconds: float) -> String:
	if seconds < 3600:
		return "%5.1f min  " % (seconds / 60)
	return "day %4.2f  " % (seconds / 86400)
