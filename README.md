# VACUUM IS COMING! 🧸 [CO-OP]

A co-op Roblox roguelite: 1–4 toys escape a messy bedroom while Mr. Suckles the vacuum chases them.
The full plan is in **[docs/DESIGN.md](docs/DESIGN.md)**.

## What's in here
```
default.project.json   Rojo project: maps the src/ folders into Roblox
src/shared/            ReplicatedStorage.Shared
  Config.luau          ALL tunable numbers (prices, coins, rooms, product IDs)
  RoomPicker.luau      picks the random room order for a run
  Economy.luau         coin payout, perks, streak, revive rules
src/server/            ServerScriptService.Server
  Main.server.luau     entry point: lobby or run server?
  Lobby.luau           Toy Box elevator -> private run server
  RunManager.luau      builds rooms, moves Mr. Suckles, bag/rescue/revive, pays coins
  PlayerData.luau      saving with a session lock
  Purchases.luau       Robux purchases (server-checked), VIP, Party Pass
  Ads.luau             rewarded ads (off until your account is eligible)
  Remotes.luau         client <-> server events
src/client/
  Main.client.luau     coin counter, ping wheel, revive prompt, end-of-run result
tests/run.luau         tests for RoomPicker + Economy (run with Lune)
```

## Fastest way to try it (no Rojo needed)
1. Install **Roblox Studio** from https://create.roblox.com.
2. Download **`dist/VacuumIsComing.rbxl`**: on GitHub, open the file and click the download button.
3. Double-click it to open it in Studio, then press **Play**.

The place already contains every script plus the lobby (baseplate, spawn and the yellow Toy Box zone). It starts in **test-run mode**: you run through grey placeholder rooms while the red ball (Mr. Suckles) chases you.
- Yellow pad = goal
- Blue pad = frees bagged friends

To see the lobby instead: select **Workspace** → Attributes → untick **StudioRunMode**.

The file is a snapshot. It's rebuilt with `rojo build place.project.json -o dist/VacuumIsComing.rbxl`. For day-to-day work, use the Rojo setup below so code changes sync live.

## First-time setup with live sync (about 20 minutes)

### 1. Install the tools
1. **Roblox Studio:** download it from https://create.roblox.com and log in.
2. **Rojo** (syncs these files into Studio). The easiest route is VS Code:
   1. Install [VS Code](https://code.visualstudio.com).
   2. Install the **"Rojo – Roblox Studio Sync"** extension.
   3. Open this folder in VS Code.
   4. Run the command palette → **"Rojo: Open menu"** → install Rojo and the Studio plugin when it asks.

   Without VS Code: download `rojo` 7.4+ from https://github.com/rojo-rbx/rojo/releases, then run `rojo plugin install`.
3. Get the code onto your PC. Either clone it with git, or on GitHub open branch `claude/modest-hypatia-gg2ojf` → **Code** → **Download ZIP**.

### 2. Connect Studio
1. In Studio, create a new **Baseplate** and **save/publish it** (File → Publish to Roblox).
2. In this folder, run `rojo serve` (or use VS Code's Rojo menu → *Start server*).
3. In Studio: **Plugins** tab → **Rojo** → **Connect**. The scripts appear under ServerScriptService, ReplicatedStorage and StarterPlayerScripts.

From then on, edits to files in `src/` show up in Studio straight away.

### 3. Set up the place in Studio
1. **Lobby elevator:**
   1. In Workspace, create a **Folder** named `Lobby`.
   2. Inside it, create a **Model** named `ToyBox`.
   3. Inside that, create a **Part** named `Zone` (Anchored ✔, CanCollide ✘, Transparency 0.5, about 12×1×12).

   Players standing on it get sent on a run.
2. Put a **SpawnLocation** in the lobby.
3. **Game Settings → Security → Enable Studio Access to API Services** ✔. Without it, saving data doesn't work in Studio.
4. **Game Settings → Places → Max Players: 20.**

### 4. Test a run in Studio
Teleports don't work in Studio, so there's a test switch:
1. Select **Workspace** → Properties → **Add Attribute** → name `StudioRunMode`, type Boolean, ticked ✔.
2. Press **Play**. You'll run through grey **placeholder rooms**:
   - Yellow pad = goal
   - Blue pad = frees bagged friends
   - Red ball = Mr. Suckles
3. Untick the attribute to test the lobby again.

## Building real rooms
1. In **ServerStorage**, create a Folder named `Rooms`.
2. Build each room as a **Model** named exactly like its id in `Config.luau` (e.g. `LegoMinefield`, `ToyBoxStart`, `SockDrawer`, `PlugBoss`).
3. Inside each room, add these Parts (they can be invisible, with CanCollide off):
   - `Entrance`: where players arrive. The room is lined up so this sits on the previous room's Exit.
   - `Exit`: where the next room attaches.
   - `Goal`: touching it clears the room. In PlugBoss, this is the plug.
   - `BagRelease` (optional): touching it frees bagged teammates.
   - A Folder `VacuumPath` with Parts named `1`, `2`, `3`…: Mr. Suckles' route (optional).
4. Room scripts can read the model's attributes `Difficulty` ("normal"/"hard"), `PlayerCount` and `Active` to switch on hard mode and solo versions.

Optional: put a Model named `Vacuum` in ServerStorage to replace the red ball.

Any room that isn't built yet automatically uses a placeholder, so you can build them one at a time.

## Selling things
1. Create the products in Creator Hub → your experience → **Monetization**:
   - Revive developer product: R$19
   - Party Pass game pass: R$149
   - VIP subscription: R$99/month
   - Premium skins: developer products
2. Paste their IDs into `Config.Products` in `src/shared/Config.luau`. Anything left at 0 stays switched off.

Purchases are granted on the server only, and never twice for the same purchase.

## Running the tests
Install [Lune](https://github.com/lune-org/lune/releases), then:
```
lune run tests/run
```
