# Idle Game Research for Lighthouse Keeper

**About the evidence.** The 15 reports underneath this are thin. Most researchers ran 2–4 web searches and read only the result snippets. Only two pages were fully read: Pecorella's "The Math of Idle Games, Part I" and Eric Guan's design-principles post. Three follow-up investigations filled gaps:
- an economy simulation with no web sources;
- a Godot rendering search (3 searches, no pages fetched, nothing tested on a device);
- a Godot web audio check (the export docs were fetched).

Below, **(unverified)** means the researcher wrote it from memory or took it from a low-quality snippet. **(sourced)** means it came from a wiki, a fetched article or a cited review. **(sim)** means it is output from our own toy Python model, not data from any real game. Numbers marked as my own proposals are design recommendations, not findings.

---

## 1. Executive summary

- **Something worth buying is always close.** Every successful game prices the next purchase so it is seconds away early on and minutes to hours away later. The tools are a geometric cost curve (`base × r^owned`, with r between 1.07 and 1.15) and production that grows roughly linearly per unit (Pecorella; Cookie Clicker wiki; Clicker Heroes wiki).
- **Two constants decide how long the game is.** In our simulation, a 5% change in the per-copy price growth moved the finish date by about 40%. A 5% change in the generator cost ratio moved it by about 20%. Tier gates, apart from the first, barely mattered (sim). Freeze these two constants first.
- **The screen is the progress bar.** Egg, Inc.'s farm, Idle Miner's growing shaft, Cell to Singularity's diorama and Candy Box's growing page all show progress without a number. Critics of number-only games (Kittens, NGU, Antimatter Dimensions) make the opposite point: players cannot appreciate what they have achieved.
- **Reveal one step ahead.** Show what the player can use now, plus the next one or two items as silhouettes or "???". Never show a wall of 40 items (Cookie Clicker (unverified); Antimatter Dimensions help page (sourced); A Dark Room).
- **New systems arrive just as the old one goes stale.** Paperclips, A Dark Room and Antimatter Dimensions each add a new bottleneck or layer at a plateau. Paperclips makes the player "invest in a breakthrough" to move on (Wikipedia, sourced).
- **Automation is the first big reward.** AdCap's managers, Idle Miner's managers and Tap Titans 2's skill trees turn active play into passive income. The moment the game starts playing itself feels like a promotion.
- **Returning should feel like a celebration.** Pecorella (GDC 2015, sourced) treats the check-in as the core moment, followed by a "welcome back" payout. Offline progress is capped but generous, and the best games let the player buy a higher cap (Egg, Inc. silos; Idle Slayer). In the sim, the offline cap and rate drove pacing far more than active play did.
- **Active play is optional.** Golden cookies and Egg, Inc. drones reward attention. A player who misses them does not fall behind.
- **Mechanics, text and visuals tell the story together.** The Grandmapocalypse, Paperclips' stages and A Dark Room's log tell stories through state changes and one-line text, never cutscenes.
- **Finite arcs earn goodwill.** Spaceplan and A Dark Room have endings and were praised for them (TouchArcade, sourced). The genre's most common criticism is "pointless treadmill" (Gamezebo on Egg, Inc.; Cookie Clicker critiques).
- **Keep the player out of a spreadsheet.** Opaque prestige maths, dense UI and dependence on calculators are the most frequent criticisms (Clicker Heroes, Realm Grinder, Melvor, NGU, Antimatter Dimensions).
- **The web platform sets hard limits.** A full-screen pixel buffer needs an integer scale chosen for each device, so the tier widths can only be approximate. Synthesised audio has to be baked into samples when the game loads, because live generation is not supported in Godot's default web audio mode (Godot docs, sourced).

---

## 2. What each studied game teaches

**Cookie Clicker (Orteil, 2013).** About 20 buildings share one price formula, `base × 1.15^owned` (wiki.gg, sourced; the Classic version used 1.1). Upgrades for each building appear at count thresholds. The Grandmapocalypse darkens the visuals, the news ticker and the golden-cookie odds in stages. Wrath cookies are 33% of golden cookies at stage 1 and 100% at stage 3 (guide snippets). **Borrow:** a single table-driven cost formula, and a news ticker that reacts to game state and carries jokes and story almost for free.

**AdVenture Capitalist / Communist (Hyper Hippo, 2014).** Ten businesses run on cycle timers. A manager, bought once, automates a business, including while offline (sourced). Owning 25, 50, 100… of a business doubles its output (unverified, though Pecorella confirms ×2 at 25 and 50). The Lemonade Stand's price growth is 1.07 (Pecorella, sourced). **Borrow:** managers as the automation milestone, doublings at owned-count milestones, and x1/x10/x100/Max buy buttons.

