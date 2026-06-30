--!native
--!optimize 2
local module = {}

local AllHashes = require(script.Parent:WaitForChild("GenerateObject"))

local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad
local math_sqrt = math.sqrt
local math_max = math.max
local math_min = math.min
local math_huge = math.huge
local vector2_new = Vector2.new
local table_insert = table.insert

local function transformPointRaw(lx, ly, ox, oy, scaleX, scaleY, cosA, sinA, centerX, centerY)
	local x = (lx - centerX) * scaleX
	local y = (ly - centerY) * scaleY
	local rx = cosA * x - sinA * y
	local ry = sinA * x + cosA * y
	return ox + (centerX * scaleX) + rx, oy + (centerY * scaleY) + ry
end

local function isPointInPolyRaw(px, py, polyFlat)
	local inside = false
	local count = #polyFlat
	local jx, jy = polyFlat[count-1], polyFlat[count]
	for i = 1, count, 2 do
		local ix, iy = polyFlat[i], polyFlat[i+1]
		if ((iy > py) ~= (jy > py)) and (px < (jx - ix) * (py - iy) / (jy - iy) + ix) then
			inside = not inside
		end
		jx, jy = ix, iy
	end
	return inside
end

local function getRotatedAABB(pos, size, cosA, sinA)
	local px = pos.X + size.X * 0.5
	local py = pos.Y + size.Y * 0.5
	local hw = size.X * 0.5
	local hh = size.Y * 0.5
	local tlX = px + (cosA * -hw - sinA * -hh)
	local tlY = py + (sinA * -hw + cosA * -hh)

	local trX = px + (cosA * hw - sinA * -hh)
	local trY = py + (sinA * hw + cosA * -hh)

	local blX = px + (cosA * -hw - sinA * hh)
	local blY = py + (sinA * -hw + cosA * hh)

	local brX = px + (cosA * hw - sinA * hh)
	local brY = py + (sinA * hw + cosA * hh)
	local pad = 2

	return math_min(tlX, trX, blX, brX) - pad, 	math_max(tlX, trX, blX, brX) + pad, math_min(tlY, trY, blY, brY) - pad, math_max(tlY, trY, blY, brY) + pad
end

local function getSurfaceDataRaw(px, py, polyFlat)
	local closestDistSq = math_huge
	local nx, ny = 0, -1
	local cx, cy = px, py

	local count = #polyFlat
	for i = 1, count, 2 do
		local p1x, p1y = polyFlat[i], polyFlat[i+1]
		local nextIdx = (i + 2) > count and 1 or (i + 2)
		local p2x, p2y = polyFlat[nextIdx], polyFlat[nextIdx+1]

		local ex, ey = p2x - p1x, p2y - p1y
		local val = (px - p1x) * ex + (py - p1y) * ey
		local lenSq = ex*ex + ey*ey

		local param = (lenSq > 0) and math_max(0, math_min(lenSq, val)) / lenSq or 0
		local projX = p1x + ex * param
		local projY = p1y + ey * param

		local dx, dy = px - projX, py - projY
		local dSq = dx*dx + dy*dy

		if dSq < closestDistSq then
			closestDistSq = dSq
			cx, cy = projX, projY

			local dist = math_sqrt(lenSq)
			if dist > 0 then
				nx, ny = -ey / dist, ex / dist
			end
		end
	end

	return nx, ny, math_sqrt(closestDistSq), cx, cy
end

