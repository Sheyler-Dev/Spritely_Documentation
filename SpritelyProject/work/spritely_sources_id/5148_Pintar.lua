--!native
--!optimize 2

local module = {}

local function getDiffRGBAFromValues(b1, idx1, r2,g2,b2,a2)
	local dr = buffer.readu8(b1, idx1)     - r2
	local dg = buffer.readu8(b1, idx1 + 1) - g2
	local db = buffer.readu8(b1, idx1 + 2) - b2
	local da = buffer.readu8(b1, idx1 + 3) - a2

	return math.sqrt(dr*dr + dg*dg + db*db + da*da) / 510
end


function module.paint(EditableImage, startPos, newColorBuf, editor, SIZE, tolerance)

	tolerance = tolerance or 0

	local width, height = SIZE.X, SIZE.Y
	local totalPixels = width * height

	local mainBuffer = EditableImage:ReadPixelsBuffer(Vector2.zero, SIZE)

	local visited = table.create(totalPixels, false)

	local startIdx = (startPos.Y * width + startPos.X) * 4

	local targetR = buffer.readu8(mainBuffer, startIdx)
	local targetG = buffer.readu8(mainBuffer, startIdx + 1)
	local targetB = buffer.readu8(mainBuffer, startIdx + 2)
	local targetA = buffer.readu8(mainBuffer, startIdx + 3)

	local nr = buffer.readu8(newColorBuf, 0)
	local ng = buffer.readu8(newColorBuf, 1)
	local nb = buffer.readu8(newColorBuf, 2)
	local na = buffer.readu8(newColorBuf, 3)

	local stack = {startPos}
	local stackSize = 1

	while stackSize > 0 do

		local pos = stack[stackSize]
		stack[stackSize] = nil
		stackSize -= 1

		local x, y = pos.X, pos.Y

		if x < 0 or x >= width or y < 0 or y >= height then
			continue
		end

		local pixelIndex = y * width + x
		local visitedIdx = pixelIndex + 1

		if visited[visitedIdx] then
			continue
		end

		visited[visitedIdx] = true

		local idx = pixelIndex * 4
		
		if getDiffRGBAFromValues(mainBuffer, idx, targetR,targetG,targetB,targetA) <= tolerance then
			buffer.writeu8(mainBuffer, idx, nr)
			buffer.writeu8(mainBuffer, idx + 1, ng)
			buffer.writeu8(mainBuffer, idx + 2, nb)
			buffer.writeu8(mainBuffer, idx + 3, na)

			stackSize += 1; stack[stackSize] = Vector2.new(x + 1, y)
			stackSize += 1; stack[stackSize] = Vector2.new(x - 1, y)
			stackSize += 1; stack[stackSize] = Vector2.new(x, y + 1)
			stackSize += 1; stack[stackSize] = Vector2.new(x, y - 1)

		end
	end

	EditableImage:WritePixelsBuffer(Vector2.zero, SIZE, mainBuffer)

	if editor and editor.Frame and editor.Frame.NewChange then
		editor.Frame.NewChange:Fire()
	end
end

return module