**Clicker Heroes / Tap Titans 2.** Hero cost is `floor(base × 1.07^level)`, which is about 5.4× per 25 levels (wiki, sourced). Tapping dominates early, then hero damage overtakes it. Tap Titans 2's skill trees exist "to eventually not have to tap" (sourced). Players rely on external calculators to time prestige (sourced). **Borrow:** let tapping fade out gracefully, and show an in-game "reward if you reset now" preview.

**Egg, Inc. (Auxbrain).** The farm fills with chickens, hen houses and trucks. An egg-tier ladder always shows what comes next. Silos are an offline cap the player can buy (sourced snippets). Drones are optional tap targets. **Borrow:** named tiers that re-theme the scene, and a visible offline cap the player can buy up.

**Idle Miner Tycoon (Kolibri, 2016).** A vertical stack of shafts feeds an elevator and a warehouse, and throughput is limited by the slowest stage. Managers earn offline (sourced). Each new mine is a new scene. **Borrow:** a bottleneck the player must rebalance (light reach vs. harbour capacity), and one new scene per tier.

**Cell to Singularity (Computer Lunch).** Every purchase places something in a growing diorama. A second currency, Ideas, appears at a story milestone (sourced). Each node carries a short educational blurb (unverified). **Borrow:** every purchase places a sprite, and a second currency arrives with a story beat.

**Universal Paperclips (Lantz, 2017).** Each stage swaps in a different bottleneck: money, then compute, then matter. Projects are the reveal mechanism, each with a one-line description. Lantz planned a weekend's work and spent about 9 months (sourced). **Borrow:** each tier changes what the constraint is, not just its size, and the project text is the narrative.

**A Dark Room (Townsend, 2013).** It opens with one button, "stoke fire", and the interface grows as mechanics appear (sourced). Terse log lines ("the wind howls") carry the mood. Critics found the start too empty and the late game a standard RPG. **Borrow:** a one-tap opening and a log-line voice.

**Candy Box (aniwey, 2013), all unverified.** The page itself grows with ASCII art as the player buys. **Borrow:** surprise panels, where the reveal is the reward.

**Spaceplan (Hollands, 2017).** It has a definite ending, reached in "a couple of days" of check-ins (TouchArcade) or about 9 hours (one user). Reviewers liked the finite arc. AppUnwrapper said the story beats were spaced too far apart for the waiting (sourced). **Borrow:** a real ending, with story beats never further apart than the waits.

**Kittens Game.** The web of resources widens step by step, and storage caps force the player to build warehouses (unverified). Its contributor docs say to reuse existing resources rather than add new ones (sourced). **Borrow:** caps as pacing, and restraint about adding resources.

**Antimatter Dimensions.** Nested prestige layers each re-skin "generator feeds generator". The Reality update (Dec 2022) added 7 Celestials (sourced). Reviews complain of a slow start and a slow end (sourced, player sentiment). **Borrow:** each layer reuses the same mechanic with a twist, plus the help page's rule of showing only the next unlock.

**NGU Idle.** A dozen parallel systems and no tutorial. It is widely criticised for revealing too much too fast (unverified). **Borrow:** the warning. Do not do this on a 240 px screen.

**Melvor Idle.** Offline play is the headline feature: the same rules are simulated, with a cap of about 24 h (unofficial guide), and a "welcome back" summary follows. It has about 15k Steam reviews, roughly 90% positive (third-party). **Borrow:** treat the welcome-back summary as a feature, not an afterthought.

**Realm Grinder.** Three reset layers: abdicate, reincarnate, ascend (sourced). The faction chosen at reset reshapes the next run. **Borrow:** if there is a prestige, make it a choice, not just +x%.

**Idle Slayer / Leaf Blower Revolution.** Both use pixel art. In Idle Slayer, offline bonuses are a stat the player can buy (sourced). In Leaf Blower Revolution, each content wave changes the look of the screen, and gem rewards slow sharply above e7 (player posts). **Borrow:** offline earnings as an upgrade path, and a visual change with each wave.

---

## 3. Design principles

**1. One cost formula, many data rows.**
*Evidence:* Cookie Clicker uses `base × 1.15^owned` for every building (wiki, sourced). Clicker Heroes uses `floor(base × 1.07^level)` (wiki, sourced). Pecorella gives closed forms for bulk cost and the maximum affordable (sourced).
*Apply:* Every purchasable item is one row: `id, tier, base_cost, growth, base_output, effect, flavour`. Use one cost function. Use the closed-form `cost(n)` and `max_affordable()` for Buy Max, with no loops.

**2. The scene is the progress bar.**
*Evidence:* Egg, Inc.'s farm, Idle Miner's shaft and Cell to Singularity's diorama. The "can't see progress" criticism lands on Kittens, NGU and Antimatter Dimensions.
*Apply:* Every one of the 40+ items has a footprint in the scene: a sprite, a longer beam, a moored boat, or a count of lit windows driven by total purchases.

