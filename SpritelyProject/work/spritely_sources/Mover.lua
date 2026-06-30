local module = {}
function module.UInput(frame:Frame)
	local UserInputService = game:GetService("UserInputService")
	
	local parent = frame.Parent

	local dragging = false
	local inputConnection = nil

	local function clampToParentScale(pos)
		local x,y = math.clamp(pos.X.Scale, 0, 1),math.clamp(pos.Y.Scale, 0, 1)
		return UDim2.new(
			x,
			0,
			y,
			0
		),Vector2.new(x,y)
	end

	local function getRelativeScalePosition(mousePos)
		local absPos = parent.AbsolutePosition
		local absSize = parent.AbsoluteSize

		local relX = (mousePos.X - absPos.X) / absSize.X
		local relY = (mousePos.Y - absPos.Y) / absSize.Y

		return UDim2.new(relX, 0, relY, 0)
	end

	UserInputService.InputChanged:Connect(function(moveInput)
		if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
			local newPos = getRelativeScalePosition(moveInput.Position)
			local Position
			frame.Position,Position = clampToParentScale(newPos)
			local ImageSize:Vector2 = parent.ImageContent.Object.Size
			local PointOnImage = Vector2.new(Position.X*(ImageSize.X-1),Position.Y*(ImageSize.Y-1))
			local ImageColor:buffer =parent.ImageContent.Object:ReadPixelsBuffer(PointOnImage,Vector2.one)
			local R,G,B = buffer.readu8(ImageColor,0),buffer.readu8(ImageColor,1),buffer.readu8(ImageColor,2)
			local Color = Color3.fromRGB(R,G,B)
			frame.Parent.Parent.RGB.Value = Color
		end
	end)

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local newPos = getRelativeScalePosition(input.Position)
			local Position
			frame.Position,Position = clampToParentScale(newPos)
			local ImageSize:Vector2 = parent.ImageContent.Object.Size
			local PointOnImage = Vector2.new(Position.X*(ImageSize.X-1),Position.Y*(ImageSize.Y-1))
			local ImageColor:buffer =parent.ImageContent.Object:ReadPixelsBuffer(PointOnImage,Vector2.one)
			local R,G,B = buffer.readu8(ImageColor,0),buffer.readu8(ImageColor,1),buffer.readu8(ImageColor,2)
			local Color = Color3.fromRGB(R,G,B)
			frame.Parent.Parent.RGB.Value = Color
			dragging = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			if inputConnection then
				inputConnection:Disconnect()
				inputConnection = nil
			end
		end
	end)

	parent.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local newPos = getRelativeScalePosition(input.Position)
			local Position
			frame.Position,Position = clampToParentScale(newPos)
			local ImageSize:Vector2 = parent.ImageContent.Object.Size
			local PointOnImage = Vector2.new(Position.X*(ImageSize.X-1),Position.Y*(ImageSize.Y-1))
			local ImageColor:buffer =parent.ImageContent.Object:ReadPixelsBuffer(PointOnImage,Vector2.one)
			local R,G,B = buffer.readu8(ImageColor,0),buffer.readu8(ImageColor,1),buffer.readu8(ImageColor,2)
			local Color = Color3.fromRGB(R,G,B)
			frame.Parent.Parent.RGB.Value = Color
			dragging = true
		end
	end)
end
return module
