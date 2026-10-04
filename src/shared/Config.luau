--!strict
-- All tunable numbers live here. Change values, not code.
-- See docs/DESIGN.md for the reasoning behind each number.

local Config = {}

-- Fill these in after creating them on the Creator Hub (Monetization tab).
-- 0 / "" means "not set up yet": the matching feature stays switched off.
Config.Products = {
	ReviveDevProduct = 0, -- R$19, max 1 paid/ad/token revive per run
	PartyPassGamePass = 0, -- R$149, private runs
	VipSubscriptionId = "", -- R$99/month, looks like "EXP-123456789"
	-- Premium skins are developer products: [productId] = skinId
	PremiumSkins = {} :: { [number]: string },
}

Config.Lobby = {
	MaxPartySize = 4,
	ElevatorWaitSeconds = 15,
}

-- A run: fixed start -> slots -> fixed boss. "safe" = Sock Drawer safe room.
Config.RunPlan = { "easy", "easy", "safe", "medium", "medium", "safe", "hard", "hard" }
Config.StartRoom = "ToyBoxStart"
Config.SafeRoom = "SockDrawer"
Config.BossRoom = "PlugBoss"

export type RoomDef = { id: string, tier: string } -- tier: "easy" | "medium" | "hard"

-- Launch pool (10). Update rooms get appended here as they ship.
Config.Rooms = {
	{ id = "TrampolineBed", tier = "easy" },
	{ id = "MarbleRun", tier = "easy" },
	{ id = "JackInTheBox", tier = "easy" },
	{ id = "LegoMinefield", tier = "medium" },
	{ id = "TwoPlayerBridges", tier = "medium" },
	{ id = "CrayonDoor", tier = "medium" },
	{ id = "FanTunnel", tier = "medium" },
	{ id = "PuzzleCube", tier = "medium" },
	{ id = "BookshelfClimb", tier = "hard" },
	{ id = "UnderTheBed", tier = "hard" },
} :: { RoomDef }

Config.Vacuum = {
	EnterDelay = { normal = 8, hard = 4 }, -- seconds after a room starts
	StartSpeed = 10, -- studs/second
	Acceleration = 0.4, -- extra studs/second gained every second
	MaxSpeed = 22,
	CatchRadius = 5,
}

Config.Revives = {
	FreePerRun = 1,
	SoloFreePerRun = 2, -- solo players get 2 self-revives
	ExtraFreeAfterRuns = 25, -- earned perk: +1 free revive
	MaxBoughtPerRun = 1, -- paid OR ad OR daily token, combined
	DecisionSeconds = 12,
}

Config.Coins = {
	PerRoomCleared = 10,
	PerRescue = 5,
	BossBonus = 40,
	VipBonus = 0.25, -- +25% of base, added (not multiplied)
	AdDoubler = 1.0, -- +100% of base; VIPs get it without watching
	NoAdsFlatBonus = 20, -- players who can't see ads (e.g. under 13)
}

-- 7-day streak, resets if a day is missed (design decision, see DESIGN.md).
Config.StreakRewards = { 25, 30, 40, 50, 60, 75, 150 }

-- Perks: bought with coins only, never Robux. ~60 runs to max for a free player.
Config.Perks = {
	speed = { costs = { 300, 550, 850 }, values = { 0.05, 0.08, 0.10 } },
	rescue = { costs = { 450, 750, 1100 }, values = { 0.20, 0.30, 0.40 } },
	squeaky = { costs = { 600, 950, 1300 }, values = { 3, 4, 5 } },
}

return Config