**3. Reveal one step ahead.**
*Evidence:* Cookie Clicker silhouettes (unverified). Antimatter Dimensions' "next piece(s)" rule (sourced). A Dark Room's growing interface (sourced).
*Apply:* Show the buyable items plus one or two silhouettes marked "?". Reveal an item's name and price when the player has about 50% of its cost. Whole tier tabs appear only at tier-up.

**4. Milestones break up the exponential.**
*Evidence:* AdCap doubles output at 25 and 50 owned (Pecorella, sourced), with further thresholds (unverified). Clicker Heroes doubles every 25 levels (unverified). Guan says changes of about ×1.2 are noticeable and +1% is not (designer claim).
*Apply:* ×2 at 10, 25, 50 and 100 owned for repeatable items (the sim used these). Show the next milestone beside the buy button. No upgrade smaller than ×1.2.

**5. Automation is the first promotion.**
*Evidence:* AdCap and Idle Miner managers. Tap Titans 2's skill trees exist to remove tapping (sourced). One designer says the first automation should come within about 3 minutes (snippet).
*Apply:* "Keeper's assistant"-style purchases automate guiding ships in calm weather. Storm taps remain a bonus. Offline income counts only automated output.

**6. Active play is a bonus, not an obligation.**
*Evidence:* Golden cookies and Egg, Inc. drones. Cookie Clicker is criticised because golden-cookie hunting conflicts with idling. In the sim, ×2 storms for 3 minutes per session changed the finish date by under 0.3 day.
*Apply:* A storm is a short tap event that multiplies the idle rate. A missed storm costs nothing. Treat storms as flavour and feedback, not a pacing lever. Taps should matter less by tier 3 (the Clicker Heroes pattern).

**7. Each tier changes the constraint, the scene and the text at once.**
*Evidence:* Paperclips' stages change the bottleneck and the story together. Idle Miner and Leaf Blower Revolution re-theme the scene for each area.
*Apply:* Tier 1 is limited by light reach (coin only), tier 2 by harbour and crew capacity, tier 3 by town prosperity. Each tier-up also brings a resolution step, new palette colours and a letter. Caveat: in the sim, reach and harbour caps never slowed the late game, because coin per ship grows without bound (see §4). If these constraints should bind, they must cap coin per ship as well.

**8. Returning is the reward moment.**
*Evidence:* Pecorella (sourced). Melvor's summary. Egg, Inc.'s silos. Uoidle ignores absences under 60 s (sourced). In the sim, offline cap and rate purchases explained most of the gap between players who check in 3 times a day and those who check in 5 times.
*Apply:* A 3–4 line welcome-back card in the keeper's voice with one-tap collect, and a visible offline cap the player can upgrade.

**9. Finish the story.**
*Evidence:* Spaceplan and A Dark Room were praised for finite arcs (sourced). "Pointless" is the standard idle criticism.
*Apply:* Tier 3 ends with the lit port town, an epilogue letter and an optional "keep playing" or new-coast mode.

**10. Expose the maths.**
*Evidence:* Clicker Heroes players needed external calculators (sourced). Realm Grinder and Melvor are criticised as opaque and dense.
*Apply:* Every upgrade states its effect ("+12% coin per ship"). Income per second is always visible. Any reset shows its reward before the player confirms.

---

## 4. Numbers to design with

### Cost growth per unit

| Source | r | Status |
|---|---|---|
| AdCap Lemonade Stand | 1.07 | sourced (Pecorella) |
| Clicker Heroes heroes | 1.07 | sourced (wiki) |
| Cookie Clicker buildings | 1.15 (Classic 1.10) | sourced (wiki) |
| Guan's example | 1.15 cost / 1.10 output | designer claim |
| Kittens, Realm Grinder | 1.07–1.15 | unverified |
| Our pacing sim | 1.15 for every item | sim |

**Conflict:** the AdCap report recalls r *falling* from about 1.15 (cheap businesses) to 1.07 (expensive ones). The economy-math lens recalls it *rising* from 1.07 to 1.15. Both are unverified. Pecorella's verified 1.07 belongs to AdCap's *first* business, which fits the rising version.

**Recommendation:** use a single growth value of 1.15 for every generator and freeze it. The 10-day result from the sim is calibrated to 1.15. The sim's elasticity of about 8 means the earlier proposal of 1.07 / 1.10 / 1.13 per tier would shorten the game drastically unless k is re-tuned. For small capped items such as offline-cap upgrades, where only 5–10 levels exist, use r = 1.15–1.3.

### Economy model (sim)

