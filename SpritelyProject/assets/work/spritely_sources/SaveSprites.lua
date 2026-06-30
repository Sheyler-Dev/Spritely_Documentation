local module = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
function ClickSelection(screen, button: ImageButton, Size: Vector2, canRemove)
	for _, a in pairs(screen:GetChildren()) do
		if a:IsA("ImageButton") then
			if a == button then
				local Pixels = a.ImageContent.Object:ReadPixelsBuffer(Vector2.zero, Size)
				local name = a:GetAttribute("Num") - 1
				local Pixels2 = screen:FindFirstChild(tostring(name))

				if Pixels2 then
					local Pixels2Image = Pixels2.ImageContent.Object:ReadPixelsBuffer(Vector2.zero, Size)
					screen.Parent.Editor.Paper.ImageContent.Object:WritePixelsBuffer(Vector2.zero, Size, Pixels2Image)
				else
					local eraserBufferVariable = buffer.create(Size.X * Size.Y * 4)
					screen.Parent.Editor.Paper.ImageContent.Object:WritePixelsBuffer(Vector2.zero, Size, eraserBufferVariable)
				end
				
				script.Parent.UpdateFrame:Fire()
				
				screen.Parent.Editor:FindFirstChild("ImageLabel").ImageContent.Object:WritePixelsBuffer(Vector2.zero, Size, Pixels)

				if canRemove then
					screen.Parent.RedoUndo:Fire()
				end
			else
				a:SetAttribute("On", false)
				a.UIStroke.Color = Color3.fromRGB(70, 70, 70)
			end
		end
	end
end

function ApplyEffect(button:ImageButton)
	local Ant = false
	button.InputBegan:Connect(function(int)
		if int.UserInputType == Enum.UserInputType.MouseMovement and not Ant then
			Ant = true
			TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(90, 90, 90)}):Play()
		end
	end)
	button.InputEnded:Connect(function(int)
		if int.UserInputType == Enum.UserInputType.MouseMovement then
			Ant = false
			TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
		end
	end)
end

function createDetencion(button: Instance, b: RBXScriptConnection, c: RBXScriptConnection)
	local a
	a = button.AncestryChanged:Connect(function()
		if b then b:Disconnect() end
		if c then c:Disconnect() end
		if a then a:Disconnect() end
	end)
end

function module.save(folder, UI, Size)
	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("ImageButton") then
			if child:GetAttribute("On") == true then
				local Pixels = UI.ImageContent.Object:ReadPixelsBuffer(Vector2.zero, Size)
				child.ImageContent.Object:WritePixelsBuffer(Vector2.zero, Size, Pixels)
				folder.Parent.FrameDates.Value:FindFirstChild(tostring(child:GetAttribute("Num"))):SetAttribute("Image", buffer.tostring(Pixels))
				break
			end
		end
	end
end

function module.SetAttribute(Button, parent, Size, val)
	for _, button in pairs(parent:GetChildren()) do
		if button == Button then
			ClickSelection(parent, button, Size, val) 
			button:SetAttribute("On", true)
			button.UIStroke.Color = Color3.new(1, 1, 1)
		end
	end
end

local function CenterScrollX(Scroll: ScrollingFrame, Obj: GuiObject)
	if not Scroll or not Obj then return end

	local scrollAbsPos = Scroll.AbsolutePosition
	local scrollAbsSize = Scroll.AbsoluteSize
	local canvasAbsSize = Scroll.AbsoluteCanvasSize
	local objAbsPos = Obj.AbsolutePosition
	local objAbsSize = Obj.AbsoluteSize
	local objCanvasX = objAbsPos.X - scrollAbsPos.X + Scroll.CanvasPosition.X

	local targetCanvasX = objCanvasX - (scrollAbsSize.X / 2 - objAbsSize.X / 2)
	local success = pcall(function()
		targetCanvasX = math.clamp(targetCanvasX, 0, canvasAbsSize.X - scrollAbsSize.X)
	end)

	if not success then return end
	local dist = math.abs(Scroll.CanvasPosition.X - targetCanvasX)
	local t = math.clamp(dist / 800, 0, 0.25)
	TweenService:Create(Scroll, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		CanvasPosition = Vector2.new(targetCanvasX, Scroll.CanvasPosition.Y)
	}):Play()
end