local function cachePolygonToWorld(vertices, ox, oy, sx, sy, cosA, sinA, szX, szY)
	local flat = table.create(#vertices * 2)
	local cx, cy = szX * 0.5, szY * 0.5
	local idx = 1
	for _, p in ipairs(vertices) do
		local wx, wy = transformPointRaw(p.X, p.Y, ox, oy, sx, sy, cosA, sinA, cx, cy)
		flat[idx] = wx
		flat[idx+1] = wy
		idx += 2
	end
	return flat
end

function module.collisionFromBoxesDetailed(Image1: ImageLabel, Image2: ImageLabel)
	local pos1, pos2 = Image1.AbsolutePosition, Image2.AbsolutePosition
	local size1, size2 = Image1.AbsoluteSize, Image2.AbsoluteSize

	local r1, r2 = math_rad(Image1.AbsoluteRotation), math_rad(Image2.AbsoluteRotation)
	local c1, s_1 = math_cos(r1), math_sin(r1)
	local c2, s_2 = math_cos(r2), math_sin(r2)

	local minX1, maxX1, minY1, maxY1 = getRotatedAABB(pos1, size1, c1, s_1)
	local minX2, maxX2, minY2, maxY2 = getRotatedAABB(pos2, size2, c2, s_2)

	if minX1 > maxX2 or maxX1 < minX2 or minY1 > maxY2 or maxY1 < minY2 then
		return false
	end
	local f1, fr1 = Image1:GetAttribute("ImageFolder"), Image1:GetAttribute("Frame")
	local f2, fr2 = Image2:GetAttribute("ImageFolder"), Image2:GetAttribute("Frame")
	local collData = AllHashes.CreatedColliders
	local Paths1 = collData[f1][fr1]
	local Paths2 = collData[f2][fr2]
	local objSize1, objSize2 = AllHashes.Sizes[f1], AllHashes.Sizes[f2]

	local sx1, sy1 = size1.X / objSize1.X, size1.Y / objSize1.Y
	local sx2, sy2 = size2.X / objSize2.X, size2.Y / objSize2.Y

	local rad1, rad2 = math_rad(Image1.AbsoluteRotation), math_rad(Image2.AbsoluteRotation)
	local cos1, sin1 = math_cos(rad1), math_sin(rad1)
	local cos2, sin2 = math_cos(rad2), math_sin(rad2)

	local type1 = AllHashes.CollisionType[f1]
	local type2 = AllHashes.CollisionType[f2]

	local contacts = { A = {}, B = {} }
	local bestNx, bestNy = 0, 0
	local maxDepth = -math_huge
	local hasContact = false

	if type1 == "Radial" and type2 == "Radial" then

		local cm1 = AllHashes.CenterOfMass[f1][fr1]
		local cm2 = AllHashes.CenterOfMass[f2][fr2]
		local cx1, cy1 = transformPointRaw(cm1.X, cm1.Y, pos1.X, pos1.Y, sx1, sy1, cos1, sin1, objSize1.X*0.5, objSize1.Y*0.5)
		local cx2, cy2 = transformPointRaw(cm2.X, cm2.Y, pos2.X, pos2.Y, sx2, sy2, cos2, sin2, objSize2.X*0.5, objSize2.Y*0.5)
		local dx, dy = cx1 - cx2, cy1 - cy2
		local distSq = dx*dx + dy*dy
		local rSum = (Paths1 * sx1) + (Paths2 * sx2)

		if distSq < (rSum * rSum) then
			local dist = math_sqrt(distSq)
			local nx, ny = 0, 1
			if dist > 0 then nx, ny = dx/dist, dy/dist end

			local depth = rSum - dist

			table_insert(contacts.A, vector2_new(cx1 - nx * (Paths1*sx1), cy1 - ny * (Paths1*sx1)))
			table_insert(contacts.B, vector2_new(cx2 + nx * (Paths2*sx2), cy2 + ny * (Paths2*sx2)))
			return true, vector2_new(nx, ny), depth, "radial", contacts
		end
		return false
	end

	if type1 == "Radial" or type2 == "Radial" then
		local cImg, cPath, cSx, cSy, cCos, cSin, cSz, cPos, isA_Radial
		local pImg, pPath, pSx, pSy, pCos, pSin, pSz, pPos

		if type1 == "Radial" then
			cImg, cPath, cSx, cSy, cCos, cSin, cSz, cPos, isA_Radial = Image1, Paths1, sx1, sy1, cos1, sin1, objSize1, pos1, true
			pImg, pPath, pSx, pSy, pCos, pSin, pSz, pPos = Image2, Paths2, sx2, sy2, cos2, sin2, objSize2, pos2
		else
			cImg, cPath, cSx, cSy, cCos, cSin, cSz, cPos, isA_Radial = Image2, Paths2, sx2, sy2, cos2, sin2, objSize2, pos2, false
			pImg, pPath, pSx, pSy, pCos, pSin, pSz, pPos = Image1, Paths1, sx1, sy1, cos1, sin1, objSize1, pos1
		end

		local com = AllHashes.CenterOfMass[cImg:GetAttribute("ImageFolder")][cImg:GetAttribute("Frame")]
		local ccx, ccy = transformPointRaw(com.X, com.Y, cPos.X, cPos.Y, cSx, cSy, cCos, cSin, cSz.X*0.5, cSz.Y*0.5)
		local radius = cPath * cSx

		for _, vList in ipairs(pPath) do
			local polyFlat = cachePolygonToWorld(vList, pPos.X, pPos.Y, pSx, pSy, pCos, pSin, pSz.X, pSz.Y)
			local inside = isPointInPolyRaw(ccx, ccy, polyFlat)
			local nx, ny, dEdge, cpx, cpy = getSurfaceDataRaw(ccx, ccy, polyFlat)

			if inside or dEdge < radius then
				hasContact = true
				local currentDepth = inside and (radius + dEdge) or (radius - dEdge)
				if currentDepth > maxDepth then
					maxDepth = currentDepth
					bestNx, bestNy = nx, ny
				end

				local contactCircle = vector2_new(ccx - nx * radius, ccy - ny * radius)
				local contactPoly = vector2_new(cpx, cpy)

				if isA_Radial then
					table_insert(contacts.A, contactCircle)
					table_insert(contacts.B, contactPoly)
				else
					table_insert(contacts.A, contactPoly)
					table_insert(contacts.B, contactCircle)
				end
			end
		end

		if hasContact then
			if not isA_Radial then bestNx, bestNy = -bestNx, -bestNy end
			return true, vector2_new(bestNx, bestNy), maxDepth, "slope", contacts
		end
		return false
	end

	local worldPolys1 = {}
	for i, vList in ipairs(Paths1) do
		worldPolys1[i] = cachePolygonToWorld(vList, pos1.X, pos1.Y, sx1, sy1, cos1, sin1, objSize1.X, objSize1.Y)
	end

	local worldPolys2 = {}
	for i, vList in ipairs(Paths2) do
		worldPolys2[i] = cachePolygonToWorld(vList, pos2.X, pos2.Y, sx2, sy2, cos2, sin2, objSize2.X, objSize2.Y)
	end

	for _, polyFlat1 in ipairs(worldPolys1) do
		for k = 1, #polyFlat1, 2 do
			local px, py = polyFlat1[k], polyFlat1[k+1]

			for _, polyFlat2 in ipairs(worldPolys2) do
				if isPointInPolyRaw(px, py, polyFlat2) then
					hasContact = true
					local nx, ny, d, cpx, cpy = getSurfaceDataRaw(px, py, polyFlat2)
					table_insert(contacts.A, vector2_new(px, py))
					table_insert(contacts.B, vector2_new(cpx, cpy))
					if d > maxDepth then
						maxDepth = d
						bestNx, bestNy = nx, ny
					end
				end
			end
		end
	end

	for _, polyFlat2 in ipairs(worldPolys2) do
		for k = 1, #polyFlat2, 2 do
			local px, py = polyFlat2[k], polyFlat2[k+1]

			for _, polyFlat1 in ipairs(worldPolys1) do
				if isPointInPolyRaw(px, py, polyFlat1) then
					hasContact = true

					local nx, ny, d, cpx, cpy = getSurfaceDataRaw(px, py, polyFlat1)

					table_insert(contacts.A, vector2_new(cpx, cpy))
					table_insert(contacts.B, vector2_new(px, py))

					if d > maxDepth then
						maxDepth = d
						bestNx, bestNy = -nx, -ny
					end
				end
			end
		end
	end

	if hasContact then
		return true, -vector2_new(bestNx, bestNy), maxDepth, "slope", contacts
	end

	return false
end

function module.collisionFromBoxes(Image1: ImageLabel, Image2: ImageLabel)

	local p1, p2 = Image1.AbsolutePosition, Image2.AbsolutePosition
	local s1, s2 = Image1.AbsoluteSize, Image2.AbsoluteSize

	local r1, r2 = math_rad(Image1.AbsoluteRotation), math_rad(Image2.AbsoluteRotation)
	local c1, s_1 = math_cos(r1), math_sin(r1)
	local c2, s_2 = math_cos(r2), math_sin(r2)

	local minX1, maxX1, minY1, maxY1 = getRotatedAABB(p1, s1, c1, s_1)
	local minX2, maxX2, minY2, maxY2 = getRotatedAABB(p2, s2, c2, s_2)

	if minX1 > maxX2 or maxX1 < minX2 or minY1 > maxY2 or maxY1 < minY2 then
		return false
	end

	local f1, fr1 = Image1:GetAttribute("ImageFolder"), Image1:GetAttribute("Frame")
	local f2, fr2 = Image2:GetAttribute("ImageFolder"), Image2:GetAttribute("Frame")

	local Paths1 = AllHashes.CreatedColliders[f1][fr1]
	local Paths2 = AllHashes.CreatedColliders[f2][fr2]

	local oSz1, oSz2 = AllHashes.Sizes[f1], AllHashes.Sizes[f2]
	local sx1, sy1 = s1.X / oSz1.X, s1.Y / oSz1.Y
	local sx2, sy2 = s2.X / oSz2.X, s2.Y / oSz2.Y

	local r1, r2 = math_rad(Image1.AbsoluteRotation), math_rad(Image2.AbsoluteRotation)
	local c1, s_1 = math_cos(r1), math_sin(r1)
	local c2, s_2 = math_cos(r2), math_sin(r2)

	local type1, type2 = AllHashes.CollisionType[f1], AllHashes.CollisionType[f2]
	if type1 == "Radial" and type2 == "Radial" then
		local cm1 = AllHashes.CenterOfMass[f1][fr1]
		local cm2 = AllHashes.CenterOfMass[f2][fr2]

		local cx1, cy1 = transformPointRaw(cm1.X, cm1.Y, p1.X, p1.Y, sx1, sy1, c1, s_1, oSz1.X*0.5, oSz1.Y*0.5)
		local cx2, cy2 = transformPointRaw(cm2.X, cm2.Y, p2.X, p2.Y, sx2, sy2, c2, s_2, oSz2.X*0.5, oSz2.Y*0.5)

		local dx, dy = cx1 - cx2, cy1 - cy2
		local distSq = dx*dx + dy*dy
		local rSum = (Paths1 * sx1) + (Paths2 * sx2)

		if distSq < rSum*rSum then
			local d = math_sqrt(distSq)
			local nx, ny = 0, 0
			if d > 0 then nx, ny = dx/d, dy/d else nx=1 end
			local cp = vector2_new(cx2 + nx*(Paths2*sx2), cy2 + ny*(Paths2*sx2))
			return true, vector2_new(nx, ny), rSum - d, "slope", cp
		end
		return false
	end

	local is1R = (type1 == "Radial")
	if type1 == "Radial" or type2 == "Radial" then
		local cDat, pDat
		local cm, rad, ccx, ccy
		local pPaths, pPos, pSx, pSy, pCos, pSin, pW, pH

		if is1R then
			local com = AllHashes.CenterOfMass[f1][fr1]
			ccx, ccy = transformPointRaw(com.X, com.Y, p1.X, p1.Y, sx1, sy1, c1, s_1, oSz1.X*0.5, oSz1.Y*0.5)
			rad = Paths1 * sx1
			pPaths, pPos, pSx, pSy, pCos, pSin, pW, pH = Paths2, p2, sx2, sy2, c2, s_2, oSz2.X, oSz2.Y
		else
			local com = AllHashes.CenterOfMass[f2][fr2]
			ccx, ccy = transformPointRaw(com.X, com.Y, p2.X, p2.Y, sx2, sy2, c2, s_2, oSz2.X*0.5, oSz2.Y*0.5)
			rad = Paths2 * sx2
			pPaths, pPos, pSx, pSy, pCos, pSin, pW, pH = Paths1, p1, sx1, sy1, c1, s_1, oSz1.X, oSz1.Y
		end

		for _, vList in ipairs(pPaths) do
			local polyFlat = cachePolygonToWorld(vList, pPos.X, pPos.Y, pSx, pSy, pCos, pSin, pW, pH)
			if isPointInPolyRaw(ccx, ccy, polyFlat) then
				local nx, ny, dEdge, cx, cy = getSurfaceDataRaw(ccx, ccy, polyFlat)
				local depth = rad + dEdge
				if is1R then nx, ny = -nx, -ny end
				return true, -vector2_new(nx, ny), depth, "slope", vector2_new(cx, cy)
			else
				local nx, ny, dEdge, cx, cy = getSurfaceDataRaw(ccx, ccy, polyFlat)
				if dEdge < rad then
					local depth = rad - dEdge
					if is1R then nx, ny = -nx, -ny end
					return true, -vector2_new(nx, ny), depth, "slope", vector2_new(cx, cy)
				end
			end
		end
	else
		local worldPolys1 = {}
		for i, vList in ipairs(Paths1) do
			worldPolys1[i] = cachePolygonToWorld(vList, p1.X, p1.Y, sx1, sy1, c1, s_1, oSz1.X, oSz1.Y)
		end

		local worldPolys2 = {}
		for i, vList in ipairs(Paths2) do
			worldPolys2[i] = cachePolygonToWorld(vList, p2.X, p2.Y, sx2, sy2, c2, s_2, oSz2.X, oSz2.Y)
		end

		local overallHasContact = false
		local overallMinDepth = -math_huge
		local overallNx, overallNy = 0, 0
		local overallContacts = { A = {}, B = {} }

		for _, polyFlat1 in ipairs(worldPolys1) do
			for _, polyFlat2 in ipairs(worldPolys2) do

				local minDepth = math_huge
				local bestNx, bestNy = 0, 0
				local tempContactsA, tempContactsB = {}, {}

				local function testAxes(pA, pB, invertNormal)
					local countA, countB = #pA, #pB

					local cAx, cAy = 0, 0
					for i = 1, countA, 2 do cAx += pA[i]; cAy += pA[i+1] end
					cAx /= (countA / 2); cAy /= (countA / 2)

					for i = 1, countA, 2 do
						local p1x, p1y = pA[i], pA[i+1]
						local nxt = (i + 2) > countA and 1 or (i + 2)
						local p2x, p2y = pA[nxt], pA[nxt+1]

						local dx, dy = p2x - p1x, p2y - p1y
						local lenSq = dx*dx + dy*dy
						if lenSq == 0 then continue end
						local len = math_sqrt(lenSq)
						local nx, ny = -dy/len, dx/len

						local mx, my = (p1x + p2x)*0.5, (p1y + p2y)*0.5
						if ((mx - cAx)*nx + (my - cAy)*ny) < 0 then
							nx, ny = -nx, -ny
						end

						local maxDepthEdge = -math_huge
						local deepPts = {}

						for j = 1, countB, 2 do
							local vx, vy = pB[j], pB[j+1]
							local depth = -((vx - p1x)*nx + (vy - p1y)*ny)
							if depth > maxDepthEdge + 0.001 then
								maxDepthEdge = depth
								deepPts = { {vx, vy} }
							elseif depth > maxDepthEdge - 0.001 then
								table_insert(deepPts, {vx, vy})
							end
						end
						if maxDepthEdge < 0 then return false end

						if maxDepthEdge < minDepth then
							minDepth = maxDepthEdge
							bestNx = invertNormal and -nx or nx
							bestNy = invertNormal and -ny or ny
							tempContactsA, tempContactsB = {}, {}

							for _, pt in ipairs(deepPts) do
								local vx, vy = pt[1], pt[2]
								local px, py = vx + nx * maxDepthEdge, vy + ny * maxDepthEdge

								local ptA_x, ptA_y, ptB_x, ptB_y
								if invertNormal then
									ptA_x, ptA_y = px, py
									ptB_x, ptB_y = vx, vy
								else
									ptA_x, ptA_y = vx, vy
									ptB_x, ptB_y = px, py
								end
								table_insert(tempContactsA, vector2_new(ptA_x, ptA_y))
								table_insert(tempContactsB, vector2_new(ptB_x, ptB_y))
							end
						end
					end
					return true
				end

				if testAxes(polyFlat2, polyFlat1, false) and testAxes(polyFlat1, polyFlat2, true) then
					overallHasContact = true
					if minDepth > overallMinDepth then
						overallMinDepth = minDepth
						overallNx, overallNy = bestNx, bestNy
						overallContacts.A = tempContactsA
						overallContacts.B = tempContactsB
					end
				end
			end
		end

		if overallHasContact then
			return true, vector2_new(overallNx, overallNy), overallMinDepth, "slope", overallContacts
		end
	end
	return false	
end

return module