--!strict
-- Coin, perk, streak and revive rules. Pure logic so it can be tested with Lune;
-- the caller passes in the Config table.

local Economy = {}

export type RunStats = { roomsCleared: number, rescues: number, bossBeaten: boolean }
export type Bonuses = { isVip: boolean, adEligible: boolean, watchedAd: boolean }

-- Bonuses are each a share of the base and are added, never multiplied together.
function Economy.runPayout(coins: any, stats: RunStats, bonuses: Bonuses): number
	local base = stats.roomsCleared * coins.PerRoomCleared + stats.rescues * coins.PerRescue
	if stats.bossBeaten then
		base += coins.BossBonus
	end

	local total = base
	if bonuses.isVip then
		total += math.floor(base * coins.VipBonus)
	end
	if bonuses.isVip or (bonuses.adEligible and bonuses.watchedAd) then
		total += math.floor(base * coins.AdDoubler)
	elseif not bonuses.adEligible then
		total += coins.NoAdsFlatBonus
	end
	return total
end

-- Returns the cost of the next level, or nil when maxed.
function Economy.nextPerkCost(perks: any, perkId: string, currentLevel: number): number?
	local perk = perks[perkId]
	assert(perk, `unknown perk {perkId}`)
	return perk.costs[currentLevel + 1]
end

function Economy.perkValue(perks: any, perkId: string, level: number): number
	if level <= 0 then
		return 0
	end
	return perks[perkId].values[level]
end

-- today/lastDay are whole UTC day numbers (os.time() // 86400).
-- Returns the new streak count and the reward, or nil if already claimed today.
function Economy.claimStreak(rewards: { number }, lastDay: number?, count: number, today: number): (number, number?)
	if lastDay == today then
		return count, nil
	end
	local newCount = if lastDay == today - 1 then count + 1 else 1
	local index = ((newCount - 1) % #rewards) + 1
	return newCount, rewards[index]
end

-- How many free revives a team gets this run.
function Economy.freeRevives(revives: any, partySize: number, bestRunsCompleted: number): number
	local n = if partySize <= 1 then revives.SoloFreePerRun else revives.FreePerRun
	if bestRunsCompleted >= revives.ExtraFreeAfterRuns then
		n += 1
	end
	return n
end

return Economy
