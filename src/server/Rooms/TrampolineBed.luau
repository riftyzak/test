--!strict
-- EASY room: bounce across a giant bed while pillows fly at you.
-- Fall into a gap and you land on the carpet; toy blocks on the side let you climb back up
-- (costing time while Mr. Suckles closes in).
-- Hard version: shorter mattresses, more and faster pillows.
--
-- Mechanics are generic part attributes handled by the client:
--   BouncePower  launches you upward when you land on the part
--   Knockback    shoves you away from the part when it hits you

local TweenService = game:GetService("TweenService")

local Shared = require(script.Parent.Shared)

local TrampolineBed = {}

local MATTRESS_TOP = 6

function TrampolineBed.build(difficulty: string): Model
	local hard = difficulty == "hard"
	local model = Instance.new("Model")
	model.Name = "TrampolineBed"
	local part = Shared.part

	-- Room shell
	part(model, "Carpet", Vector3.new(34, 1, 92), CFrame.new(0, 0, 0), Color3.fromRGB(110, 80, 160))
	part(model, "WallLeft", Vector3.new(1, 20, 92), CFrame.new(-17, 10, 0), Color3.fromRGB(250, 230, 200))
	part(model, "WallRight", Vector3.new(1, 20, 92), CFrame.new(17, 10, 0), Color3.fromRGB(250, 230, 200))
	Shared.marker(model, "Entrance", CFrame.new(0, 1, -42))
	Shared.marker(model, "Exit", CFrame.new(0, 1, 46))

	-- Step up onto the bed
	part(model, "ToyBlockStep", Vector3.new(6, 3, 4), CFrame.new(0, 2, -33), Color3.fromRGB(230, 70, 70))

	-- Mattresses with gaps; each one bounces you
	local length = if hard then 8 else 10
	local centers = { -24, -8, 8, 24 }
	local colors = { Color3.fromRGB(120, 180, 255), Color3.fromRGB(255, 255, 255) }
	for i, z in centers do
		local mattress = part(
			model,
			`Mattress{i}`,
			Vector3.new(16, MATTRESS_TOP - 0.5, length),
			CFrame.new(0, (MATTRESS_TOP + 0.5) / 2, z),
			colors[(i % 2) + 1]
		)
		mattress.Material = Enum.Material.Fabric
		mattress:SetAttribute("BouncePower", if hard then 62 else 58)
	end

	-- Climb-back blocks beside each gap
	for i, z in { -16, 0, 16 } do
		part(model, `ClimbBlock{i}`, Vector3.new(4, 3, 4), CFrame.new(11, 2, z), Color3.fromRGB(255, 200, 60))
	end
	Shared.marker(model, "BagRelease", CFrame.new(11, 4, 0), Color3.fromRGB(80, 160, 255))

	-- Headboard + goal pillow
	part(
		model,
		"GoalPillow",
		Vector3.new(16, 2, 6),
		CFrame.new(0, MATTRESS_TOP + 0.5, 33),
		Color3.fromRGB(255, 240, 240)
	)
	part(model, "Headboard", Vector3.new(18, 16, 2), CFrame.new(0, 8, 37), Color3.fromRGB(140, 90, 50))
	Shared.marker(model, "Goal", CFrame.new(0, MATTRESS_TOP + 2, 33), Color3.fromRGB(255, 220, 60))
	part(model, "StepDown", Vector3.new(6, 3, 4), CFrame.new(0, 2, 41), Color3.fromRGB(230, 70, 70))

	-- Vacuum route along the carpet
	Shared.vacuumPath(model, { Vector3.new(0, 2, -42), Vector3.new(0, 2, 0), Vector3.new(0, 2, 34) })

	-- Flying pillows sweep across the bed
	local pillowZs: { number } = if hard then { -24, -8, 8, 24 } else { -8, 24 }
	local pillows = {}
	for i, z in pillowZs do
		local pillow = part(
			model,
			`FlyingPillow{i}`,
			Vector3.new(5, 3, 4),
			CFrame.new(-13, MATTRESS_TOP + 3, z),
			Color3.new(1, 1, 1)
		)
		pillow.CanCollide = false
		pillow:SetAttribute("Knockback", 45)
		table.insert(pillows, pillow)
	end

	-- Animate only while the room is active (positions are final by then).
	local tweens: { Tween } = {}
	model:GetAttributeChangedSignal("Active"):Connect(function()
		for _, t in tweens do
			t:Cancel()
		end
		table.clear(tweens)
		if model:GetAttribute("Active") ~= true then
			return
		end
		local period = if hard then 1.4 else 2.2
		for i, pillow in pillows do
			local across = pillow.CFrame * CFrame.new(26, 0, 0)
			local info = TweenInfo.new(period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, i * 0.4)
			local tween = TweenService:Create(pillow, info, { CFrame = across })
			tween:Play()
			table.insert(tweens, tween)
		end
	end)

	return model
end

return TrampolineBed
