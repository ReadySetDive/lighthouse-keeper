class_name Content
## Every purchasable, tier and line of story. Balancing the game means editing this file;
## economy.gd turns these rows into prices and output.

# Generator prices and output come from one formula (Economy.unit_cost, Economy.output_each).
# The finish date is very sensitive to these; re-run sim.gd after touching any of them.
const GEN_BASE_COST := 10.0
const GEN_COST_STEP := 7.5 # each generator rank costs this much more than the last...
const GEN_OUTPUT_STEP := 5.5 # ...and makes this much more
const TIER_COST_STEP := 400.0
const TIER_OUTPUT_STEP := 40.0
const REACH_UNIT := 12.0 # ships per minute from one rank-0 reach generator
const TRADE_UNIT := 0.2 # coin per second from one rank-0 trade generator; matches 12 ships/min

const TIERS := [
	{
		"name": "DARK COAST",
		"tab": "COAST",
		"target_width": 160,
	},
	{
		"name": "FISHING HAMLET",
		"tab": "HAMLET",
		"target_width": 200,
		"letter_from": "FROM THE SHIPPING OFFICE",
		"letter": "Keeper. Masters report a light on the north coast where none has burned in years. Families are moving to your shore. They will need your light.",
	},
	{
		"name": "PORT TOWN",
		"tab": "PORT",
		"target_width": 240,
		"letter_from": "FROM THE HAMLET COUNCIL",
		"letter": "The charter is granted. We are a town now. Ships come for trade, not shelter. Keep the light. We will keep the rest.",
	},
]

const ENDING_TITLE := "THE HARBOUR FESTIVAL"
const ENDING_LETTER := "The whole town is lit tonight. A child asks what the lighthouse is for. 'So people come home,' you say.\n\nTHE END.\n\nThe light keeps turning."

const OPENING_LINES := [
	"You inherit a dead lighthouse.",
	"Tap the sea to flash the lamp.",
]

const AMBIENT_LINES := [
	[
		"The wind leans on the tower.",
		"Gulls sleep on the gallery rail.",
		"Fog on the water. Keep the light.",
		"A ship's bell, far out. Then nothing.",
		"The sea is loud tonight.",
		"Rain needles the glass.",
		"You trim the wick. It is enough.",
	],
	[
		"Children race the beam along the beach.",
		"Fishers mend nets under your light.",
		"Someone leaves bread at your door.",
		"The jetty creaks in the swell.",
		"A fisher waves from the shore.",
		"Gulls fight over the herring.",
	],
	[
		"Bells from the customs house.",
		"A liner passes, lit like a town.",
		"The quay smells of coal and oranges.",
		"Sailors toast the light from the bar.",
		"The tug whistles at you.",
		"The town no longer fears the dark.",
	],
]

