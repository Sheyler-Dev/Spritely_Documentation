--!native
--!optimize 2
local module = {}
local HTTP = game:GetService("HttpService")
local function getPixelCenter(pixels, sizeX, sizeY)
	local minX, minY = sizeX, sizeY
	local maxX, maxY = 0, 0
	local foundOpaque = false

	for y = 0, sizeY - 1 do
		for x = 0, sizeX - 1 do
			if buffer.readu8(pixels, (y * sizeX + x) * 4 + 3) > 128 then
				if x < minX then minX = x end
				if x > maxX then maxX = x end
				if y < minY then minY = y end
				if y > maxY then maxY = y end
				foundOpaque = true
			end
		end
	end

	if not foundOpaque then
		return Vector2.new(sizeX / 2, sizeY / 2)
	end

	return Vector2.new((minX + maxX) / 2, (minY + maxY) / 2)
end

local function getConvexHull(points)
	local n = #points
	if n <= 3 then return points end
	table.sort(points, function(a, b)
		if a.X == b.X then return a.Y < b.Y end
		return a.X < b.X
	end)
	local function crossProduct(o, a, b)
		return (a.X - o.X) * (b.Y - o.Y) - (a.Y - o.Y) * (b.X - o.X)
	end
	local lower = {}
	for i = 1, n do
		while #lower >= 2 and crossProduct(lower[#lower-1], lower[#lower], points[i]) <= 0 do
			table.remove(lower)
		end
		table.insert(lower, points[i])
	end
	local upper = {}
	for i = n, 1, -1 do
		while #upper >= 2 and crossProduct(upper[#upper-1], upper[#upper], points[i]) <= 0 do
			table.remove(upper)
		end
		table.insert(upper, points[i])
	end
	table.remove(upper)
	table.remove(lower)
	for _, p in ipairs(upper) do table.insert(lower, p) end
	return lower
end

local function isOpaque(pixels, x, y, sizeX, sizeY)
	if x < 0 or y < 0 or x >= sizeX or y >= sizeY then return false end
	return buffer.readu8(pixels, (y * sizeX + x) * 4 + 3) > 128
end

