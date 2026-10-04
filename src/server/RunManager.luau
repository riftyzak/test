--!strict
-- Runs one escape on a private server: builds the rooms, drives Mr. Suckles,
-- handles bagging/rescue/revives, pays coins, then sends everyone back to the lobby.
--
-- Room models live in ServerStorage.Rooms, named like the ids in Config.Rooms.
-- Each room model needs these BaseParts (anywhere inside it):
--   Entrance    where players arrive; lined up with the previous room's Exit
--   Exit        where the next room attaches
--   Goal        touching it clears the room (in PlugBoss: the plug)
--   BagRelease  (optional) touching it frees every bagged teammate
-- Optional: a Folder "VacuumPath" with Parts named 1, 2, 3... for the vacuum's route.
-- Rooms read their Attributes "Difficulty" ("normal"/"hard") and "PlayerCount" to adapt.
-- Rooms can also be built in code: a ModuleScript in Server/Rooms named like the room id,
-- returning { build = function(difficulty): Model }.
-- Missing rooms are replaced by a grey placeholder so the game is playable right away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local RoomPicker = require(ReplicatedStorage.Shared.RoomPicker)
local Ads = require(script.Parent.Ads)
local PlayerData = require(script.Parent.PlayerData)
local Purchases = require(script.Parent.Purchases)
local Remotes = require(script.Parent.Remotes)

local RunManager = {}

type Room = { slot: RoomPicker.Slot, model: Model }

local state = {
	rooms = {} :: { Room },
	current = 0,
	roomCleared = false,
	bossBeaten = false,
	roomsCleared = 0,
	rescues = {} :: { [Player]: number },
	freeRevivesLeft = 0,
	boughtRevives = 0,
	awaitingRevive = false,
	reviveGranted = false,
	vacuum = nil :: Model?,
}

local function today(): number
	return os.time() // 86400
end

local function rootOf(player: Player): BasePart?
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function findPart(model: Model, name: string): BasePart?
	return model:FindFirstChild(name, true) :: BasePart?
end

local function placeholderRoom(id: string, kind: string): Model
	local model = Instance.new("Model")
	model.Name = id
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(24, 1, 60)
	floor.Color = if kind == "safe" then Color3.fromRGB(120, 200, 140) else Color3.fromRGB(170, 170, 170)
	floor.Parent = model
	local function marker(name: string, z: number, color: Color3?)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = if color then 0.3 else 1
		p.Color = color or Color3.new()
		p.Size = Vector3.new(6, 1, 6)
		p.CFrame = CFrame.new(0, 1, z)
		p.Parent = model
	end
	marker("Entrance", -28)
	marker("Exit", 30)
	marker("Goal", 26, Color3.fromRGB(255, 220, 60))
	marker("BagRelease", 0, Color3.fromRGB(80, 160, 255))
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(300, 50)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.Text = `[placeholder] {id}`
	text.Parent = sign
	sign.Parent = floor
	model.PrimaryPart = floor
	return model
end

local function makeVacuum(): Model
	local template = ServerStorage:FindFirstChild("Vacuum")
	if template and template:IsA("Model") then
		return template:Clone()
	end
	local model = Instance.new("Model")
	model.Name = "MrSuckles"
	local body = Instance.new("Part")
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(7, 7, 7)
	body.Color = Color3.fromRGB(200, 40, 60)
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	return model
end

