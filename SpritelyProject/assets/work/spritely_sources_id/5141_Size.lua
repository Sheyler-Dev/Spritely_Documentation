local module = {}

local minZoom, maxZoom = 1,10

function module.Size(frame: ImageLabel)
	local originalSize = frame.Size
	local canvasSize = frame.ImageContent.Object.Size
	local currentZoom = 1

	frame:GetPropertyChangedSignal("ImageContent"):Connect(function()
		local editable = frame.ImageContent.Object
		if editable then
			canvasSize = editable.Size
			task.wait()
			originalSize = frame.Size
			currentZoom = 1
		end
	end)

	local function adjustFrameSize(delta, mousePos)

		local zoomFactor = 1 + (delta > 0 and 0.1 or -0.1)

		local newZoom = math.clamp(currentZoom * zoomFactor, minZoom, maxZoom)
		zoomFactor = newZoom / currentZoom
		currentZoom = newZoom

		local parentSize = frame.Parent.AbsoluteSize

		local oldSize = frame.Size
		local newSize = UDim2.new(
			originalSize.X.Scale * currentZoom,
			0,
			originalSize.Y.Scale * currentZoom,
			0
		)
		local relativeMouse = (mousePos - frame.AbsolutePosition) / frame.AbsoluteSize
		local pivot = Vector2.new(
			frame.Position.X.Scale + (relativeMouse.X - frame.AnchorPoint.X) * frame.Size.X.Scale,
			frame.Position.Y.Scale + (relativeMouse.Y - frame.AnchorPoint.Y) * frame.Size.Y.Scale
		)

		local newPos = UDim2.fromScale(
			pivot.X - (relativeMouse.X - frame.AnchorPoint.X) * newSize.X.Scale,
			pivot.Y - (relativeMouse.Y - frame.AnchorPoint.Y) * newSize.Y.Scale
		)

		local framePixelSize = Vector2.new(
			newSize.X.Scale * parentSize.X,
			newSize.Y.Scale * parentSize.Y
		)

		local frameCenterPixel = Vector2.new(
			newPos.X.Scale * parentSize.X,
			newPos.Y.Scale * parentSize.Y
		)

		local topLeft = frameCenterPixel - (framePixelSize / 2)
		local bottomRight = frameCenterPixel + (framePixelSize / 2)

		local centerX = frameCenterPixel.X
		local centerY = frameCenterPixel.Y

		if framePixelSize.X <= parentSize.X then
			centerX = parentSize.X / 2
		else
			if topLeft.X > 0 then
				centerX = math.min(centerX, framePixelSize.X / 2)
			elseif bottomRight.X < parentSize.X then
				centerX = math.max(centerX, parentSize.X - framePixelSize.X / 2)
			end
		end

		if framePixelSize.Y <= parentSize.Y then
			centerY = parentSize.Y / 2
		else
			if topLeft.Y > 0 then
				centerY = math.min(centerY, framePixelSize.Y / 2)
			elseif bottomRight.Y < parentSize.Y then
				centerY = math.max(centerY, parentSize.Y - framePixelSize.Y / 2)
			end
		end

		frameCenterPixel = Vector2.new(centerX, centerY)

		newPos = UDim2.fromScale(frameCenterPixel.X / parentSize.X, frameCenterPixel.Y / parentSize.Y)

		frame.Position = newPos
		frame.Size = newSize

		frame.Parent.Grid.Size = newSize
		frame.Parent.Paper.Size = newSize
		frame.Parent.Grid.Position = frame.Position
		frame.Parent.Paper.Position = frame.Position

		script.Parent.ChangeSize:Fire()
	end


	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			adjustFrameSize(input.Position.Z, Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

return module