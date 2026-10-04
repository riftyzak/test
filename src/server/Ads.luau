--!strict
-- Rewarded video ads (coin doubler + ad revive).
--
-- Roblox rules: rewarded ads may only be offered to players aged 13+, and the
-- publishing account must be 13+, have 2-step verification and a verified ID.
-- https://create.roblox.com/docs/production/promotion/rewarded-video-ads
--
-- Until ads are wired up, everyone counts as NOT ad-eligible. That is the safe
-- default: those players get the daily free revive token and the flat coin bonus
-- instead, which is exactly what under-13 players get anyway.

local Ads = {}

function Ads.isEligible(_player: Player): boolean
	-- TODO(ads): replace with Roblox's ad-availability check once the account is eligible.
	return false
end

return Ads
