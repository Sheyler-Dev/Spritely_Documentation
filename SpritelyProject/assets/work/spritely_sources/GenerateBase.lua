local module = {}

function module.BasePlate(model)
	local BaseFrame = model.BasePlate
	local BestSize = model.AbsoluteSize
	local GridSize =model.Grid.Value
	for i, base in pairs(BaseFrame:GetChildren()) do
		if base:IsA("Frame") then
			base:Destroy()
		end
	end
	local COnt = 0
	for X = -BaseFrame.Size.X.Scale, BaseFrame.Size.X.Scale*2, (BaseFrame.Size.X.Scale/GridSize) do
		local newFrameX = Instance.new("Frame", BaseFrame)
		local PosX = X
		newFrameX.Position = UDim2.new(PosX, 0, 0, 0)
		newFrameX.Size = UDim2.new(0, 1, 1, 0)
		newFrameX.BackgroundColor3 = Color3.fromRGB(200, 255, 255)
		newFrameX.BorderSizePixel = 0
		newFrameX.Name = "X"..COnt
		COnt+=1
	end
	local Ultimo = BaseFrame:FindFirstChild("X"..COnt-1)
	if Ultimo then
		Ultimo.Size = UDim2.new(0,4,1,0)
	end
	COnt = 0
	for Y =   -BaseFrame.Size.X.Scale, BaseFrame.Size.X.Scale*2, (BaseFrame.Size.X.Scale/GridSize) do
		local newFrameY = Instance.new("Frame", BaseFrame)
		local PosY = Y
		newFrameY.Position = UDim2.new(0, 0, PosY, 0)
		newFrameY.Size = UDim2.new(1, 0, 0, 1)
		newFrameY.BackgroundColor3 = Color3.fromRGB(200, 255, 255)
		newFrameY.BorderSizePixel = 0
		newFrameY.Name = "Y"..COnt
		COnt+=1
	end
	local Ultimo = BaseFrame:FindFirstChild("Y"..COnt-1)
	if Ultimo then
		Ultimo.Size = UDim2.new(0,4,1,0)
	end
end
return module
