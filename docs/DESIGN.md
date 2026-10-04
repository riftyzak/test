# VACUUM IS COMING! 🧸 [CO-OP] — Game Design Doc

> 1–4 toys escape a messy bedroom while **Mr. Suckles**, a dumb, dramatic vacuum with googly eyes, chases them.
> Every run picks rooms in a different order.

## 1. Goals
- **Make money without being aggressive or "slop".** Anything that affects gameplay is earned with coins only, never bought with Robux. No paid random items (loot boxes). No fake scarcity.
- **Replayability:** a randomized co-op run lasts about 10–12 minutes.
- **Audience:** kids 9–13, mobile first. Prices a parent would approve without a second thought.
- **Scope:** one first-time solo dev (with Claude writing the code), 10–20 hours a week, launch in about 6–8 weeks.

## 2. Why this concept (research summary)
- Tycoons are crowded, and dead clones are common (e.g. a toilet factory tycoon with 0 visitors). The tycoons that win add a twist, like *Steal a Brainrot* or *Grow a Garden*.
- Co-op **horror** roguelites (DOORS-style) are full of cheap clones. **Non-horror** co-op roguelites have far fewer competitors.
- "Escape the toy ___ obby" games exist in bulk, but they are linear 30-stage obbies. Ours has to *look* different: a villain, co-op, and a different layout every run. Never call it "Escape ___ Obby".
- "Escape" games are hot in 2026 (*Escape Tsunami for Brainrots*).

## 3. Run structure
```
Toy Box start (tutorial) → easy → easy → 🧦 safe → medium → medium → 🧦 safe → hard → hard → 🔌 PlugBoss
```
- Each room appears at most once per run.
- **Hard slots** can hold a real hard room, **or any medium room on its hard version**. That gives 7 options at launch, so runs don't always end the same way.
- **Hard version (launch):** the vacuum enters sooner, there are extra hazards, and there are fewer checkpoints or less time. New hard *layouts* come later, 1–2 per update.
- **Safe room (Sock Drawer):** the vacuum can't enter. Spend coins on one-run boosts here, free bagged friends, and catch your breath.
- **Mr. Suckles** enters each room after a delay, follows a path laid out in that room, and speeds up the longer the team takes.

### Getting caught
- Caught toys go into the **vacuum bag**. A teammate reaching the room's **BagRelease** frees everyone who's bagged.
- The run ends only if **everyone** is bagged. Then revives are offered.

### Revives
| Source | Limit |
|---|---|
| Free revive | 1 per run (solo: 2); +1 after 25 completed runs (earned perk) |
| Paid (R$19) **or** ad **or** daily token | Max **1 per run combined**, only after the free revives are used, no countdown pressure |
| Daily revive token | For players who can't see ads (e.g. under 13) |

### Solo play
Every teamwork room has a solo version, set by the room's `PlayerCount` attribute: push a toy weight onto the pressure plate, set the flashlight on the floor, and the boss pull just takes longer.

### Talking to teammates
Most 9–13 players don't have voice chat (it needs age verification). Instead there's a **ping wheel**: Here / Go / Help / Wait, shown above your head. The flashlight and crayon rooms depend on it.

## 4. Rooms

### Launch pool (10)
| Tier | Room | Idea |
|---|---|---|
| Easy | Trampoline Bed | Bounce across the bed while pillows fly |
| Easy | Marble Run | Ride a giant marble track; a breather/spectacle room |
| Easy | Jack-in-the-Box Field | Boxes launch you; learn the rhythm |
| Medium | Lego Minefield | Find the safe path through painful bricks |
| Medium | Two-Player Bridges | One holds the plate while the others cross, then swap |
| Medium | Crayon Art Door | Each player has one color; match the picture |
| Medium | Fan Tunnel | Block the wind with a book shield |
| Medium | Puzzle Cube Lock | Carry shapes into a giant shape sorter |
| Hard | Bookshelf Climb | Vertical climb, vacuum sucking from below |
| Hard | Under the Bed | Pitch black; the flashlight holder guides the team |

### Fixed rooms
- **Toy Box Start:** a 30-second play-to-learn tutorial (jump, carry, rescue) with a slow practice vacuum. Skipped after your first run.
- **Sock Drawer:** the safe room.
- **PlugBoss:** a 3-phase boss. ① Dodge the sucking hose. ② Climb the whipping cord. ③ Everyone grabs the plug and pulls together.

### Update roadmap (one every 2–3 weeks)
1. Domino Chain
2. Toy Soldier Patrol (stealth, second enemy type)
3. RC Car Race
4. Train Set
5. Paper Airplane Flight
6. **Lobby Toy Room** (decorate your corner): a big update about 2 months after launch

