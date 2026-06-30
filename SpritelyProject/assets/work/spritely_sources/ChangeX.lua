local UserInputService = game:GetService("UserInputService")
local module = {}
module.Maxs = {}
module.textboxs = {}
local textbox = require(script.Parent:WaitForChild("Textbox"))

function module.ChangeMaxs(frame: Frame, newMaxs: Vector2, currentChangeVal)
	module.Maxs[frame] = newMaxs
	if module.textboxs[frame] then
		module.textboxs[frame].min = newMaxs.X
		module.textboxs[frame].max = newMaxs.Y
	end
	if currentChangeVal then
		local minVal = newMaxs.X
		local maxVal = newMaxs.Y
		local range = maxVal - minVal
		local clampedVal = math.clamp(currentChangeVal.Value, minVal, maxVal)
		local normalizedX = (range > 0) and ((clampedVal - minVal) / range) or 0
		normalizedX = math.clamp(normalizedX, 0, 1)
		frame.Position = UDim2.new(normalizedX, 0, frame.Position.Y.Scale, 0)
		currentChangeVal.Value = clampedVal
	end
end

function module.MoveOnX(frame: Frame, ChangeVal: NumberValue, MinMax: Vector2)
	local parent = frame.Parent
	local dragging = false
	module.Maxs[frame] = MinMax
	local text 
	local box = parent.Parent:FindFirstChildWhichIsA("TextBox")
	if box then
		text = textbox.new(box,{["MinNumber"] = MinMax.X,["MaxNumber"] = MinMax.Y})
		module.textboxs[frame] = text
		function text.onChanged(value)
			ChangeVal.Value = value
		end
		ChangeVal.Changed:Connect(function(value)
			local minVal = module.Maxs[frame].X
			local maxVal = module.Maxs[frame].Y
			local range = maxVal - minVal
			local normalizedX = (range > 0) and ((value - minVal) / range) or 0
			normalizedX = math.clamp(normalizedX, 0, 1)
			frame.Position = UDim2.new(normalizedX, 0, 0.5, 0)
			text.textBox.Text = tostring(value)
		end)
	end
	
	local function updatePosition(mousePos)
		local absPos = parent.AbsolutePosition
		local absSize = parent.AbsoluteSize

		local relX = math.clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)

		local minVal = module.Maxs[frame].X
		local maxVal = module.Maxs[frame].Y
		local range = maxVal - minVal

		local realValue = minVal + (relX * range)
		local snappedValue = math.round(realValue) 
		
		local finalRelX = (range > 0) and ((snappedValue - minVal) / range) or 0

		frame.Position = UDim2.new(finalRelX, 0, 0.5, 0)
		ChangeVal.Value = math.clamp(snappedValue, minVal, maxVal)
	end
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updatePosition(input.Position)
		end
	end)

	parent.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updatePosition(input.Position)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement) then
			updatePosition(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	return text
end

return module