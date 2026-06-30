--!native
local CollectionService = game:GetService("CollectionService")
local AllHashes = require(script.Parent:WaitForChild("GenerateObject"))
local GuiService = game:GetService("GuiService")

local EPSILON = 1e-6

local Raycast2D = {}
local TaggedObjects = {}
local Default = {
	["RespectVisible"] = false,
	["RayCastType"] = "Exclude",
	["Instances"] = {}
}

local function rotatePoint(p, center, angle)
	local rad = math.rad(angle)
	local cosA, sinA = math.cos(rad), math.sin(rad)
	local x, y = p.X - center.X, p.Y - center.Y
	return Vector2.new(
		cosA * x - sinA * y + center.X,
		sinA * x + cosA * y + center.Y
	)
end

local function transformPoint(v, center, scale, rotation)
	local rad = math.rad(rotation)
	local cosA, sinA = math.cos(rad), math.sin(rad)
	
	local x = v.X * scale.X - (center.X - center.X)
	local y = v.Y * scale.Y - (center.Y - center.Y)

	local offsetX = (v.X - (center.X / scale.X)) * scale.X
	local offsetY = (v.Y - (center.Y / scale.Y)) * scale.Y

	local rx = cosA * offsetX - sinA * offsetY
	local ry = sinA * offsetX + cosA * offsetY

	return Vector2.new(center.X + rx, center.Y + ry)
end

local function isPointInPoly(p, poly)
	local inside = false
	local j = #poly
	for i = 1, #poly do
		if ((poly[i].Y > p.Y) ~= (poly[j].Y > p.Y)) and
			(p.X < (poly[j].X - poly[i].X) * (p.Y - poly[i].Y) / (poly[j].Y - poly[i].Y) + poly[i].X) then
			inside = not inside
		end
		j = i
	end
	return inside
end

local function segmentIntersectionPoint(p1, p2, q1, q2)
	local r = p2 - p1
	local s = q2 - q1
	local r_cross_s = r.X * s.Y - r.Y * s.X
	if math.abs(r_cross_s) < EPSILON then return nil end

	local qp = q1 - p1
	local t = (qp.X * s.Y - qp.Y * s.X) / r_cross_s
	local u = (qp.X * r.Y - qp.Y * r.X) / r_cross_s

	if t > EPSILON and t <= 1 and u >= 0 and u <= 1 then
		return p1 + r * t, t
	end
	return nil
end

local function addObject(obj: Instance)
	if obj:IsDescendantOf(game.StarterGui) then return end
	if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and not TaggedObjects[obj] then
		TaggedObjects[obj] = true
	end
end

local function removeObject(obj: Instance)
	TaggedObjects[obj] = nil
end

CollectionService:GetInstanceAddedSignal("SpritelyObject"):Connect(addObject)
CollectionService:GetInstanceRemovedSignal("SpritelyObject"):Connect(removeObject)

for _, obj in ipairs(CollectionService:GetTagged("SpritelyObject")) do
	addObject(obj)
end

function Raycast2D.performRaycast(origin: Vector2, direction: Vector2, Options)
	Options = Options or Default
	local rayEnd = origin + direction
	local closestHit = nil
	local closestT = math.huge

	for obj in pairs(TaggedObjects) do
		if not obj.Visible and Options.RespectVisible then continue end
		if table.find(Options.Instances or {}, obj) and Options.RayCastType == "Exclude" then continue end

		local folder = obj:GetAttribute("ImageFolder")
		local frame  = obj:GetAttribute("Frame")
		local collData = AllHashes.CreatedColliders[folder][frame]
		local imgSize  = AllHashes.Sizes[folder]
		if not imgSize or not collData then continue end

		local absSize = obj.AbsoluteSize
		local scale   = absSize / imgSize
		local center  = obj.AbsolutePosition + GuiService:GetGuiInset() + absSize * 0.5
		local rot     = obj.AbsoluteRotation

		if type(collData) == "table" then
			for _, vList in ipairs(collData) do
				local worldPoly = {}
				for i, v in ipairs(vList) do
					local raw = Vector2.new(
						(v.X - imgSize.X * 0.5) * scale.X,
						(v.Y - imgSize.Y * 0.5) * scale.Y
					)
					worldPoly[i] = rotatePoint(center + raw, center, rot)
				end

				local n = #worldPoly
				for i = 1, n do
					local p1 = worldPoly[i]
					local p2 = worldPoly[i % n + 1]

					local hit, t = segmentIntersectionPoint(origin, rayEnd, p1, p2)
					if hit and t < closestT then
						local edge = p2 - p1
						local normal = Vector2.new(-edge.Y, edge.X).Unit
						if normal:Dot(direction) > 0 then
							normal = -normal
						end

						closestT = t
						closestHit = {
							Instance = obj,
							Position = hit,
							Normal   = normal,
							Distance = t * direction.Magnitude,
						}
					end
				end
			end

		elseif type(collData) == "number" then
			local radius = collData * scale.X
			local com    = AllHashes.CenterOfMass[folder][frame]
			local rawCOM = Vector2.new(
				(com.X - imgSize.X * 0.5) * scale.X,
				(com.Y - imgSize.Y * 0.5) * scale.Y
			)
			local circleCenter = rotatePoint(center + rawCOM, center, rot)

			local L   = circleCenter - origin
			local tca = L:Dot(direction.Unit)
			if tca >= 0 then
				local d2 = L:Dot(L) - tca * tca
				local r2 = radius * radius
				if d2 <= r2 then
					local thc = math.sqrt(r2 - d2)
					local t0  = tca - thc
					local t1  = tca + thc
					local tHit = t0 > EPSILON and t0 or t1
					local tNorm = tHit / direction.Magnitude

					if tNorm < closestT and tHit > EPSILON then
						local hitPos = origin + direction.Unit * tHit
						closestT = tNorm
						closestHit = {
							Instance = obj,
							Position = hitPos,
							Normal   = (hitPos - circleCenter).Unit,
							Distance = tHit,
						}
					end
				end
			end
		end
	end

	return closestHit
end

return Raycast2D