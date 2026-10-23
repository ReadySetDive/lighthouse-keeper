class_name Economy
extends RefCounted
## The game's numbers: what the keeper owns, what things cost and what they earn.
## Pure state and arithmetic, so the headless balance sim can play it too.

const PRICE_GROWTH := 1.15
const MILESTONES := [10, 25, 50, 100] # owning this many of a generator doubles its output
const BASE_AWAY_CAP_HOURS := 2.0
const BASE_AWAY_RATE := 0.5
const COIN_PER_SHIP := 1.0
const FLASH_SHARE_OF_INCOME := 0.1 # so flashing still matters, a little, once income is large

var coins := 0.0
var lifetime_coins := 0.0
var tier := 0
var ended := false
var owned := {}
var revealed := {}


static func is_generator(item: Dictionary) -> bool:
	return item.kind == "reach" or item.kind == "trade"


static func milestone_multiplier(owned_count: int) -> float:
	var multiplier := 1.0
	for milestone in MILESTONES:
		if owned_count >= milestone:
			multiplier *= 2
	return multiplier


## The next milestone to aim for, or 0 once all are reached.
static func next_milestone(owned_count: int) -> int:
	for milestone in MILESTONES:
		if owned_count < milestone:
			return milestone
	return 0


static func format(number: float) -> String:
	if number < 1000:
		return str(floori(number))
	const SUFFIXES := ["K", "M", "B", "T", "QA", "QI"]
	var thousands := floori(log(number) / log(1000.0) + 1e-9)
	if thousands > SUFFIXES.size():
		var tens := floori(log(number) / log(10.0) + 1e-9)
		return "%.2fE%d" % [number / pow(10, tens), tens]
	var scaled := number / pow(1000, thousands)
	if scaled >= 100:
		return "%d%s" % [floori(scaled), SUFFIXES[thousands - 1]]
	if scaled >= 10:
		return "%.1f%s" % [scaled, SUFFIXES[thousands - 1]]
	return "%.2f%s" % [scaled, SUFFIXES[thousands - 1]]


## Rates are often fractional early on, so small ones keep a decimal.
static func format_rate(number: float) -> String:
	return "%.1f" % number if number < 100 else format(number)


func count(item: Dictionary) -> int:
	return owned.get(item.id, 0)


func unit_cost(item: Dictionary) -> float:
	if not is_generator(item):
		return item.cost
	return (Content.GEN_BASE_COST
		* pow(Content.GEN_COST_STEP, item.rank)
		* pow(Content.TIER_COST_STEP, item.tier)
		* pow(PRICE_GROWTH, count(item)))


## Each generator owned raises the next one's price; a bulk buy is the sum of that geometric series.
func cost(item: Dictionary, amount: int) -> float:
	if not is_generator(item):
		return item.cost
	return unit_cost(item) * (pow(PRICE_GROWTH, amount) - 1) / (PRICE_GROWTH - 1)


func max_affordable(item: Dictionary) -> int:
	if not is_generator(item):
		return 1 if can_buy(item, 1) else 0
	return floori(log(coins * (PRICE_GROWTH - 1) / unit_cost(item) + 1) / log(PRICE_GROWTH))


func can_buy(item: Dictionary, amount: int) -> bool:
	if not is_generator(item) and count(item) > 0:
		return false
	return coins >= cost(item, amount)


func buy(item: Dictionary, amount: int) -> void:
	coins -= cost(item, amount)
	owned[item.id] = count(item) + amount
	match item.kind:
		"tier_up":
			tier += 1
		"ending":
			ended = true


## What each copy of a generator currently adds, milestones and boosts included.
func output_each(generator: Dictionary) -> float:
	var unit := Content.REACH_UNIT if generator.kind == "reach" else Content.TRADE_UNIT
	return (unit
		* pow(Content.GEN_OUTPUT_STEP, generator.rank)
		* pow(Content.TIER_OUTPUT_STEP, generator.tier)
		* milestone_multiplier(count(generator))
		* boost_multiplier(generator))


func boost_multiplier(generator: Dictionary) -> float:
	var multiplier := 1.0
	for item in Content.ITEMS:
		if (item.kind == "boost" and count(item) > 0
				and item.boosts in [generator.kind, "both"]
				and item.scope in [generator.tier, -1]):
			multiplier *= item.amount
	return multiplier


func ships_per_minute() -> float:
	return _generated("reach")


func ship_income_per_second() -> float:
	return ships_per_minute() / 60 * COIN_PER_SHIP


func trade_per_second() -> float:
	return _generated("trade")


# Generators add income independently. Multiplying ships by coin per ship made each purchase
# raise the worth of every other, and the whole story ended within an afternoon.
func income_per_second() -> float:
	return ship_income_per_second() + trade_per_second()


func flash_value() -> float:
	return (1 + income_per_second() * FLASH_SHARE_OF_INCOME) * _product_of("tap")


func storm_multiplier() -> float:
	return _product_of("storm")


func away_cap_seconds() -> float:
	return _best_of("away_cap", BASE_AWAY_CAP_HOURS) * 3600


func away_rate() -> float:
	return _best_of("away_rate", BASE_AWAY_RATE)


func earn(amount: float) -> void:
	coins += amount
	lifetime_coins += amount


func advance(seconds: float) -> void:
	earn(income_per_second() * seconds)


## Credits time spent away at the away rate, up to the away cap. Returns the seconds credited.
func away(seconds: float) -> float:
	var credited := minf(seconds, away_cap_seconds())
	earn(income_per_second() * credited * away_rate())
	return credited


func to_dict() -> Dictionary:
	return {
		"coins": coins,
		"lifetime_coins": lifetime_coins,
		"tier": tier,
		"ended": ended,
		"owned": owned,
		"revealed": revealed.keys(),
	}


static func from_dict(data: Dictionary) -> Economy:
	var economy := Economy.new()
	economy.coins = data.coins
	economy.lifetime_coins = data.lifetime_coins
	economy.tier = int(data.tier)
	economy.ended = data.ended
	for id in data.owned:
		economy.owned[id] = int(data.owned[id])
	for id in data.revealed:
		economy.revealed[id] = true
	return economy


func _generated(kind: String) -> float:
	var total := 0.0
	for item in Content.ITEMS:
		if item.kind == kind:
			total += count(item) * output_each(item)
	return total


func _product_of(kind: String) -> float:
	var product := 1.0
	for item in Content.ITEMS:
		if item.kind == kind and count(item) > 0:
			product *= item.amount
	return product


func _best_of(kind: String, base: float) -> float:
	var best := base
	for item in Content.ITEMS:
		if item.kind == kind and count(item) > 0:
			best = maxf(best, item.amount)
	return best
