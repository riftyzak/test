--!strict
-- Builds the room order for one run. Pure logic (no Roblox APIs) so it can be tested with Lune.

local RoomPicker = {}

export type RoomDef = { id: string, tier: string }
export type Slot = { id: string, kind: "start" | "room" | "safe" | "boss", difficulty: "normal" | "hard" }

-- A Roblox Random, or any object with NextInteger (tests use a fake one).
type Rng = any

local function takeRandom(candidates: { RoomDef }, rng: Rng): RoomDef?
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

-- Hard slots can use a real hard room, or any medium room on its hard version.
local function fitsSlot(room: RoomDef, slotTier: string): boolean
	if slotTier == "hard" then
		return room.tier == "hard" or room.tier == "medium"
	end
	return room.tier == slotTier
end

function RoomPicker.pick(
	rooms: { RoomDef },
	plan: { string },
	rng: Rng,
	names: { start: string, safe: string, boss: string }
): { Slot }
	local used: { [string]: boolean } = {}
	local result: { Slot } = { { id = names.start, kind = "start", difficulty = "normal" } }

	for _, slotTier in plan do
		if slotTier == "safe" then
			table.insert(result, { id = names.safe, kind = "safe", difficulty = "normal" })
			continue
		end

		local candidates = {}
		for _, room in rooms do
			if not used[room.id] and fitsSlot(room, slotTier) then
				table.insert(candidates, room)
			end
		end

		local chosen = takeRandom(candidates, rng)
		if not chosen then
			error(`RoomPicker: no unused room left for a "{slotTier}" slot; add rooms or shorten Config.RunPlan`)
		end
		used[chosen.id] = true
		table.insert(result, {
			id = chosen.id,
			kind = "room",
			difficulty = if slotTier == "hard" then "hard" else "normal",
		})
	end

	table.insert(result, { id = names.boss, kind = "boss", difficulty = "normal" })
	return result
end

return RoomPicker