local function buildRooms(slots: { RoomPicker.Slot })
	local folder = Instance.new("Folder")
	folder.Name = "Run"
	folder.Parent = workspace
	local templates = ServerStorage:FindFirstChild("Rooms")
	local previousExit = CFrame.new(0, 50, 0)

	for _, slot in slots do
		-- Priority: a model you built in Studio > a room built in code > grey placeholder.
		local template = templates and templates:FindFirstChild(slot.id)
		local builder = script.Parent.Rooms:FindFirstChild(slot.id)
		local model
		if template and template:IsA("Model") then
			model = template:Clone()
		elseif builder and builder:IsA("ModuleScript") then
			model = (require(builder) :: any).build(slot.difficulty)
		else
			model = placeholderRoom(slot.id, slot.kind)
		end
		local entrance = findPart(model, "Entrance")
		local exit = findPart(model, "Exit")
		assert(entrance and exit and findPart(model, "Goal"), `room {slot.id} needs Entrance, Exit and Goal parts`)

		-- Line this room's Entrance up with the previous room's Exit.
		local pivotFromEntrance = entrance.CFrame:ToObjectSpace(model:GetPivot())
		model:PivotTo(previousExit * pivotFromEntrance)
		previousExit = exit.CFrame
		model:SetAttribute("Difficulty", slot.difficulty)
		model:SetAttribute("PlayerCount", #Players:GetPlayers())
		model.Parent = folder
		table.insert(state.rooms, { slot = slot, model = model })
	end
end

local function currentRoom(): Room?
	return state.rooms[state.current]
end

local function spawnAt(player: Player, part: BasePart)
	local character = player.Character
	local root = rootOf(player)
	if character and root then
		root.Anchored = false
		character:PivotTo(part.CFrame + Vector3.new(math.random(-3, 3), 4, math.random(-3, 3)))
	end
end

local function isBagged(player: Player): boolean
	return player:GetAttribute("Bagged") == true
end

local function bag(player: Player)
	player:SetAttribute("Bagged", true)
	local root = rootOf(player)
	if root then
		root.Anchored = true
	end
end

local function unbagAll(at: BasePart, rescuer: Player?)
	for _, player in Players:GetPlayers() do
		if isBagged(player) then
			player:SetAttribute("Bagged", false)
			spawnAt(player, at)
			if rescuer and rescuer ~= player then
				state.rescues[rescuer] = (state.rescues[rescuer] or 0) + 1
			end
		end
	end
end

local function everyoneBagged(): boolean
	local players = Players:GetPlayers()
	if #players == 0 then
		return true
	end
	for _, player in players do
		if not isBagged(player) then
			return false
		end
	end
	return true
end

local function vacuumPath(room: Room): { Vector3 }
	local points = {}
	local folder = room.model:FindFirstChild("VacuumPath", true)
	if folder then
		local parts = folder:GetChildren()
		table.sort(parts, function(a, b)
			return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
		end)
		for _, p in parts do
			if p:IsA("BasePart") then
				table.insert(points, p.Position)
			end
		end
	end
	if #points == 0 then
		points = {
			(findPart(room.model, "Entrance") :: BasePart).Position,
			(findPart(room.model, "Goal") :: BasePart).Position,
		}
	end
	return points
end

-- Moves the vacuum along the room's path until the room is cleared or the team wipes.
local function runVacuum(room: Room)
	local vacuum = state.vacuum :: Model
	local path = vacuumPath(room)
	local cfg = Config.Vacuum
	vacuum:PivotTo(CFrame.new(path[1] + Vector3.new(0, 4, 0)))
	vacuum.Parent = nil

	local enterDelay = if room.slot.difficulty == "hard" then cfg.EnterDelay.hard else cfg.EnterDelay.normal
	local waited = 0
	while waited < enterDelay and not state.roomCleared do
		waited += task.wait(0.1)
	end
	if state.roomCleared then
		return
	end
	vacuum.Parent = workspace

	local position = path[1]
	local target = 2
	local speed = cfg.StartSpeed
	while not state.roomCleared and not state.awaitingRevive do
		local dt = RunService.Heartbeat:Wait()
		speed = math.min(cfg.MaxSpeed, speed + cfg.Acceleration * dt)
		if target <= #path then
			local toTarget = path[target] - position
			local step = speed * dt
			if toTarget.Magnitude <= step then
				position = path[target]
				target += 1
			else
				position += toTarget.Unit * step
			end
		end
		vacuum:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)))

		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and not isBagged(player) and (root.Position - position).Magnitude <= cfg.CatchRadius + 3 then
				bag(player)
				root.CFrame = CFrame.new(position + Vector3.new(0, 9, 0)) -- dangling in the bag
			end
		end
		-- Bagged players ride along with the vacuum.
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and isBagged(player) then
				root.CFrame = CFrame.new(position + Vector3.new(0, 9, 0))
			end
		end
		if everyoneBagged() then
			return
		end
	end
	vacuum.Parent = nil