# Kinds:
#   reach, value  generators, bought many times: ships per minute, or coin per ship
#   boost         one-off multiplier on generators: `boosts` reach/value/both, `scope` a tier or -1 for all
#   tap, storm    one-off multipliers on flashing the lamp and on storm rescues
#   away_cap, away_rate  one-off: hours of away time credited, and the share of income it earns
#   tier_up, ending      one-off: opens the next tier, or finishes the story
# Within a tier, rows are in price order; the shop shows them in this order.
const ITEMS := [
	{"id": "wick", "tier": 0, "kind": "reach", "rank": 0, "name": "Oil Wick", "line": "The wick takes. A captain exhales."},
	{"id": "hand_bell", "tier": 0, "kind": "tap", "amount": 3.0, "cost": 50.0, "name": "Hand Bell", "desc": "X3 FLASH", "line": "You ring at passing hulls. They hear you."},
	{"id": "polish", "tier": 0, "kind": "trade", "rank": 1, "name": "Brass Polish", "line": "The brass shines. So, briefly, do you."},
	{"id": "spare_wicks", "tier": 0, "kind": "boost", "boosts": "reach", "scope": 0, "amount": 2.0, "cost": 400.0, "name": "Spare Wicks", "desc": "X2 SHIPS FROM THE COAST", "line": "A drawer full of wicks. Never dark again."},
	{"id": "clockwork", "tier": 0, "kind": "reach", "rank": 2, "name": "Clockwork Turner", "line": "The lamp turns itself. You sleep in shifts."},
	{"id": "logbook", "tier": 0, "kind": "away_cap", "amount": 4.0, "cost": 1500.0, "name": "Ship's Logbook", "desc": "AWAY TIME COUNTS UP TO 4H", "line": "You log the night. Ships pass as you sleep."},
	{"id": "mirror", "tier": 0, "kind": "boost", "boosts": "trade", "scope": 0, "amount": 2.0, "cost": 3000.0, "name": "Silvered Mirror", "desc": "X2 COIN FROM THE COAST", "line": "The mirror doubles the light. And the dust."},
	{"id": "fresnel", "tier": 0, "kind": "trade", "rank": 3, "name": "Fresnel Lens", "line": "Good glass. Your light reaches the reef."},
	{"id": "storm_glass", "tier": 0, "kind": "storm", "amount": 2.0, "cost": 6000.0, "name": "Storm Glass", "desc": "X2 STORM RESCUES", "line": "The glass clouds before the weather turns."},
	{"id": "kettle", "tier": 0, "kind": "away_rate", "amount": 0.65, "cost": 12000.0, "name": "Night Kettle", "desc": "AWAY TIME EARNS 65%", "line": "Tea at midnight. The watch goes easier."},
	{"id": "letter", "tier": 0, "kind": "tier_up", "cost": 25000.0, "name": "Letter to the Office", "desc": "OPENS THE FISHING HAMLET", "line": "You seal a letter to the Shipping Office."},
	{"id": "gallery", "tier": 0, "kind": "reach", "rank": 4, "name": "Taller Gallery", "line": "Another ring of stone. The sea shrinks."},
	{"id": "flags", "tier": 0, "kind": "trade", "rank": 5, "name": "Signal Flags", "line": "Flags on the rail. Ships answer in colour."},
	{"id": "foghorn", "tier": 0, "kind": "reach", "rank": 6, "name": "Foghorn", "line": "The horn bellows. Gulls take it personally."},

	{"id": "hut", "tier": 1, "kind": "reach", "rank": 0, "name": "Fisher's Hut", "line": "A hut on the shore. Its owner nods at you."},
	{"id": "net_loft", "tier": 1, "kind": "trade", "rank": 1, "name": "Net Loft", "line": "Nets hang to dry like grey washing."},
	{"id": "jetty", "tier": 1, "kind": "reach", "rank": 2, "name": "Jetty", "line": "A jetty. Boats come in instead of past."},
	{"id": "tarred_hulls", "tier": 1, "kind": "boost", "boosts": "reach", "scope": 1, "amount": 2.0, "cost": 300000.0, "name": "Tarred Hulls", "desc": "X2 SHIPS FROM THE HAMLET", "line": "Tarred hulls slip past the rocks unharmed."},
	{"id": "watchman", "tier": 1, "kind": "away_cap", "amount": 8.0, "cost": 2000000.0, "name": "Night Watchman", "desc": "AWAY TIME COUNTS UP TO 8H", "line": "A watchman takes the small hours."},
	{"id": "smokehouse", "tier": 1, "kind": "trade", "rank": 3, "name": "Smokehouse", "line": "The smokehouse smells of herring and money."},
	{"id": "salt_cellars", "tier": 1, "kind": "boost", "boosts": "trade", "scope": 1, "amount": 2.0, "cost": 20000000.0, "name": "Salt Cellars", "desc": "X2 COIN FROM THE HAMLET", "line": "Salted fish keeps. So does trade."},
	{"id": "lifeboat", "tier": 1, "kind": "reach", "rank": 4, "name": "Lifeboat Crew", "line": "A lifeboat crew. They argue about oars."},
	{"id": "old_notes", "tier": 1, "kind": "boost", "boosts": "both", "scope": 0, "amount": 2.0, "cost": 500000000.0, "name": "Old Keeper's Notes", "desc": "X2 EVERYTHING ON THE COAST", "line": "The old keeper's notes. He knew every rock."},
	{"id": "rockets", "tier": 1, "kind": "storm", "amount": 2.0, "cost": 5e9, "name": "Coastguard Rockets", "desc": "X2 STORM RESCUES", "line": "Coastguard rockets. Red stars in the rain."},
	{"id": "oil_depot", "tier": 1, "kind": "away_rate", "amount": 0.8, "cost": 5e10, "name": "Oil Depot", "desc": "AWAY TIME EARNS 80%", "line": "Oil by the barrel. The light never thins."},
	{"id": "market", "tier": 1, "kind": "trade", "rank": 5, "name": "Market Stall", "line": "A stall sells you your own fish."},
	{"id": "charter", "tier": 1, "kind": "tier_up", "cost": 1e12, "name": "Town Charter", "desc": "OPENS THE PORT TOWN", "line": "The hamlet votes. It wants to be a town."},
	{"id": "second_light", "tier": 1, "kind": "reach", "rank": 6, "name": "Second Light", "line": "A second light to the north. Two eyes now."},

	{"id": "breakwater", "tier": 2, "kind": "reach", "rank": 0, "name": "Breakwater", "line": "A breakwater. The harbour stops shivering."},
	{"id": "customs", "tier": 2, "kind": "trade", "rank": 1, "name": "Customs House", "line": "Customs House. Ships pay to see your light."},
	{"id": "tug", "tier": 2, "kind": "reach", "rank": 2, "name": "Steam Tug", "line": "A steam tug coughs its way around the bay."},
	{"id": "bank", "tier": 2, "kind": "trade", "rank": 3, "name": "Merchant Bank", "line": "A bank. They ask you to sign for the light."},
	{"id": "dry_dock", "tier": 2, "kind": "reach", "rank": 4, "name": "Dry Dock", "line": "A dry dock. Ships come here to be mended."},
	{"id": "dredged", "tier": 2, "kind": "boost", "boosts": "reach", "scope": 2, "amount": 2.0, "cost": 5e11, "name": "Dredged Channel", "desc": "X2 SHIPS FROM THE PORT", "line": "They dredge the channel. Deep hulls come."},
	{"id": "promenade", "tier": 2, "kind": "tap", "amount": 5.0, "cost": 1e12, "name": "Promenade", "desc": "X5 FLASH", "line": "A promenade. Couples walk to see the beam."},
	{"id": "gas_lamps", "tier": 2, "kind": "trade", "rank": 5, "name": "Gas Lamps", "line": "Windows light along the quay. You did that."},
	{"id": "harbour_master", "tier": 2, "kind": "away_cap", "amount": 12.0, "cost": 2e12, "name": "Harbour Master", "desc": "AWAY TIME COUNTS UP TO 12H", "line": "A harbour master. He salutes the tower."},
	{"id": "trade_charter", "tier": 2, "kind": "boost", "boosts": "trade", "scope": 2, "amount": 2.0, "cost": 5e12, "name": "Trade Charters", "desc": "X2 COIN FROM THE PORT", "line": "Trade charters. Every flag on the sea."},
	{"id": "electric", "tier": 2, "kind": "reach", "rank": 6, "name": "Electric Lamp", "line": "Electric light. The beam goes white."},
	{"id": "coal_bunker", "tier": 2, "kind": "away_rate", "amount": 1.0, "cost": 1e13, "name": "Coal Bunker", "desc": "AWAY TIME EARNS 100%", "line": "Coal for winter. No night goes unlit."},
	{"id": "telegraph", "tier": 2, "kind": "boost", "boosts": "both", "scope": -1, "amount": 2.0, "cost": 2e13, "name": "Telegraph Office", "desc": "X2 EVERYTHING EVERYWHERE", "line": "The telegraph ticks. The world knows you."},
	{"id": "festival", "tier": 2, "kind": "ending", "cost": 1.5e14, "name": "Harbour Festival", "desc": "THE END OF THE STORY", "line": "The town plans a festival for its keeper."},
]