**Model.** Income per tier = min(ships/min, harbour cap) × coin per ship × 2^(upgrades owned).
- Even-numbered generators add ships/min (lamp reach). Odd-numbered ones add coin per ship.
- Generator i costs `10 × r_tier^tier × k^i × 1.15^owned`.
- Output grows by `q^i` per generator, and value grows by `ro^tier` per tier.
- Milestones double output at 10, 25, 50 and 100 owned.

**Player model.** The simulated player buys the item that pays for itself fastest, among those within 3× of the best payback. The first session lasts 30 min. Later check-ins last 8 min each, spread evenly between 08:00 and 22:00.

**Constants that hit the pacing targets:**
- k = 7.5 (cost ratio between generators)
- q = 2.2 (output ratio, so k/q ≈ 3.4)
- r_tier = 60 (cost growth per tier)
- ro = 2.3 (value growth per tier, so r_tier/ro ≈ 26)
- upgrade cost multiplier = 6
- price growth per copy owned = 1.15
- tier 1→2 gate ≈ 70 coin

| Player | Tier 2 | Tier 3 | Finish |
|---|---|---|---|
| 3 check-ins/day | 21 min | day 2.0 | day 10.0 |
| 5 check-ins/day | 21 min | day 1.15 | day 9.0 |
| 3 check-ins/day, no storms | about 24 min | day 2.0 | day 10.3 |

**What controls what.**
- **Tier 2 timing depends on gate 1 alone.** A gate of about 70 coin (roughly the price of the third generator) lands at 21 min. At about 230 coin the gate misses the first session, so tier 2 slips to the next check-in, around 7 h later. Set gate 1 as an absolute coin value, not as a multiple of k.
- **Tier 3 timing depends mostly on k and the offline rules.**
- **Finish depends on k, price growth, q, r_tier and ro.** Gate 2 and the lifetime-earnings floor moved finish by 0.00 day.

**Sensitivity (3 check-ins a day, each constant ±5%):**

| Constant | Finish at −5% / +5% |
|---|---|
| price growth per copy | day 6.0 / 13.6 |
| k | day 8.0 / 12.3 |
| q | day 11.3 / 9.0 |
| r_tier | day 9.6 / 11.0 |
| ro | day 10.6 / 9.6 |

**Cliff check.** The economy-math lens earlier reported a cliff: finish jumped from day 11 to day 86 when k moved from 7.5 to 7.6. The sim did not reproduce it. Scanning k from 7.0 to 8.0 gave a smooth day 7.3 to day 13.6, about +0.6 day per +0.1 in k. A real cliff would need a hard wall, such as a gate that opens only when one specific item is bought.

**Why q differs from the lens.** The lens used an output ratio of 5.5. The sim splits output between reach and coin per ship and adds milestones, so the two q values are not comparable.

**Recommendations.**
- Aim for a finish within ±25% of the target day. Hitting ±5% is unrealistic.
- Purchases happen only at check-ins, so results move in steps of 0.3–0.6 day. Scan each constant continuously rather than trusting single runs.
- Re-run the sim (`sim2.py`, `base.py`, `sens.py` in the scratchpad) against the real 42-row table, because upgrades and offline items were placeholders.
- Keep building the headless simulator in GDScript as planned.

### Suggested 42-item shape (proposal, used by the sim)

Each tier has 14 items: 7 repeatable generators, 5 one-off upgrades (multipliers and automation) and 2 offline items (cap and rate). Tier 2 and 3 items stay hidden until tier-up.

### Unlock cadence

| Phase | Target | Source |
|---|---|---|
| First purchase | 10–20 s | Cookie Clicker 15-cookie Cursor (unverified); rule of thumb |
| Second purchase | under ~45 s | pacing lens (unverified) |
| First 5 min | 5–10 purchases | pacing lens (unverified) |
| First automation | about 3 min | one designer (snippet) |
| Mid game | an unlock every 5–15 min | unverified |
| Tier 2 | 21–29 min | sim |

**Conflict on tier timing:** the pacing lens proposed tier 2 at 8–12 min and tier 3 at 1–2 h. The economy-math lens targeted 14–21 days for the whole ladder.

**Recommendation:**
- Tier 2 inside the first session, at about 20–30 min. This is achievable (sim), and Guan says first sessions run 15–60 min.
- Tier 3 on day 2–4. A player who checks in 5 times a day arrives at day 1.15 in the sim, so raise gate 2 if that is too early.
- The ending at about day 9–10 for a player who checks in 3 times a day. The two player types finish about a day apart.
- Spaceplan's "couple of days" shows that a shorter arc is also acceptable.

### First prestige

Sources put the first prestige anywhere from 15–60 min (one developer reports 25–35 min, another article says 45–90 min) to Cookie Clicker's first ascension, which takes many hours (prestige level 365–440, guide snippets). Several reports (economy-math, narrative-idles, Idle Miner) advise **no hard prestige in v1**, because the tiers already provide the arc.