end

local function reviveOptionsFor(player: Player): { string }
	local data = PlayerData.get(player)
	local options = {}
	if state.freeRevivesLeft > 0 then
		table.insert(options, "free")
		return options -- token/paid are only offered once the free revives are used up
	end
	if data and state.boughtRevives < Config.Revives.MaxBoughtPerRun then
		local tokenAvailable = not Ads.isEligible(player)
			and not (data.reviveToken.day == today() and data.reviveToken.used)
		if tokenAvailable or data.reviveCredits > 0 then
			table.insert(options, "token")
		end
		if Config.Products.ReviveDevProduct ~= 0 then
			table.insert(options, "paid")
		end
	end
	return options
end

-- Team wiped: offer revives. Returns true if the team was revived.
local function offerRevive(): boolean
	state.awaitingRevive = true
	state.reviveGranted = false
	local prompt = Remotes.get("RevivePrompt")
	for _, player in Players:GetPlayers() do
		prompt:FireClient(player, reviveOptionsFor(player), Config.Revives.DecisionSeconds)
	end
	local waited = 0
	while waited < Config.Revives.DecisionSeconds and not state.reviveGranted do
		waited += task.wait(0.1)
	end
	state.awaitingRevive = false
	prompt:FireAllClients(nil) -- close the prompt
	return state.reviveGranted
end

local function onReviveChoice(player: Player, choice: unknown)
	if not state.awaitingRevive or state.reviveGranted then
		return
	end
	if not table.find(reviveOptionsFor(player), choice :: string) then
		return -- not allowed; never trust the client
	end
	local data = PlayerData.get(player) :: PlayerData.Data
	if choice == "free" then
		state.freeRevivesLeft -= 1
	elseif choice == "token" then
		if data.reviveCredits > 0 then
			data.reviveCredits -= 1
		else
			data.reviveToken = { day = today(), used = true }
		end
		state.boughtRevives += 1
	else
		return -- "paid" goes through the purchase prompt and ProcessReceipt
	end
	state.reviveGranted = true
end

local function grantPaidRevive(_player: Player, data: PlayerData.Data): boolean
	if state.awaitingRevive and not state.reviveGranted and state.boughtRevives < Config.Revives.MaxBoughtPerRun then
		state.boughtRevives += 1
		state.reviveGranted = true
	else
		-- Bought too late or over the cap: keep it for later instead of wasting the Robux.
		data.reviveCredits += 1
	end
	return true
end

local function payOut()
	local result = Remotes.get("RunResult")
	for _, player in Players:GetPlayers() do
		local data = PlayerData.get(player)
		if data then
			local coins = Economy.runPayout(Config.Coins, {
				roomsCleared = state.roomsCleared,
				rescues = state.rescues[player] or 0,
				bossBeaten = state.bossBeaten,
			}, {
				isVip = Purchases.isVip(player),
				adEligible = Ads.isEligible(player),
				watchedAd = false, -- TODO(ads): offer the doubler after the run
			})
			PlayerData.addCoins(player, coins)
			if state.bossBeaten then
				data.runsCompleted += 1
			end
			PlayerData.saveNow(player)
			result:FireClient(player, coins, state.bossBeaten)
		end
	end
end

local function returnToLobby()
	task.wait(8)
	if RunService:IsStudio() then
		print("RunManager: run over (teleport back to lobby is skipped in Studio)")
		return
	end
	local players = Players:GetPlayers()
	if #players > 0 then
		pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, players)
		end)
	end
end