Each update also adds 1–2 new hard layouts.

## 5. Economy

### Coins per run
- +10 per room cleared, +5 per teammate you rescue, +40 for beating the boss.
- A full win pays about **100–120**. A wipe partway through still pays something (about 40 by room 4).

**Bonuses** (each is a share of the base; they add, never multiply):
- VIP: +25%
- Ad doubler: +100%. VIPs get it without watching an ad.
- Players who can't see ads get a flat +20 instead.

So a VIP win pays about 225.

**Daily streak:** a 7-day track (25 / 30 / 40 / 50 / 60 / 75 / 150). It resets if a day is missed. *This was a deliberate choice. If players or parents push back, soften it to a streak that never resets; that's a one-line change.*

### Perks (coins only, never Robux)
| Perk | Levels | Cost |
|---|---|---|
| Run speed | +5% / +8% / +10% | 300 / 550 / 850 |
| Faster rescue | 20% / 30% / 40% | 450 / 750 / 1,100 |
| Squeaky toy (stuns vacuum, 1 use per run) | 3s / 4s / 5s | 600 / 950 / 1,300 |
| Extra free revive | — | Unlocked after 25 completed runs |

Maxing everything costs 6,850 coins, about **62 full wins** for a free player.

**Other coin sinks:**
- One-run safe-room boosts: 50–100
- Emotes and trails: 500–1,500
- Earnable skins (about half of all skins): 1,500–4,000
- Lobby toy room: later update

### Robux shop
| Item | Price | Type |
|---|---|---|
| Premium skins (animated/glowing) | R$49–149 | Developer products, permanent ownership. Nothing is sold for both coins and Robux |
| VIP subscription | R$99/month | Gold tag, +25% coins, skip ads, monthly exclusive skin, lobby lounge |
| Party Pass | R$149 once | Game pass: private runs, choose the room set |
| Revive | R$19 | Developer product, see the revive limits |

**Rewarded ads** may only be shown to players aged **13+**, and the publishing account must be 13+ with 2-step verification and a verified ID. Everyone else gets the daily token and the flat bonus. [Roblox docs](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)

**Payouts:** 1 Robux earned is about **$0.0038** through DevEx (cashing out), or $0.0054 for spending by age-verified US players aged 18+. Roblox also pays Creator Rewards based on how long people play.

## 6. Presentation
- **Name:** VACUUM IS COMING! 🧸 [CO-OP]. ⚠️ Search the exact name on Roblox before publishing.
- **Icon (512×512, designed at 1024):** Mr. Suckles' face filling the frame, googly eyes, nozzle open, a tiny toy flying in. It must read at 150px.
- **Thumbnails (1920×1080; Roblox auto-tests them):**
  1. Door hold
  2. Rescue from the bag
  3. Pulling the plug
- **Art:** real game scenes posed in Studio, with effects added in Photopea. No AI art; it looks cheap to players and can be flagged as misleading.
- **Audio:** free music and sound effects from the Roblox library, plus a recorded goofy voice for Mr. Suckles ("I'M HUNGRYYY").
- **Servers:** lobbies of 20 players; each run happens on its own private server.

## 7. Launch plan & targets
1. Playtest with 10–20 kids or friends and fix whatever confuses them.
2. Message 20–50 small Roblox YouTubers (1k–50k subscribers).
3. Run Sponsored ads: **$30–50** over 3–5 days (about $10 a day).
4. **Targets:**
   - At least 3–4% of people who see the icon click it
   - The average visit lasts 10+ minutes
   - At least 15% of new players come back the next day

   If all three are met, spend more on ads. If one is missed, fix it first.

## 8. Technical notes
- One place does both jobs: a **reserved server** (made by the Toy Box elevator) runs an escape, and every other server is the lobby.
- All rewards and purchases are granted **on the server**. `ProcessReceipt` is idempotent: it stores purchase IDs so a purchase is never granted twice.
- Player data uses DataStore `UpdateAsync` with a session lock, so data can't be duplicated or lost during the lobby↔run teleport.
- All tunable numbers are in `src/shared/Config.luau`.
- The room order and economy rules are pure modules, covered by `tests/run.luau`.

## 9. Open TODOs
- [ ] Build the 10 launch rooms, the start room, the Sock Drawer and the boss in Studio (placeholders are used until then)
- [ ] Rescue perk (hold-to-release) and squeaky toy interactions
- [ ] Rewarded ads integration (`src/server/Ads.luau`)
- [ ] Shop UI (skins, perks, VIP) and the safe-room boost shop
- [ ] Party Pass: private lobby elevator
- [ ] Earnable skins, emotes and trails data
- [ ] Mr. Suckles model and voice lines