**Recommendation:** make tier-ups a non-destructive "prestige-lite". Add an optional "New Season" only after the ending. If it is added:
- gain = `floor(sqrt(lifetime_coin / K))` (AdCap-style; the n² angel pattern is the lens's inference),
- the gain is spent on 2–3 path choices (the Realm Grinder lesson),
- the scene never visually drops back a tier.

### Offline rules

| Game | Rule | Status |
|---|---|---|
| Uoidle | 100% rate, 8 h cap, ignores absences under 60 s | sourced |
| Egg, Inc. | 50% (standard permit), 1 h per silo, research +6 min per level | sourced snippet, undated |
| Melvor | full simulation, about 24 h | unofficial guide |
| Leaf Blower Revolution | 3 days, 7 with a paid upgrade | player comment |

**Conflict:** the Egg, Inc. report recalls about 3 min per silo, while the offline lens's snippet says 1 h. Trust the snippet, but note it is undated.

**Recommendation (the sim's ladder):**
- Formula: `min(elapsed, cap) × income_per_s × offline_rate`, one closed-form step.
- Six offline purchases, two per tier. The cap rises 2 → 3 → 4 → 6 → 8 → 10 → 12 h and the rate rises 50% → 100%. By tier 3 this covers a night's sleep.
- Ignore gaps under 60 s. Clamp negative time gaps to 0.

### Session rhythm

- The first session lasts 15–60 min, then the player returns roughly hourly, then a few times a day (Guan, designer claim). Check-ins last 10 s–2 min (unverified).
- **Recommendation:** design for 3–5 check-ins a day. Every return should offer a decision (what to buy) and a payout, and about one return in three should find a storm waiting.

### Number formatting

Show exact numbers below 1,000, then K/M/B/T with 3 significant digits, then scientific notation above about 1e15. Keep every number within about 8 characters (several reports, unverified conventions). A ladder topping out around 3e19 fits comfortably in double-precision floats.

---

## 5. Story and tone

### Delivery mechanisms, cheapest first

1. **Rolling log:** 3 lines in the bottom strip, newest at the bottom, older lines fading out (A Dark Room). It reports ships passing, weather and the neighbours' doings.
2. **Reactive log pool:** 15–25 ambient lines per tier, each gated by game state (Cookie Clicker). A fan homage, Token Clicker, has 448 headlines, which shows how cheap each line is (secondary source).
3. **Item flavour:** one line per purchasable item, about 45 lines in all (Egg, Inc.; Cell to Singularity blurbs).
4. **Letters:** one full-screen moment per tier-up, 3–4 in total, kept in a journal the player can re-read (narrative lens proposal).
5. **Mechanics as story:** a Grandmapocalypse-style turn, such as storms that grow harsher as the coast grows richer, told only through state changes.

### Arc (narrative lens outline)

- **Dark Coast:** you inherit a dead lighthouse. You are alone and every ship matters. The first letter comes from the shipping office.
- **Fishing Hamlet:** you are no longer alone. Named neighbours (the baker, the bell-ringer) appear in the log without needing sprites.
- **Port Town:** the town no longer needs you but keeps your light burning. The final letter is a thank-you.
- **Optional epilogue:** the far horizon, lit by lights you inspired.

### Voice

Dry, kind and brief, in the second person. Use one narrator, write every line in one sitting, then cut each line by a third (narrative lens). Keep lines to 60 characters or fewer. The best draft lines:

- "The lamp catches. Somewhere out there, a captain exhales."
- "First ship past. She did not wave. They never do."
- "A storm builds. Your thumbs know what to do."
- "Smoke on the shore. A fisherman has built a hut. He nods at the light."
- "The fog bell rings. For once, you are not the loudest thing on the coast."
- "Windows light up along the quay. You did not light them. You did."
- "A second light, to the north. The coast has two eyes now."
- "A child asks what the lighthouse is for. 'So people come home,' you say."

**Offline card in voice:** "While you slept: 12 ships, 1 close call, 340 coin."

**Pacing warning:** Spaceplan's story beats were "too far apart" for the waiting (AppUnwrapper, sourced). Post a log line at least every few minutes of play, even when nothing unlocks.

---

## 6. Visual progression

### Tier-up changes (visual lens proposal, unverified)

| Tier | Target width | Colours | Scene |
|---|---|---|---|
| 1, Dark Coast | ~160 px | 8 | rock, lamp, fog, rare ships |
| 2, Fishing Hamlet | ~200 px | 12 (+grass, wood, warm window, moon/foam) | cottages, jetty, lifeboat, bell |
| 3, Port Town | ~240 px | 16 (+dusk purple, sunset pink, harbour green, white) | quay, second light, customs house, lit windows |

Other proposals were 120 → 180 → 240 px (Idle Miner/Cell report) and 4 → 8 → 12 colours (Melvor/Realm report).

The tier 1 palette from the visual lens is `#0b0d1a`, `#1b2340`, `#2f4a7a`, `#6a7a9a`, `#2b2b2b`, `#e8e0c8`, `#c8372d`, `#ffd96a`.

Rules:
- The beam and the windows are always the brightest colours, so the eye goes to what the player owns.
- The sky and sea stay dark and low in saturation.
- A 2×2 Bayer dither on the beam's falloff adds apparent shades without adding colours.

**Ceremony:** a 1–2 s fade to black and a single lamp flash, then the new resolution, palette and letter arrive together. The fade also hides the buffer reallocation.

### Filling the phone with clean pixels (rendering lens; searches only, untested)

**Fixed widths cannot work.** A fixed logical width of 200 on a 1080 px phone gives a 5.4× scale, and fractional scales make pixels uneven. Square pixels that also fill the screen need an integer scale k chosen per device, with the logical width set to `floor(physical_width / k)`. On a 1080-wide phone, k = 8, 6, 5 and 4 give widths of 135, 180, 216 and 270. A 1440-wide phone reaches 240 at k = 6.

**Define the tiers by target width and pick k per device.** Use `k = round(physical_width / target_width)`, so 160/200/240 become approximate.

**Setup:**
- Set the root stretch mode to `disabled` and the web export's Canvas Resize Policy to Adaptive.
- Set the default canvas texture filter to Nearest.
- Avoid `canvas_items` stretch with integer mode. It letterboxes and renders at native resolution, so it is not a low-res buffer.
- Avoid a TextureRect showing a viewport texture. One developer found it broke clicks.

```gdscript
extends SubViewportContainer
# Full rect, stretch = true; SubViewport > world. UI is a sibling layer.

var target_width := 180  # set per tier; tier-up assigns it and calls _fit_scale

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_scale)
	_fit_scale()

# An integer shrink keeps logical pixels square; the logical width follows the device.
func _fit_scale() -> void:
	stretch_shrink = maxi(1, roundi(get_viewport_rect().size.x / target_width))
```

`stretch_shrink` can change at runtime without a reload (unverified). After it changes, redraw the code-generated pixel art.

**Address bar.** Showing or hiding the browser's address bar changes the visible height by roughly 10–15 logical rows (estimate), so anchor the layout to the screen edges.

**Check on a real phone first.** Print `DisplayServer.window_get_size()` on Android Chrome and see whether it reports physical pixels (1080 wide) or CSS pixels (about 412). The k values for every tier depend on it.

### Layout for a portrait phone

- **Top 55–60%: the scene, in the pixel buffer.**
  - The sky takes about 20%, then the horizon, the sea and a cliff. The lighthouse sits about one-third in from the side so the beam sweeps across the screen. The town grows in the foreground strip.
  - Layers, back to front: stars, far sea, ships (slow parallax), the dithered beam cone, a scrolling near-sea wave layer, the coast and lighthouse, the town lights.
- **Bottom 40–45%: the UI, on a native-resolution layer** (a sibling CanvasLayer above the container; rendering lens recommendation). It holds:
  - a 3-line log;
  - a pinned "buy next" button;
  - a scrolling item list with tier tabs. Each row has a 16×16 icon, name, count, cost and next milestone, and the whole row is the tap target;
  - an x1 / x10 / Max toggle;
  - a rule that a drag of 8 px or more counts as a scroll, not a tap.

**Why a separate layer.** If the UI shared the buffer, the logical size of a touch target would change at every tier. 48 dp (the Android guideline, unverified) is about 21 logical px at k = 6 on a 1080 px phone, but about 32 at k = 4. *(I recalculated this; the rendering report's "7 px" assumes CSS-pixel units.)*

**Scaling the UI.** Draw the 5×7 pixel font, with its 6 px advance, at a fixed integer scale chosen per device so rows are at least 48 dp. Text columns and visible rows then stay constant across tiers. Purely decorative text, such as ship names and titles, can stay in the buffer.

**Feedback:**
- a floating "+N" per ship rather than a jittering total;
- costs shown green when affordable and dimmed when not, never signalled by colour alone;
- tabular digits.

---

## 7. Audio (Godot web, single-threaded)

**Live generation is out.** Since Godot 4.3, web exports default to **Sample** playback. The docs list these limits (sourced):
- no procedural audio generation;
- no AudioEffects;
- no reverb or doppler;
- unreliable positional audio.

That rules out AudioStreamGenerator. The docs do not name it, but it is the procedural case. Forcing **Stream** playback restores the features but adds latency, "especially when thread support is disabled" (sourced). One Godot 4.4.1 thread reports a generator crackling on Android web builds, with no fix found (snippet only).

**Bake every sound at load time** (from memory, unverified against 4.7):
- Build each sound as an `AudioStreamWAV`: 16-bit, mono, 22050 Hz, with samples written to a `PackedByteArray` via `encode_s16`.
- Generate the sounds in chunks across frames, behind the title screen.
- A 6 s loop takes about 264 KB.
- **Untested:** whether a runtime-created WAV is accepted by the Sample path. Test this on the target phone first.

Recipes, in one `SfxBaker` with a dictionary cache:
- **Coin:** two square tones a fifth apart (e.g. 988 → 1319 Hz), 0.15 s, exponential decay.
- **Horn:** a detuned low pair (~110/165 Hz), 1.2 s, slow attack, low-pass applied in the bake.
- **Fog bell:** inharmonic sine partials at roughly 1 : 2.76 : 5.4 : 8.9, each with its own decay, about 2 s (ratios unverified).
- **Storm and sea-wash:** low-passed noise with a slow LFO, looped for 4–8 s, plus thunder bursts. Make each loop seamless by using whole oscillator cycles or crossfading its ends, and set `loop_end` to the sample count.

**No effects at runtime.** Do all filtering and tails in the bake. Express storm intensity by crossfading pre-baked calm, storm and thunder layers with `volume_db` tweens on separate players.

**Unlocking the audio.**
- Chrome suspends the AudioContext until a user gesture. Make the title screen a "Tap to light the lamp" gate, start the ambient loop inside that tap, and put a mute toggle there.
- The welcome-back card should also wait for a tap, because contexts may re-suspend after the tab is backgrounded (unverified).
- Define audio buses in the editor, not in code. One silent-audio thread was fixed that way (snippet).

**Voices and latency.**
- `max_polyphony` defaults to 1 (unverified), so set about 6 on the coin player. Keep the total under about 8–16 voices (a guess).
- Use non-positional players.
- Expected latency is 20–100 ms+ (unverified), which is fine for these sounds.

---

## 8. Saves (Godot web on Android Chrome)

### What the reference games do (all unverified)

Cookie Clicker, Antimatter Dimensions and Kittens Game keep the save in localStorage, plus a Base64 export string the player copies and pastes. Autosave runs every 30–60 s. Players treat the export code as the real backup.

### Storage facts

- On the web, Godot's `user://` is backed by IndexedDB (Godot 4.1 docs, sourced). It needs cookies and site data to be allowed, and private browsing blocks it. `OS.is_userfs_persistent()` can return false positives (3.x docs, sourced).
- Under storage pressure, browsers evict the least-recently-used origin first. `navigator.storage.persist()` exempts the origin, but do not call it on page load (web.dev, sourced). Chrome grants persistence based on engagement or add-to-home-screen (a 2016 source, flagged as dated).
- Clearing site data wipes localStorage and IndexedDB together, so keeping both adds no redundancy (unverified).
- Writes to `user://` reach IndexedDB asynchronously. If the tab is killed right after a write, that write may be lost (unverified).

### The tunnel URL problem

Browser storage is scoped to the origin: scheme, host and port. Every new `trycloudflare.com` or ngrok hostname starts with a fresh, empty save. Mitigations, best first:

1. **Move to a stable origin before anyone plays seriously:** a named tunnel with a fixed hostname, GitHub Pages or itch.io. This is the only real fix.
2. **Make the export code the primary backup.** Put Import on the title screen. While hosting is unstable, nudge the player to "Back up your save" after every tier-up.
3. **Migration link (untested):** the old origin opens `newhost/#save=LK1:...`, and the new origin reads the fragment on load. Fragments never reach the server, but long codes may hit URL length limits.
4. Add to Home Screen helps the save survive eviction but does not help when the origin changes.

### Format (saves lens, adapted)

- **Fields:** `v` (int), `saved_at_unix`, `coins`, `lifetime_coins`, `tier`, `owned` (a map from stable string ID to count), story and journal line IDs, settings. Do not store derived values or art.
- **Encoding:** `JSON.stringify(dict).to_utf8_buffer()` → `.compress(FileAccess.COMPRESSION_DEFLATE)` → `Marshalls.raw_to_base64()`, prefixed with `LK1:` and carrying a CRC32. `decompress()` needs the output size, so either use `decompress_dynamic()` or store the length (my note; check against the docs).
- **Import:** reject a bad prefix, a bad CRC, a `v` newer than the build, NaN or negative values, each with a visible error. Do not silently repair, per the project's fail-loudly rule.
- **Migrations:** a chain of `migrate_N_to_N+1` functions. Missing IDs default to 0, so new purchasable items slot in.
- **Anti-cheat:** none. The CRC only catches truncated pastes.

### Cadence

- Save every 30 s, after each purchase, on tier-up, and when the page becomes hidden.
- On mobile, `visibilitychange` to hidden is the only reliable event; `beforeunload` is not (unverified). Hook it through `JavaScriptBridge`. Test whether Godot's own focus-out notification fires reliably on Android Chrome.
- Keep one backup slot. Write to a temp file, then rename it.
- Call `navigator.storage.persist()` once, after the first meaningful purchase.

### Sharing the code on a phone

Show the code in a read-only selectable field with three buttons:
- **Copy:** `DisplayServer.clipboard_set`, falling back to `navigator.clipboard.writeText`.
- **Share:** `navigator.share`, which needs HTTPS.
- **Download:** a Blob `.txt` file.

Import uses a paste field plus a Paste button. All of these must be called directly inside the button handler, because they need a user gesture (unverified).

### Offline on load

Compute `elapsed = clamp(now − saved_at, 0, cap)` and apply it once, in closed form. Single-threaded WASM would freeze on a tick-by-tick catch-up loop. Imported codes apply their own timestamp, still capped.

---

## 9. Pitfalls from the genre

- **Treadmill with no decisions.** Cookie Clicker can be solved, and AdCap is "deliberately shallow". Counter this with milestones that shift the best buy and a different constraint in each tier.
- **Large-number blindness** (AdCap): "after the thousandth zero nothing feels different". Counter it with visual footprints and a finite ladder.
- **Hypersensitive constants.** In the sim, a 5% change in price growth moved the finish by 40% (sim). Freeze price growth and k early, and always re-simulate after changing them.
- **Opaque maths and calculator dependence** (Clicker Heroes, Egg, Inc., Realm Grinder).
- **UI overload and too-fast reveal** (NGU, Melvor, Realm Grinder). On a 240 px screen this is fatal.
- **Too empty early** (A Dark Room critics). The first ship should arrive within seconds.
- **Story beats too sparse for the wait** (Spaceplan).
- **Active mechanics that punish idling** (golden-cookie hunting).
- **Stingy or miscalculated offline progress** loses players (guide, sourced in spirit), and so does a cap shorter than a night's sleep.
- **Late-game stall** (Leaf Blower Revolution above e7, AdCap, Antimatter Dimensions' slow end). End each tier before its curve flattens.
- **Mandatory or rote prestige** (AdCap). Resets that only add a multiplier become a chore.
- **Rehashed content** (AdCap's Moon and Mars, unverified). Each tier needs a new mechanic, not just bigger numbers.
- **Dark patterns** (Tap Titans 2, Idle Miner and Egg, Inc. monetisation): timers, ad-doubling, punishment for broken streaks. None apply here, so do not import them out of habit.
- **Scope creep** (Paperclips went from a weekend to nine months). Lock 42 items and 3 tiers early.

---

## 10. Open questions for the design phase

1. **Tier target widths.** Given that k is chosen per device, which target widths should the tiers aim for (e.g. ~160/200/240 or ~180/216/270)? Is a resolution step of about 1.2× per tier visible enough to feel like a reward?
2. **UI scale.** With the UI on a native layer, what integer scale per device keeps rows at 48 dp or more, and how many item rows are then visible?
3. **Tier gating.** Should gates use lifetime coin, ships guided, owning the previous tier's key item, or a mix? The pacing lens favours counts so players cannot skip ahead. The sim used coin gates and showed that gate 1 alone sets tier 2 timing.
4. **Arc length.** A weekend game like Spaceplan, or the sim's 9–10 days? This choice sets k and price growth.
5. **Real constraints.** Should the reach and harbour caps bind in the late game? In the sim they never did.
6. **Prestige.** Is it out of v1 entirely, or an optional post-ending "New Season" with path choices? Does anything carry over into it?
7. **Second resource.** Should tier 2 or 3 introduce one (reputation, trade), or should the game stay coin-only, following the Kittens contributors' restraint?
8. **Storms.** How often do they happen, does one wait for a returning player, and how many baked intensity layers are needed?
9. **Hosting.** Can a stable origin be secured before playtesting? If not, how aggressive should the backup nudge be?
10. **Things to verify on a real phone and in the docs before relying on them:**
    - Rendering: whether the canvas reports physical or CSS pixels; whether `stretch_shrink` changes at runtime without a hitch; how much the address bar changes the height.
    - Audio: whether a runtime-created `AudioStreamWAV` plays in Sample mode; how long baking takes; latency from tap to sound; re-unlocking audio after backgrounding.
    - Saves: Godot's web write flush and focus-out behaviour.
    - Constants from other games: Cookie Clicker base costs; the AdCap growth range and its direction; AdCap milestone counts; Egg, Inc. silo minutes.