local function waitForParty(): number
	local expected = 1
	local waited = 0
	while waited < 20 do
		local players = Players:GetPlayers()
		if #players > 0 then
			local joinData = players[1]:GetJoinData()
			local tp = joinData and joinData.TeleportData
			if typeof(tp) == "table" and typeof(tp.partySize) == "number" then
				expected = math.clamp(tp.partySize, 1, Config.Lobby.MaxPartySize)
			end
			if #players >= expected then
				break
			end
		end
		waited += task.wait(0.5)
	end
	for _, player in Players:GetPlayers() do
		PlayerData.waitFor(player)
	end
	return #Players:GetPlayers()
end

function RunManager.start()
	Purchases.registerProduct(Config.Products.ReviveDevProduct, grantPaidRevive)
	Remotes.get("ReviveChoice").OnServerEvent:Connect(onReviveChoice)

	local partySize = waitForParty()
	local bestRuns = 0
	for _, player in Players:GetPlayers() do
		local data = PlayerData.get(player)
		if data then
			bestRuns = math.max(bestRuns, data.runsCompleted)
		end
	end
	state.freeRevivesLeft = Economy.freeRevives(Config.Revives, partySize, bestRuns)

	local slots = RoomPicker.pick(Config.Rooms, Config.RunPlan, Random.new(), {
		start = Config.StartRoom,
		safe = Config.SafeRoom,
		boss = Config.BossRoom,
	})
	-- Studio testing: workspace attribute StudioTestRoom = "TrampolineBed" puts that room right after the start.
	local testRoom = workspace:GetAttribute("StudioTestRoom")
	if RunService:IsStudio() and typeof(testRoom) == "string" and testRoom ~= "" then
		slots[2] = {
			id = testRoom,
			kind = "room",
			difficulty = if workspace:GetAttribute("StudioTestHard") == true then "hard" else "normal",
		}
	end
	buildRooms(slots)
	state.vacuum = makeVacuum()

	-- Respawns (e.g. falling off) go to the current room's entrance.
	local function onCharacter(player: Player)
		player:SetAttribute("Bagged", false)
		task.defer(function()
			local room = currentRoom()
			if room then
				spawnAt(player, findPart(room.model, "Entrance") :: BasePart)
			end
		end)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end

	for index, room in state.rooms do
		state.current = index
		state.roomCleared = false
		room.model:SetAttribute("Active", true)

		if index == 1 then
			for _, player in Players:GetPlayers() do
				spawnAt(player, findPart(room.model, "Entrance") :: BasePart)
			end
		end

		local goal = findPart(room.model, "Goal") :: BasePart
		local release = findPart(room.model, "BagRelease")
		local connections = {}
		table.insert(
			connections,
			goal.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and not isBagged(player) then
					state.roomCleared = true
				end
			end)
		)
		if release then
			table.insert(
				connections,
				release.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if player and not isBagged(player) then
						unbagAll(release, player)
					end
				end)
			)
		end

		local hasVacuum = room.slot.kind == "room" or room.slot.kind == "boss"
		while not state.roomCleared do
			if hasVacuum then
				runVacuum(room)
			else
				task.wait(0.2)
			end
			if not state.roomCleared and everyoneBagged() then
				if offerRevive() then
					unbagAll(findPart(room.model, "Entrance") :: BasePart, nil)
				else
					break
				end
			end
		end

		for _, c in connections do
			c:Disconnect()
		end
		room.model:SetAttribute("Active", false)
		if not state.roomCleared then
			break -- team wiped with no revive
		end
		if room.slot.kind == "room" then
			state.roomsCleared += 1
		elseif room.slot.kind == "boss" then
			state.bossBeaten = true
		end
		-- Anyone still bagged when the room is cleared gets carried along.
		unbagAll(findPart(room.model, "Exit") :: BasePart, nil)
	end

	if state.vacuum then
		state.vacuum.Parent = nil
	end
	payOut()
	returnToLobby()
end

return RunManager
