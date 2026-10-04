--!strict
-- Loads/saves each player's data with a session lock, so the same account can't be
-- loaded on two servers at once (e.g. lobby + run server during a teleport).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STORE_NAME = "PlayerData_v1"
local LOCK_EXPIRY = 30 * 60 -- a crashed server's lock is ignored after 30 min
local AUTOSAVE_SECONDS = 120
local MAX_RECEIPTS = 50

export type Data = {
	coins: number,
	perks: { [string]: number },
	runsCompleted: number,
	ownedSkins: { [string]: boolean },
	equippedSkin: string?,
	streak: { lastDay: number?, count: number },
	reviveToken: { day: number?, used: boolean },
	reviveCredits: number, -- paid revives bought when they couldn't be used right away
	receipts: { string }, -- recent PurchaseIds, for idempotent ProcessReceipt
}

local function defaultData(): Data
	return {
		coins = 0,
		perks = { speed = 0, rescue = 0, squeaky = 0 },
		runsCompleted = 0,
		ownedSkins = {},
		equippedSkin = nil,
		streak = { lastDay = nil, count = 0 },
		reviveToken = { day = nil, used = false },
		reviveCredits = 0,
		receipts = {},
	}
end

-- Fill in fields added in later versions so old saves keep working.
local function reconcile(data: any): Data
	local template = defaultData() :: any
	for key, value in template do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local PlayerData = {}
local loaded: { [Player]: Data } = {}

local store: DataStore? = nil
local ok = pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
if not ok then
	warn("PlayerData: DataStores unavailable (in Studio, enable 'Studio Access to API Services'). Data won't save.")
end

local function key(player: Player): string
	return `u_{player.UserId}`
end

local function retry<T>(fn: () -> T, attempts: number): (boolean, T | string)
	local lastErr: any
	for i = 1, attempts do
		local success, result = pcall(fn)
		if success then
			return true, result
		end
		lastErr = result
		task.wait(2 ^ i)
	end
	return false, tostring(lastErr)
end

local function load(player: Player)
	if not store then
		loaded[player] = defaultData()
		return
	end

	local jobId = game.JobId
	for _ = 1, 6 do
		local lockedElsewhere = false
		local success, result = retry(function()
			return (store :: DataStore):UpdateAsync(key(player), function(old)
				old = old or { data = defaultData() }
				local lock = old.lock
				if lock and lock.jobId ~= jobId and os.time() - lock.time < LOCK_EXPIRY then
					lockedElsewhere = true
					return nil -- don't write
				end
				old.lock = { jobId = jobId, time = os.time() }
				return old
			end)
		end, 3)

		if not player.Parent then
			return
		end
		if not success then
			player:Kick("Couldn't load your data, please rejoin.")
			return
		end
		if not lockedElsewhere then
			loaded[player] = reconcile((result :: any).data)
			return
		end
		-- Previous server is still saving (normal right after a teleport); wait and retry.
		task.wait(3)
	end
	player:Kick("Your data is still open on another server. Please rejoin in a minute.")
end

local function save(player: Player, release: boolean)
	local data = loaded[player]
	if not data or not store then
		return
	end
	local jobId = game.JobId
	retry(function()
		return (store :: DataStore):UpdateAsync(key(player), function(old)
			old = old or {}
			if old.lock and old.lock.jobId ~= jobId and os.time() - old.lock.time < LOCK_EXPIRY then
				return nil -- another server owns this data now; never overwrite it
			end
			old.data = data
			old.lock = if release then nil else { jobId = jobId, time = os.time() }
			return old
		end)
	end, 3)
end

function PlayerData.get(player: Player): Data?
	return loaded[player]
end

-- Yields until the player's data is loaded (or they leave).
function PlayerData.waitFor(player: Player): Data?
	while player.Parent and not loaded[player] do
		task.wait(0.1)
	end
	return loaded[player]
end

function PlayerData.saveNow(player: Player)
	save(player, false)
end

function PlayerData.addCoins(player: Player, amount: number)
	local data = loaded[player]
	if data then
		data.coins += amount
		player:SetAttribute("Coins", data.coins)
	end
end

function PlayerData.hasReceipt(data: Data, purchaseId: string): boolean
	return table.find(data.receipts, purchaseId) ~= nil
end

function PlayerData.addReceipt(data: Data, purchaseId: string)
	table.insert(data.receipts, purchaseId)
	while #data.receipts > MAX_RECEIPTS do
		table.remove(data.receipts, 1)
	end
end

function PlayerData.start()
	local function onJoin(player: Player)
		load(player)
		local data = loaded[player]
		if data then
			player:SetAttribute("Coins", data.coins)
		end
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
		loaded[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in loaded do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player in loaded do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		while pending > 0 do
			task.wait()
		end
	end)
end

return PlayerData
