--!strict
-- Every Robux purchase is granted here on the server. Never grant rewards from a LocalScript.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

type Handler = (player: Player, data: PlayerData.Data) -> boolean

local Purchases = {}
local handlers: { [number]: Handler } = {}

-- Other systems (e.g. RunManager for revives) register what a product does.
-- The handler returns true only if it actually granted the item.
function Purchases.registerProduct(productId: number, handler: Handler)
	if productId ~= 0 then
		handlers[productId] = handler
	end
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and PlayerData.get(player)
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries later
	end

	-- Already granted (Roblox can call this more than once for the same purchase).
	if PlayerData.hasReceipt(data, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local handler = handlers[receipt.ProductId]
	if not handler then
		warn(`Purchases: no handler for product {receipt.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(handler, player, data)
	if not ok or not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PlayerData.addReceipt(data, receipt.PurchaseId)
	PlayerData.saveNow(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function refreshVip(player: Player)
	local id = Config.Products.VipSubscriptionId
	if id == "" then
		return
	end
	local ok, status = pcall(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(player, id)
	end)
	if ok and status then
		player:SetAttribute("IsVip", status.IsSubscribed == true)
	end
end

local function refreshPartyPass(player: Player)
	local id = Config.Products.PartyPassGamePass
	if id == 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	if ok then
		player:SetAttribute("HasPartyPass", owns == true)
	end
end

function Purchases.isVip(player: Player): boolean
	return player:GetAttribute("IsVip") == true
end

function Purchases.start()
	-- Premium skins are permanent. The shop UI must hide the buy button for owned skins,
	-- because developer products can technically be bought again.
	for productId, skinId in Config.Products.PremiumSkins do
		Purchases.registerProduct(productId, function(_player, data)
			data.ownedSkins[skinId] = true
			return true
		end)
	end

	MarketplaceService.ProcessReceipt = processReceipt

	Players.PlayerAdded:Connect(function(player)
		refreshVip(player)
		refreshPartyPass(player)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(refreshVip, p)
		task.spawn(refreshPartyPass, p)
	end

	Players.UserSubscriptionStatusChanged:Connect(function(player, subscriptionId)
		if subscriptionId == Config.Products.VipSubscriptionId then
			refreshVip(player)
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == Config.Products.PartyPassGamePass then
			player:SetAttribute("HasPartyPass", true)
		end
	end)
end

return Purchases
