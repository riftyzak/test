--!strict
-- Helpers for rooms built in code. Coordinates are local: the room is moved into place
-- afterwards so its Entrance lines up with the previous room's Exit.

local Shared = {}

function Shared.part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Invisible (or tinted) non-colliding marker such as Entrance, Exit, Goal, BagRelease.
function Shared.marker(parent: Instance, name: string, cframe: CFrame, color: Color3?): Part
	local p = Shared.part(parent, name, Vector3.new(6, 1, 6), cframe, color or Color3.new())
	p.CanCollide = false
	p.Transparency = if color then 0.3 else 1
	return p
end

function Shared.vacuumPath(parent: Instance, points: { Vector3 })
	local folder = Instance.new("Folder")
	folder.Name = "VacuumPath"
	for i, point in points do
		local p = Shared.marker(folder, tostring(i), CFrame.new(point))
		p.Size = Vector3.new(1, 1, 1)
	end
	folder.Parent = parent
end

return Shared
