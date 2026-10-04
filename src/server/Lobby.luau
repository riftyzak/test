--!strict
-- Lobby: the Toy Box elevator. Players stand in workspace.Lobby.ToyBox.Zone (a Part);
-- after ElevatorWaitSeconds (or when full) the group is sent to a private run server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Lobby = {}

local function isInside(part: BasePart, position: Vector3): boolean
	local localPos = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y + 4 and math.abs(localPos.Z) <= half.Z
end

local function playersIn(zone: BasePart): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and isInside(zone, root.Position) and PlayerData.get(player) then
			table.insert(list, player)
			if #list >= Config.Lobby.MaxPartySize then
				break
			end
		end
	end
	return list
end

local function makeSign(zone: BasePart): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffset = Vector3.new(0, zone.Size.Y / 2 + 4, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = zone
	return label
end

local function sendToRun(party: { Player })
	if RunService:IsStudio() then
		print("Lobby: teleports don't work in Studio. Set workspace attribute StudioRunMode = true to test a run.")
		return
	end
	local ok, err = pcall(function()
		local code = TeleportService:ReserveServerAsync(game.PlaceId)
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = code
		options:SetTeleportData({ partySize = #party })
		TeleportService:TeleportAsync(game.PlaceId, party, options)
	end)
	if not ok then
		warn("Lobby: teleport failed:", err)
	end
end

function Lobby.start()
	local lobbyFolder = workspace:WaitForChild("Lobby", 30)
	local toyBox = lobbyFolder and lobbyFolder:WaitForChild("ToyBox", 30)
	local zone = toyBox and toyBox:WaitForChild("Zone", 30) :: BasePart?
	if not zone then
		warn("Lobby: missing workspace.Lobby.ToyBox.Zone (a Part). The elevator is disabled.")
		return
	end

	local sign = makeSign(zone)
	local countdown: number? = nil

	while true do
		task.wait(0.5)
		local party = playersIn(zone)
		if #party == 0 then
			countdown = nil
			sign.Text = "Step in to start!"
			continue
		end

		countdown = (countdown or Config.Lobby.ElevatorWaitSeconds) - 0.5
		sign.Text = `{#party}/{Config.Lobby.MaxPartySize} toys - leaving in {math.ceil(countdown :: number)}`

		if (countdown :: number) <= 0 or #party >= Config.Lobby.MaxPartySize then
			sign.Text = "Here we go!"
			sendToRun(party)
			countdown = nil
			task.wait(3)
		end
	end
end

return Lobby
