local module = {}

function module.SeparateBuffers(ImageEditable: EditableImage, GridSize: Vector2, CanCut: boolean)
	local AllBuffers = {}
	local imageSize = ImageEditable.Size

	local cellWidth = math.floor(imageSize.X / GridSize.X)
	local cellHeight = math.floor(imageSize.Y / GridSize.Y)
	local cellSize = Vector2.new(cellWidth, cellHeight)

	local minBounding = Vector2.zero
	local boundingSize = cellSize

	if CanCut then
		local maxBounding = Vector2.zero
		local minBoundingDetection = Vector2.new(math.huge, math.huge)
		local globalHasVisible = false

		for y = 0, GridSize.Y - 1 do
			for x = 0, GridSize.X - 1 do
				local cellPos = Vector2.new(x * cellWidth, y * cellHeight)
				local bufferImage = ImageEditable:ReadPixelsBuffer(cellPos, cellSize)

				for py = 0, cellHeight - 1 do
					for px = 0, cellWidth - 1 do
						local idx = ((py * cellWidth) + px) * 4
						local alpha = buffer.readu8(bufferImage, idx + 3)

						if alpha > 0 then
							globalHasVisible = true
							if px < minBoundingDetection.X then minBoundingDetection = Vector2.new(px, minBoundingDetection.Y) end
							if py < minBoundingDetection.Y then minBoundingDetection = Vector2.new(minBoundingDetection.X, py) end
							if px > maxBounding.X then maxBounding = Vector2.new(px, maxBounding.Y) end
							if py > maxBounding.Y then maxBounding = Vector2.new(maxBounding.X, py) end
						end
					end
				end
			end
		end

		if globalHasVisible then
			minBounding = minBoundingDetection
			boundingSize = Vector2.new(
				maxBounding.X - minBoundingDetection.X + 1,
				maxBounding.Y - minBoundingDetection.Y + 1
			)
		end
	end

	for y = 0, GridSize.Y - 1 do
		for x = 0, GridSize.X - 1 do
			local cellPos = Vector2.new(x * cellWidth, y * cellHeight)

			local bufferPos = cellPos + minBounding

			if (bufferPos.X + boundingSize.X <= imageSize.X) and (bufferPos.Y + boundingSize.Y <= imageSize.Y) then
				local bufferImage = ImageEditable:ReadPixelsBuffer(bufferPos, boundingSize)
				table.insert(AllBuffers, {
					Buffer = bufferImage,
				})
			else
				warn(("Frame en (%d,%d) excede los límites."):format(x, y))
			end
		end
	end

	return AllBuffers, boundingSize
end

return module