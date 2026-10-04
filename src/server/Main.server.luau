--!strict
-- Entry point. The same place is both the lobby and the run server:
-- a reserved server (created by the Toy Box elevator) runs an escape, everything else is the lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local Lobby = require(script.Parent.Lobby)
local PlayerData = require(script.Parent.PlayerData)
local Purchases = require(script.Parent.Purchases)
local Remotes = require(script.Parent.Remotes)
local RunManager = require(script.Parent.RunManager)

local isRunServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
-- In Studio, set the workspace attribute StudioRunMode = true to test a run with placeholder rooms.
if RunService:IsStudio() and workspace:GetAttribute("StudioRunMode") == true then
	isRunServer = true
end

PlayerData.start()
Purchases.start()

-- Speed perk (bought with coins only).
local function applyPerks(player: Player, character: Model)
	local data = PlayerData.waitFor(player)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if data and humanoid then
		humanoid.WalkSpeed = 16 * (1 + Economy.perkValue(Config.Perks, "speed", data.perks.speed))
	end
	-- TODO: rescue perk (faster BagRelease) and squeaky toy (stun) once those rooms have hold/use interactions.
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		applyPerks(player, character)
	end)
	if player.Character then
		task.spawn(applyPerks, player, player.Character)
	end

	-- Daily streak is claimed in the lobby only.
	if not isRunServer then
		local data = PlayerData.waitFor(player)
		if data then
			local count, reward =
				Economy.claimStreak(Config.StreakRewards, data.streak.lastDay, data.streak.count, os.time() // 86400)
			if reward then
				data.streak = { lastDay = os.time() // 86400, count = count }
				PlayerData.addCoins(player, reward)
				player:SetAttribute("StreakDay", count)
			end
		end
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end

-- Ping wheel: validate, rate-limit, then show it to everyone.
local PING_CHOICES = { "Here", "Go", "Help", "Wait" }
local lastPing: { [Player]: number } = {}
Remotes.get("Ping").OnServerEvent:Connect(function(player, choice)
	if typeof(choice) ~= "string" or not table.find(PING_CHOICES, choice) then
		return
	end
	local now = os.clock()
	if now - (lastPing[player] or 0) < 1 then
		return
	end
	lastPing[player] = now
	Remotes.get("Ping"):FireAllClients(player, choice)
end)
Players.PlayerRemoving:Connect(function(player)
	lastPing[player] = nil
end)

if isRunServer then
	RunManager.start()
else
	Lobby.start()
end
