-- Tests for the pure game logic. Run with: lune run tests/run
local Config = require("../src/shared/Config")
local RoomPicker = require("../src/shared/RoomPicker")
local Economy = require("../src/shared/Economy")

local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print(`FAIL {name}: {err}`)
	end
end
local function eq(a: any, b: any, msg: string?)
	if a ~= b then
		error(`{msg or "expected equal"}: got {tostring(a)}, want {tostring(b)}`, 2)
	end
end

local fakeRng = {
	NextInteger = function(_self, min: number, max: number)
		return math.random(min, max)
	end,
}
local names = { start = Config.StartRoom, safe = Config.SafeRoom, boss = Config.BossRoom }
local tierOf = {}
for _, r in Config.Rooms do
	tierOf[r.id] = r.tier
end

test("run has start, 8 slots, boss in the planned order", function()
	for seed = 1, 500 do
		math.randomseed(seed)
		local run = RoomPicker.pick(Config.Rooms, Config.RunPlan, fakeRng, names)
		eq(#run, #Config.RunPlan + 2, "length")
		eq(run[1].kind, "start")
		eq(run[#run].kind, "boss")
		for i, slotTier in Config.RunPlan do
			local slot = run[i + 1]
			if slotTier == "safe" then
				eq(slot.kind, "safe")
			elseif slotTier == "hard" then
				eq(slot.difficulty, "hard")
				assert(tierOf[slot.id] == "hard" or tierOf[slot.id] == "medium", "hard slot tier")
			else
				eq(tierOf[slot.id], slotTier, "slot tier")
				eq(slot.difficulty, "normal")
			end
		end
	end
end)

test("no room appears twice in a run", function()
	for seed = 1, 500 do
		math.randomseed(seed)
		local seen = {}
		for _, slot in RoomPicker.pick(Config.Rooms, Config.RunPlan, fakeRng, names) do
			if slot.kind == "room" then
				assert(not seen[slot.id], `duplicate {slot.id}`)
				seen[slot.id] = true
			end
		end
	end
end)

test("hard slots draw from more than the two hard rooms", function()
	local hardIds = {}
	for seed = 1, 500 do
		math.randomseed(seed)
		local run = RoomPicker.pick(Config.Rooms, Config.RunPlan, fakeRng, names)
		hardIds[run[#run - 1].id] = true
	end
	local n = 0
	for _ in hardIds do
		n += 1
	end
	assert(n > 2, `only {n} distinct rooms seen in hard slots`)
end)

test("picker errors clearly when the pool is too small", function()
	local ok, err = pcall(RoomPicker.pick, { { id = "A", tier = "easy" } }, { "easy", "easy" }, fakeRng, names)
	assert(not ok and string.find(tostring(err), "no unused room"), "expected pool error")
end)

local C = Config.Coins
test("payout: free player, ads skipped, full win", function()
	local stats = { roomsCleared = 6, rescues = 2, bossBeaten = true }
	eq(Economy.runPayout(C, stats, { isVip = false, adEligible = true, watchedAd = false }), 110)
end)
test("payout: ad doubler adds base once", function()
	local stats = { roomsCleared = 6, rescues = 2, bossBeaten = true }
	eq(Economy.runPayout(C, stats, { isVip = false, adEligible = true, watchedAd = true }), 220)
end)
test("payout: VIP gets +25% and doubler without ad (added, not multiplied)", function()
	local stats = { roomsCleared = 6, rescues = 0, bossBeaten = true } -- base 100
	eq(Economy.runPayout(C, stats, { isVip = true, adEligible = false, watchedAd = false }), 225)
end)
test("payout: ad-ineligible non-VIP gets the flat bonus", function()
	local stats = { roomsCleared = 4, rescues = 0, bossBeaten = false } -- base 40
	eq(Economy.runPayout(C, stats, { isVip = false, adEligible = false, watchedAd = false }), 60)
end)

test("perks: costs, max level, values", function()
	eq(Economy.nextPerkCost(Config.Perks, "speed", 0), 300)
	eq(Economy.nextPerkCost(Config.Perks, "speed", 3), nil)
	eq(Economy.perkValue(Config.Perks, "squeaky", 2), 4)
	eq(Economy.perkValue(Config.Perks, "rescue", 0), 0)
end)

test("perks: maxing everything takes ~60 full free wins", function()
	local total = 0
	for _, perk in Config.Perks do
		for _, cost in perk.costs do
			total += cost
		end
	end
	local runs = total / 110
	assert(runs >= 55 and runs <= 70, `{runs} runs to max perks`)
end)

local R = Config.StreakRewards
test("streak: first claim, continue, same day, reset", function()
	local c, reward = Economy.claimStreak(R, nil, 0, 100)
	eq(c, 1)
	eq(reward, 25)
	c, reward = Economy.claimStreak(R, 100, c, 101)
	eq(c, 2)
	eq(reward, 30)
	local c2, again = Economy.claimStreak(R, 101, c, 101)
	eq(c2, 2)
	eq(again, nil)
	c, reward = Economy.claimStreak(R, 101, 2, 105)
	eq(c, 1, "missed days reset")
	eq(reward, 25)
end)
test("streak: day 8 wraps to the day-1 reward", function()
	local _, reward = Economy.claimStreak(R, 7, 7, 8)
	eq(reward, 25)
end)

test("free revives: solo, group, and the 25-run perk", function()
	eq(Economy.freeRevives(Config.Revives, 1, 0), 2)
	eq(Economy.freeRevives(Config.Revives, 3, 0), 1)
	eq(Economy.freeRevives(Config.Revives, 3, 25), 2)
end)

print(`{passed} passed, {failed} failed`)
if failed > 0 then
	error("tests failed")
end