function module.create(folder, Size, folders, parents, direction)
	local a
	if not folder then
		a = Instance.new("Folder")
		a.Parent = parents
		a:SetAttribute("VertexData", "[]")

		local NewNumber = 0
		local childs = 0

		for _, buttons: Instance in pairs(folders:GetChildren()) do
			if buttons:IsA("ImageButton") then
				childs += 1
				if buttons:GetAttribute("On") then
					if direction == "Back" then
						NewNumber = buttons:GetAttribute("Num")
					else
						NewNumber = buttons:GetAttribute("Num") + 1
					end
					break
				end
			end
		end

		if NewNumber == 0 then
			NewNumber = childs + 1 
		end

		if childs == 0 then
			NewNumber = 1 
		end

		for _, buttons: Instance in pairs(folders:GetChildren()) do
			if buttons:IsA("ImageButton") then
				if buttons:GetAttribute("Num") >= NewNumber then
					buttons:SetAttribute("Num", buttons:GetAttribute("Num") + 1)
				end
			end
		end

		a.Name = tostring(NewNumber)
		a:SetAttribute("Image", buffer.tostring(buffer.create(Size.X * Size.Y * 4)))
	else
		a = folder
		if not folder:GetAttribute("VertexData") then
			a:SetAttribute("VertexData", "[]")
		end
	end

	local button = folders.UIGridLayout.ImageButton:Clone()
	ApplyEffect(button)
	button:SetAttribute("Num", tonumber(a.Name))
	button.LayoutOrder = tonumber(a.Name)
	button.Num.Text = button:GetAttribute("Num")
	button.Visible = true
	button.Parent = folders
	button.Name = button:GetAttribute("Num")

	local myString = a:GetAttribute("Image")
	local Edit = game.AssetService:CreateEditableImage({Size = Size})	
	Edit:WritePixelsBuffer(Vector2.zero, Size, buffer.fromstring(myString))

	local c = button:GetAttributeChangedSignal("On"):Connect(function()
		local grad = button:FindFirstChildWhichIsA("UIGradient")
		if button:GetAttribute("On") == true then
			if grad then grad.Enabled = false end
			CenterScrollX(button.Parent, button)
		else
			if grad then grad.Enabled = true end
		end
	end)

	local b = button:GetAttributeChangedSignal("Num"):Connect(function()
		button.Name = tostring(button:GetAttribute("Num"))
		button.LayoutOrder = button:GetAttribute("Num")
		button.Num.Text = button.Name
		a.Name = button.Name
	end)

	button.ImageContent = Content.fromObject(Edit)
	button.MouseButton1Click:Connect(function()
		if folders.Parent.IsPlaying.Value == false and button:GetAttribute("On") == false then
			module.SetAttribute(button, folders, Size, true)
		end
	end)

	module.SetAttribute(button, folders, Size, true)
	createDetencion(button, b, c)

	return Edit, button
end

function saveDates(folder: Instance, folders)
	if not folders then return end
	for _, chid in pairs(folder:GetChildren()) do
		if chid:IsA("ImageButton") then
			local EditableImage = chid.ImageContent.Object
			if EditableImage then
				local date = buffer.tostring(EditableImage:ReadPixelsBuffer(Vector2.zero, EditableImage.Size))
				local var = folders:FindFirstChild(tostring(chid:GetAttribute("Num")))
				if var then
					var:SetAttribute("Image", date)
				end
				EditableImage:Destroy()
				chid:Destroy()
			end
		end
	end
end

function CreateDates(obj, Parent)
	local Size = obj:GetAttribute("Size")
	local tableOrden = obj:GetChildren()

	table.sort(tableOrden, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	for _, a in pairs(tableOrden) do
		if Parent.Parent.FrameDates.Value ~= obj then break end
		local e = module.create(a, Size, Parent, obj)
		if a:GetAttribute("Image") ~= "" then
			local image = buffer.fromstring(a:GetAttribute("Image"))
			e:WritePixelsBuffer(Vector2.zero, Size, image)
		end
	end
end

function module.saveSprite(Screen)
	local frame = Screen:FindFirstChild("Frame")
	local Folders = frame:FindFirstChild("SavedSprites")
	local createBtn = frame:FindFirstChild("Create")

	createBtn.MouseButton1Click:Connect(function()
		if frame.IsPlaying.Value == false then
			local IsShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			local Text = IsShift and "Back" or "Forward"
			local Size = frame.FrameDates.Value and frame.FrameDates.Value:GetAttribute("Size")
			module.create(false, Size, frame.SavedSprites, frame.FrameDates.Value, Text)
		end
	end)

	frame:FindFirstChild("SaveChanges").Event:Connect(function()
		local Size = frame.FrameDates.Value and frame.FrameDates.Value:GetAttribute("Size")
		module.save(Folders, frame.Editor.ImageLabel, Size)
	end)

	frame.FrameDates.Changed:Connect(function(obj)
		if script.Parent.Old.Value ~= "" then
			saveDates(frame.SavedSprites, script.Parent.Old.Value)
		end
		CreateDates(obj, frame.SavedSprites)
	end)

	frame.Delete.MouseButton1Click:Connect(function()
		if frame.IsPlaying.Value == false then
			local Num = 0

			for _, button: ImageButton in pairs(frame.SavedSprites:GetChildren()) do
				if button:GetAttribute("On") == true then
					Num = button:GetAttribute("Num")
					local Folder = game.ReplicatedStorage:FindFirstChild("SpriteFolder")
					if Folder then
						local var = script.Parent.Value.Value
						if var then
							local folderImage = var:FindFirstChild("Value")
							if folderImage then
								local NumberTodelete = folderImage.Value:FindFirstChild(tostring(Num))
								if NumberTodelete then
									NumberTodelete:Destroy()
								end
							end
						end
					end
					local Cont = button.ImageContent.Object
					if Cont then Cont:Destroy() end
					button:Destroy()
					break
				end
			end

			local new = nil
			local ButtonsR = 0
			for _, button: ImageButton in pairs(frame.SavedSprites:GetChildren()) do
				if button:IsA("ImageButton") then
					ButtonsR += 1
					if button:GetAttribute("Num") > Num then
						button:SetAttribute("Num", button:GetAttribute("Num") - 1)
						if button:GetAttribute("Num") == Num then
							new = button
							module.SetAttribute(button, frame.SavedSprites, frame.FrameDates.Value:GetAttribute("Size"), true)
						end
					end
				end	
			end

			if new == nil then
				Num = Num - 1
				for _, button: ImageButton in pairs(frame.SavedSprites:GetChildren()) do
					if button:IsA("ImageButton") then
						if button:GetAttribute("Num") == Num then
							module.SetAttribute(button, frame.SavedSprites, frame.FrameDates.Value:GetAttribute("Size"), true)
						end
					end
				end
			end

			if ButtonsR == 0 then
				module.create(false, frame.FrameDates.Value:GetAttribute("Size"), frame.SavedSprites, frame.FrameDates.Value, "Forward")
			end
		end
	end)
end

return module