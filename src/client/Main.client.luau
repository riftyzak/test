--!strict
-- Player UI: coin counter, ping wheel, revive prompt and end-of-run result.
-- Built in code so it syncs through Rojo; restyle it in Studio later if you like.
-- Buttons are big on purpose: most players are on phones.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent: Instance, text: string, size: UDim2, pos: UDim2): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0
	l.Text = text
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string, color: Color3, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(150, 60)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	b.Activated:Connect(onClick)
	b.Parent = parent
	return b
end

-- Coins
local coins = label(gui, "", UDim2.fromOffset(220, 50), UDim2.new(0, 16, 0, 16))
coins.TextXAlignment = Enum.TextXAlignment.Left
local function refreshCoins()
	coins.Text = `Coins: {player:GetAttribute("Coins") or 0}`
end
player:GetAttributeChangedSignal("Coins"):Connect(refreshCoins)
refreshCoins()

-- Ping wheel (bottom right)
local pings = Instance.new("Frame")
pings.BackgroundTransparency = 1
pings.Size = UDim2.fromOffset(150, 4 * 68)
pings.Position = UDim2.new(1, -166, 1, -4 * 68 - 100)
pings.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = pings
local PING_LOOK = {
	Here = { text = "📍 Here!", color = Color3.fromRGB(60, 140, 255) },
	Go = { text = "➡️ Go!", color = Color3.fromRGB(60, 190, 90) },
	Help = { text = "🆘 Help!", color = Color3.fromRGB(230, 70, 70) },
	Wait = { text = "✋ Wait", color = Color3.fromRGB(240, 170, 40) },
}
for _, choice in { "Here", "Go", "Help", "Wait" } do
	local look = PING_LOOK[choice]
	button(pings, look.text, look.color, function()
		(Remotes:WaitForChild("Ping") :: RemoteEvent):FireServer(choice)
	end)
end -- Show other players' pings over their heads for 2 seconds.
(Remotes:WaitForChild("Ping") :: RemoteEvent).OnClientEvent:Connect(function(who: Player, choice: string)
	local head = who.Character and who.Character:FindFirstChild("Head")
	local look = PING_LOOK[choice]
	if not head or not look then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	label(bb, look.text, UDim2.fromScale(1, 1), UDim2.new()).TextColor3 = look.color
	bb.Parent = head
	task.delay(2, function()
		bb:Destroy()
	end)
end)

-- Revive prompt. Never shown with a countdown pressure timer, as decided in the design doc;
-- it simply closes when the server's decision window ends.
local revive = Instance.new("Frame")
revive.Size = UDim2.fromOffset(500, 200)
revive.Position = UDim2.new(0.5, -250, 0.5, -100)
revive.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
revive.BackgroundTransparency = 0.15
revive.Visible = false
revive.Parent = gui
Instance.new("UICorner", revive).CornerRadius = UDim.new(0, 16)
label(revive, "Mr. Suckles got everyone!", UDim2.new(1, -20, 0, 50), UDim2.fromOffset(10, 10))
local reviveButtons = Instance.new("Frame")
reviveButtons.BackgroundTransparency = 1
reviveButtons.Size = UDim2.new(1, -20, 0, 70)
reviveButtons.Position = UDim2.fromOffset(10, 100)
reviveButtons.Parent = revive
local row = Instance.new("UIListLayout")
row.FillDirection = Enum.FillDirection.Horizontal
row.HorizontalAlignment = Enum.HorizontalAlignment.Center
row.Padding = UDim.new(0, 10)
row.Parent = reviveButtons

local function choose(choice: string)
	(Remotes:WaitForChild("ReviveChoice") :: RemoteEvent):FireServer(choice)
end
(Remotes:WaitForChild("RevivePrompt") :: RemoteEvent).OnClientEvent:Connect(function(options: { string }?)
	for _, child in reviveButtons:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	if not options or #options == 0 then
		revive.Visible = false
		return
	end
	for _, option in options do
		if option == "free" then
			button(reviveButtons, "Free revive", Color3.fromRGB(60, 190, 90), function()
				choose("free")
			end)
		elseif option == "token" then
			button(reviveButtons, "Use revive token", Color3.fromRGB(60, 140, 255), function()
				choose("token")
			end)
		elseif option == "paid" then
			button(reviveButtons, "Revive (R$19)", Color3.fromRGB(120, 120, 140), function()
				MarketplaceService:PromptProductPurchase(player, Config.Products.ReviveDevProduct)
			end)
		end
	end
	revive.Visible = true
end)

-- End-of-run result
local result = label(gui, "", UDim2.fromOffset(600, 80), UDim2.new(0.5, -300, 0.3, 0))
result.Visible = false;
(Remotes:WaitForChild("RunResult") :: RemoteEvent).OnClientEvent:Connect(function(earned: number, won: boolean)
	result.Text = if won then `You unplugged Mr. Suckles! +{earned} coins` else `Sucked up! +{earned} coins`
	result.Visible = true
	task.delay(7, function()
		result.Visible = false
	end)
end)

-- Room mechanics driven by part attributes (the client owns its character's physics,
-- so pushes have to happen here to feel instant):
--   BouncePower  launch upward when landing on the part
--   Knockback    shove away from the part on contact
local lastPush = 0
local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	humanoid.Touched:Connect(function(hit: BasePart)
		local now = os.clock()
		if now - lastPush < 0.25 or player:GetAttribute("Bagged") == true then
			return
		end
		local bounce = hit:GetAttribute("BouncePower")
		local knock = hit:GetAttribute("Knockback")
		local velocity = root.AssemblyLinearVelocity
		if typeof(bounce) == "number" and root.Position.Y > hit.Position.Y + hit.Size.Y / 2 then
			lastPush = now
			root.AssemblyLinearVelocity = Vector3.new(velocity.X, bounce, velocity.Z)
		elseif typeof(knock) == "number" then
			lastPush = now
			local away = (root.Position - hit.Position) * Vector3.new(1, 0, 1)
			if away.Magnitude < 0.1 then
				away = Vector3.new(1, 0, 0)
			end
			root.AssemblyLinearVelocity = away.Unit * knock + Vector3.new(0, knock * 0.6, 0)
		end
	end)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end