local function GetPaths(pixels, sizeX, sizeY, step)
	local function vkey(v)
		return v.X .. "|" .. v.Y
	end

	local edges = {}
	local pointEdges = {}
	local function addEdge(a, b)
		local idx = #edges + 1
		edges[idx] = {a, b}
		local ka, kb = vkey(a), vkey(b)
		if not pointEdges[ka] then pointEdges[ka] = {} end
		if not pointEdges[kb] then pointEdges[kb] = {} end
		table.insert(pointEdges[ka], idx)
		table.insert(pointEdges[kb], idx)
	end

	for y = -step, sizeY, step do
		for x = -step, sizeX, step do
			local solid = isOpaque(pixels, x, y, sizeX, sizeY)
			if solid ~= isOpaque(pixels, x + step, y, sizeX, sizeY) then
				addEdge(Vector2.new(x + step, y), Vector2.new(x + step, y + step))
			end
			if solid ~= isOpaque(pixels, x, y + step, sizeX, sizeY) then
				addEdge(Vector2.new(x, y + step), Vector2.new(x + step, y + step))
			end
		end
	end

	local usedEdges = {}
	local paths = {}
	local threshold = step * 0.1

	for startIdx = 1, #edges do
		if not usedEdges[startIdx] then
			local e = edges[startIdx]
			local currentPath = {e[1], e[2]}
			usedEdges[startIdx] = true

			local searching = true
			while searching do
				searching = false
				local last = currentPath[#currentPath]
				local candidates = pointEdges[vkey(last)]
				if candidates then
					for _, idx in ipairs(candidates) do
						if not usedEdges[idx] then
							local ce = edges[idx]
							if (ce[1] - last).Magnitude < threshold then
								table.insert(currentPath, ce[2])
								usedEdges[idx] = true
								searching = true
								break
							elseif (ce[2] - last).Magnitude < threshold then
								table.insert(currentPath, ce[1])
								usedEdges[idx] = true
								searching = true
								break
							end
						end
					end
				end
			end

			if #currentPath > 1 and (currentPath[#currentPath] - currentPath[1]).Magnitude < threshold then
				table.remove(currentPath, #currentPath)
			end

			local simplified = {}
			local n = #currentPath
			if n >= 3 then
				for i = 1, n do
					local pPrev = currentPath[(i - 2 + n) % n + 1]
					local pCurr = currentPath[i]
					local pNext = currentPath[i % n + 1]
					local v1 = (pCurr - pPrev).Unit
					local v2 = (pNext - pCurr).Unit
					if v1:Dot(v2) < 0.999 then
						table.insert(simplified, pCurr)
					end
				end
			else
				simplified = currentPath
			end

			if #simplified > 2 then
				table.insert(paths, simplified)
			end
		end
	end

	return paths
end

local function crossProduct2D(a, b, c)
	return (b.X - a.X) * (c.Y - a.Y) - (b.Y - a.Y) * (c.X - a.X)
end

local function isConvex(verts)
	local n = #verts
	if n < 3 then return true end
	local sign = 0
	for i = 1, n do
		local a = verts[i]
		local b = verts[i % n + 1]
		local c = verts[(i + 1) % n + 1]
		local cross = crossProduct2D(a, b, c)
		if math.abs(cross) > 0.001 then
			if sign == 0 then
				sign = cross > 0 and 1 or -1
			elseif (cross > 0 and sign < 0) or (cross < 0 and sign > 0) then
				return false
			end
		end
	end
	return true
end

local function segmentsCross(ax, ay, bx, by, cx, cy, dx, dy)
	local s1x, s1y = bx - ax, by - ay
	local s2x, s2y = dx - cx, dy - cy
	local denom = -s2x * s1y + s1x * s2y
	if math.abs(denom) < 1e-9 then return false end
	local s = (-s1y * (ax - cx) + s1x * (ay - cy)) / denom
	local t = ( s2x * (ay - cy) - s2y * (ax - cx)) / denom
	return s > 0.001 and s < 0.999 and t > 0.001 and t < 0.999
end

local function decomposeConvex(verts)
	if isConvex(verts) then return {verts} end

	local n = #verts
	local bestScore = math.huge
	local bestI, bestJ = -1, -1

	for i = 1, n do
		for j = i + 2, n do
			if not (i == 1 and j == n) then
				local ax, ay = verts[i].X, verts[i].Y
				local bx, by = verts[j].X, verts[j].Y
				local valid = true

				for k = 1, n do
					local ni = k % n + 1
					if k ~= i and k ~= j and ni ~= i and ni ~= j then
						if segmentsCross(ax, ay, bx, by, verts[k].X, verts[k].Y, verts[ni].X, verts[ni].Y) then
							valid = false
							break
						end
					end
				end

				if valid then
					local mx, my = (ax + bx) * 0.5, (ay + by) * 0.5
					local insideCheck = false
					local jj = n
					for ii = 1, n do
						local ix, iy = verts[ii].X, verts[ii].Y
						local jx, jy = verts[jj].X, verts[jj].Y
						if ((iy > my) ~= (jy > my)) and
							(mx < (jx - ix) * (my - iy) / (jy - iy) + ix) then
							insideCheck = not insideCheck
						end
						jj = ii
					end

					if insideCheck then
						local dx2, dy2 = bx - ax, by - ay
						local score = dx2*dx2 + dy2*dy2
						if score < bestScore then
							bestScore = score
							bestI, bestJ = i, j
						end
					end
				end
			end
		end
	end

	if bestI == -1 then return {verts} end

	local poly1, poly2 = {}, {}
	for i = bestI, bestJ do
		table.insert(poly1, verts[i])
	end
	for i = bestJ, n do
		table.insert(poly2, verts[i])
	end
	for i = 1, bestI do
		table.insert(poly2, verts[i])
	end

	local result = {}
	for _, p in ipairs(decomposeConvex(poly1)) do table.insert(result, p) end
	for _, p in ipairs(decomposeConvex(poly2)) do table.insert(result, p) end
	return result
end

function module.Generate(collisionType, pixels, size: Vector2, data: {})
	if collisionType == "Precise" then
		local Resolution = data.Resolution or 1
		local paths = GetPaths(pixels, size.X, size.Y, Resolution)
		local center = getPixelCenter(pixels, size.X, size.Y)
		local decomposed = {}
		for _, path in ipairs(paths) do
			if #path >= 3 then
				for _, part in ipairs(decomposeConvex(path)) do
					table.insert(decomposed, part)
				end
			end
		end
		return decomposed, center

	elseif collisionType == "Custom" then
		local decodedPaths = HTTP:JSONDecode(data.Custom)
		local vectorPaths = {}
		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		local foundPoints = false

		for _, shape in pairs(decodedPaths) do
			local currentShape = {}
			for _, pt in pairs(shape) do
				local px = pt.X
				local py = pt.Y
				if px and py then
					table.insert(currentShape, Vector2.new(px, py))
					if px < minX then minX = px end
					if px > maxX then maxX = px end
					if py < minY then minY = py end
					if py > maxY then maxY = py end
					foundPoints = true
				end
			end
			if #currentShape >= 3 then
				for _, part in ipairs(decomposeConvex(currentShape)) do
					table.insert(vectorPaths, part)
				end
			elseif #currentShape > 0 then
				table.insert(vectorPaths, currentShape)
			end
		end

		local center
		if foundPoints then
			center = Vector2.new((minX + maxX) / 2, (minY + maxY) / 2)
		else
			center = size / 2
		end
		return vectorPaths, center

	elseif collisionType == "Box" then
		local Relative = data.Relative or false
		if Relative then
			local minX, minY = size.X, size.Y
			local maxX, maxY = 0, 0
			local foundOpaque = false
			for y = 0, size.Y - 1 do
				local rowOffset = y * size.X
				for x = 0, size.X - 1 do
					if buffer.readu8(pixels, (rowOffset + x) * 4 + 3) > 128 then
						if x < minX then minX = x end
						if x > maxX then maxX = x end
						if y < minY then minY = y end
						if y > maxY then maxY = y end
						foundOpaque = true
					end
				end
			end
			if not foundOpaque then
				return {{Vector2.new(0,0), Vector2.new(0,0), Vector2.new(0,0), Vector2.new(0,0)}}, size / 2
			end
			local box = {
				Vector2.new(minX, minY),
				Vector2.new(maxX+1, minY),
				Vector2.new(maxX+1, maxY+1),
				Vector2.new(minX, maxY+1)
			}
			return {box}, Vector2.new((minX + maxX) / 2, (minY + maxY) / 2)
		else
			return {
				{Vector2.new(0,0), Vector2.new(size.X,0), Vector2.new(size.X,size.Y), Vector2.new(0,size.Y)}
			}, Vector2.new(size.X / 2, size.Y / 2)
		end

	elseif collisionType == "Radial" then
		local maxDistSq = 0
		local center = getPixelCenter(pixels, size.X, size.Y)
		for y = 0, size.Y - 1 do
			for x = 0, size.X - 1 do
				if buffer.readu8(pixels, (y * size.X + x) * 4 + 3) > 128 then
					local distSq = (Vector2.new(x, y) - center).Magnitude
					if distSq > maxDistSq then maxDistSq = distSq end
				end
			end
		end
		return maxDistSq, center

	elseif collisionType == "Convex" then
		local extremePoints = {}
		local minX, minY, maxX, maxY = size.X, size.Y, 0, 0
		local found = false
		for y = 0, size.Y - 1 do
			local rowOffset = y * size.X
			local first, last = -1, -1
			for x = 0, size.X - 1 do
				if buffer.readu8(pixels, (rowOffset + x) * 4 + 3) > 128 then
					if first == -1 then first = x end
					last = x
					if x < minX then minX = x end
					if x > maxX then maxX = x end
					if y < minY then minY = y end
					if y > maxY then maxY = y end
					found = true
				end
			end
			if first ~= -1 then
				table.insert(extremePoints, Vector2.new(first, y))
				table.insert(extremePoints, Vector2.new(first, y + 1))
				table.insert(extremePoints, Vector2.new(last + 1, y))
				table.insert(extremePoints, Vector2.new(last + 1, y + 1))
			end
		end
		if not found then return {}, size / 2 end
		local center = Vector2.new((minX + maxX + 1) / 2, (minY + maxY + 1) / 2)
		local hull = getConvexHull(extremePoints)
		return {hull}, center
	end

	return {}
end

return module