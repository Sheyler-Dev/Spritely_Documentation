local module = {}
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HTTP = game:GetService("HttpService")
local twenService = game:GetService("TweenService")


local function isOpaque(pixels, x, y, sizeX, sizeY)
	if x < 0 or y < 0 or x >= sizeX or y >= sizeY then return false end
	return buffer.readu8(pixels, (y * sizeX + x) * 4 + 3) > 128
end

local function getConvexHull(points)
	local n = #points
	if n <= 3 then 
		return points 
	end

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
	return lower
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


function module.New(main:Frame,Folder:Folder,Editable:EditableImage,extraDisable:TextButton)
	local SpritelyCollision = require(script.Parent.Spritely.GenerateObject)
	main.Canvas.ImageRender.ImageContent = Content.fromObject(Editable)
	local PathEditorModule = require(script.PathEditorModule)
	local canvas = main:WaitForChild("Canvas")
	local tools = main:WaitForChild("Tools")
	local LastConnection:RBXScriptConnection = nil
	local editor = PathEditorModule.new(canvas, Editable.Size,main.Tools.ModeVal)
	
	editor:Render()
	local function CanClick()
		return main.CanClick.Value
	end
	
	for i,a in pairs(main.Tools.Mode:GetChildren()) do
		if a:IsA("ImageButton") then
			a.MouseButton1Click:Connect(function()
				if CanClick() then
					main.Tools.ModeVal.Value = a.Name
					for i,a in pairs(main.Tools.Mode:GetChildren()) do
						if a:IsA("ImageButton") then
							a.UIStroke.Enabled = false
						end
					end
					a.UIStroke.Enabled = true
				end
			end)
		end
	end
	
	main.Tools.AutoSave.Check.MouseButton1Click:Connect(function()
		if CanClick() then
			main.Tools.AutoSave.Value.Value = not main.Tools.AutoSave.Value.Value
		end
	end)
	local function SaveNewData(Folder)
		local json = editor:GenerateJSON()
		Folder = Folder or main.Tools.FolderValue.Value
		if Folder then
			Folder:SetAttribute("VertexData", json)
		end
	end
	local function UpdateCheck(val)
		local position = UDim2.fromScale(0.05,0.5)
		local color = Color3.fromRGB(152, 152, 152)
		if val then
			position = UDim2.fromScale(.6,0.5)
			color = Color3.fromRGB(48, 114, 255)
		end
		twenService:Create(main.Tools.AutoSave.Check.Frame,TweenInfo.new(.2,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out),{Position = position}):Play()
		twenService:Create(main.Tools.AutoSave.Check,TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{BackgroundColor3 = color}):Play()	
		if val then
			SaveNewData()
		end
	end
	main.Tools.AutoSave.Value.Changed:Connect(UpdateCheck)
	main.Close.MouseButton1Click:Connect(function()
		main.Parent.Enabled = false
	end)

	local previewVertex = main.Canvas:WaitForChild("Frame")

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local cursorPosition = editor:UpdatePreview(
				UserInputService:GetMouseLocation(), 
				GuiService:GetGuiInset()
			)
			previewVertex.Position = cursorPosition
		end
	end)
	
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if not CanClick() or main.Parent.Enabled == false then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if main.Tools.ModeVal.Value == "Add" then 
			local Can = editor:AddPoint(UserInputService:GetMouseLocation(), GuiService:GetGuiInset())
				if Can and main.Tools.AutoSave.Value.Value then
					local json = editor:GenerateJSON()
					local Folder = main.Tools.FolderValue.Value
					if Folder then
						Folder:SetAttribute("VertexData", json)
					end
				end	
			elseif main.Tools.ModeVal.Value == "Delete" then
				local Can = editor:RemovePoint(UserInputService:GetMouseLocation(), GuiService:GetGuiInset())
				if Can and main.Tools.AutoSave.Value.Value then
					local json = editor:GenerateJSON()
					local Folder = main.Tools.FolderValue.Value
					if Folder then
						Folder:SetAttribute("VertexData", json)
					end
				end		
			end	
		end
	end)

	tools.NewPoint.MouseButton1Click:Connect(function()
		if not CanClick() or main.Parent.Enabled == false then return end
		editor:StartNewShape()
	end)

	tools.Undo_Redo.Undo.MouseButton1Click:Connect(function()
		if not CanClick() or main.Parent.Enabled == false then return end
		local mousePos = UserInputService:GetMouseLocation()
		local guiInset = GuiService:GetGuiInset()
		editor:UpdatePreview(mousePos, guiInset)
		local Can = editor:Undo()
		if Can and main.Tools.AutoSave.Value.Value then
			local json = editor:GenerateJSON()
			local Folder = main.Tools.FolderValue.Value
			if Folder then
				Folder:SetAttribute("VertexData", json)
			end
		end	
	end)

	tools.Undo_Redo.Redo.MouseButton1Click:Connect(function()
		if not CanClick() or main.Parent.Enabled == false then return end
		local Can = editor:Redo()
		if Can and main.Tools.AutoSave.Value.Value then
			local json = editor:GenerateJSON()
			local Folder = main.Tools.FolderValue.Value
			if Folder then
				Folder:SetAttribute("VertexData", json)
			end
		end	
		local mousePos = UserInputService:GetMouseLocation()
		local guiInset = GuiService:GetGuiInset()
		editor:UpdatePreview(mousePos, guiInset)
	end)
	
	local function Update(IsMe)
		if IsMe then
			local editableData = buffer.fromstring(IsMe:GetAttribute("Image"))
			Editable:WritePixelsBuffer(Vector2.zero,Editable.Size,editableData)
			if LastConnection then
				if LastConnection.Connected then
					LastConnection:Disconnect()
					LastConnection = nil
				end
			end
			LastConnection = IsMe:GetAttributeChangedSignal("Image"):Connect(function()
				local editableData = buffer.fromstring(IsMe:GetAttribute("Image"))
				Editable:WritePixelsBuffer(Vector2.zero,Editable.Size,editableData)
			end)
		else
			for i,a in pairs(main.Tools.ScrollingFrame:GetChildren()) do
				if a:IsA("TextButton") then
					if a:GetAttribute("On") then
						local foldername = Folder:FindFirstChild(a.Text)
						if foldername then
							local editableData = buffer.fromstring(foldername:GetAttribute("Image"))
							Editable:WritePixelsBuffer(Vector2.zero,Editable.Size,editableData)
							LastConnection = foldername:GetAttributeChangedSignal("Image"):Connect(function()
								local editableData = buffer.fromstring(foldername:GetAttribute("Image"))
								Editable:WritePixelsBuffer(Vector2.zero,Editable.Size,editableData)
							end)	
						end
					end
				end
			end
		end
	end
	
	extraDisable:GetPropertyChangedSignal("Visible"):Connect(function()
		if extraDisable.Visible == false then
			if extraDisable.Parent.Parent.Parent.Visible then
				main.Parent.Enabled = false
			end
		end	
		
	end)
	
	tools.SaveChange.MouseButton1Click:Connect(function()
		if not CanClick() or main.Parent.Enabled == false then return end
		local json = editor:GenerateJSON()
		local Folder:Instance|nil = main.Tools.FolderValue.Value
		if Folder then
			if Folder.Parent and Folder.Parent.Parent then
				Folder:SetAttribute("VertexData", json)
			end
		end
	end)
	local function getOns()
		for i,a in pairs(main.Tools.ScrollingFrame:GetChildren()) do
			if a:IsA("TextButton") then
				a.UIStroke.Enabled = a:GetAttribute("On")
				if a:GetAttribute("On") then
					main.Tools.FolderValue.Value = Folder:FindFirstChild(a.Text)
				end
			end		
		
		end
	end
	
	
	local function SetUpButton(a)
		local nButton = main.Tools.ScrollingFrame.UIGridLayout.Buttons:Clone()
		nButton.Text = a.Name
		nButton.Name = a.Name
		nButton.Parent = main.Tools.ScrollingFrame
		nButton.Visible = true
		if a.Name == "1" then
			nButton:SetAttribute("On",true)
			getOns()
			Update(a)
			local json = a:GetAttribute("VertexData")
			if json then
				editor:LoadJSON(json)
			end
		end
		nButton.MouseButton1Click:Connect(function()
			if not CanClick() then return end
			local json = a:GetAttribute("VertexData")
			if json then
				editor:LoadJSON(json)
			end
			if nButton:GetAttribute("On") == false then
				for i,a in pairs(main.Tools.ScrollingFrame:GetChildren()) do
					if a:IsA("TextButton") then
						a:SetAttribute("On",false)
					end
				end
				nButton:SetAttribute("On",true)
				getOns()
				Update(a)
				local mousePos = UserInputService:GetMouseLocation()
				local guiInset = GuiService:GetGuiInset()
				editor:UpdatePreview(mousePos,guiInset)
				editor:RemoveRedoUndo()
			end
		end)
		
		a:GetPropertyChangedSignal("Name"):Connect(function()
			nButton.Text = a.Name
			nButton.Text = a.Name
		end)
	end
	
	for i,a in pairs(Folder:GetChildren()) do
		if a:IsA("Folder") then
			SetUpButton(a)
		end
	end
	
	Folder.ChildAdded:Connect(function(a)
		if a:IsA("Folder") then
			SetUpButton(a)
		end
	end)
	
	Folder.ChildRemoved:Connect(function(a)
		if a:IsA("Folder") then
			for i,b in pairs(main.Tools.ScrollingFrame:GetChildren()) do
				if b:IsA("TextButton") then
					if b.Text == a.Name then
						if b:GetAttribute("On") then
							local newA = Folder:FindFirstChild(b.Text)
							if not newA then
								newA = Folder:FindFirstChild(tonumber(b.Text)+1)
								if not newA then
									newA = Folder:FindFirstChild(tonumber(b.Text)-1)
								end
							end	
							if newA then
								local obj = b.Parent:FindFirstChild(newA.Name)
								if obj then
									obj:SetAttribute("On",true)
									Update(newA)
								end
							end
						end
						b:Destroy()
						getOns()
						break
					end
				end
			end
		end
	end)

	local Orden = {}
	for i,a:Instance in pairs(main.Parent.ChoiseData:GetChildren()) do
		if a:IsA("Frame") or a:IsA("TextButton") then
			Orden[a] = a.Visible
		end
	end
	
	main.Load.Changed:Connect(function(val:number)
		local Max = main.Load:GetAttribute("Max")
		local Bar = main.Parent.ChoiseData.Loading.Bar.Bar
		Bar:TweenSize(UDim2.fromScale(val/Max,1),Enum.EasingDirection.Out,Enum.EasingStyle.Linear,0.1)
	end)
	main.Load:GetAttributeChangedSignal("Max"):Connect(function()
		local Max = main.Load:GetAttribute("Max")
		local Bar = main.Parent.ChoiseData.Loading.Bar.Bar
		Bar:TweenSize(UDim2.fromScale(main.Load.Value/Max,1),Enum.EasingDirection.Out,Enum.EasingStyle.Linear,0.1)
	end)
	
	local function ConvertPathsToJSON(paths,gridSize)
		local exportData = {}

		for _, shape in ipairs(paths) do
			local shapeData = {}
			for _, p in ipairs(shape) do
				
				local nx = p.X / gridSize.X
				local ny = p.Y / gridSize.Y

				local gridX = math.round(nx * gridSize.X)
				local gridY = math.round(ny * gridSize.Y)

				table.insert(shapeData, {X = gridX, Y = gridY})
			end
			if #shapeData > 0 then
				table.insert(exportData, shapeData)
			end
		end

		return exportData
	end
	
	local GetData = Instance.new("BindableFunction",script)
	local GetData2 = Instance.new("BindableFunction",script)
	function GetData2.OnInvoke()
		main.Parent.ChoiseData.Ops2.Visible = true
		local Can = nil
		local ns:RBXScriptConnection,ns2:RBXScriptConnection
		ns = main.Parent.ChoiseData.Ops2.Yes.MouseButton1Click:Connect(function()
			Can = true
			ns:Disconnect()
			ns2:Disconnect()
		end)
		ns2 = main.Parent.ChoiseData.Ops2.No.MouseButton1Click:Connect(function()
			Can = false
			ns:Disconnect()
			ns2:Disconnect()
		end)
		
		while Can == nil do
			task.wait()
		end
		main.Parent.ChoiseData.Ops2.Visible = false
		return Can
	end
	function GetData.OnInvoke()
		local Can = 0
		for i,a in pairs(Orden) do
			i.Visible = a
		end
		local ns:RBXScriptConnection,ns2:RBXScriptConnection,ns3:RBXScriptConnection
		ns = main.Parent.ChoiseData.Ops.All.MouseButton1Click:Connect(function()
			Can = 1
			ns:Disconnect()
			ns2:Disconnect()
			ns3:Disconnect()
		end)
		ns2 = main.Parent.ChoiseData.Ops.Only.MouseButton1Click:Connect(function()
			Can = 2
			ns:Disconnect()
			ns2:Disconnect()
			ns3:Disconnect()
		end)
		ns3 = main.Parent.ChoiseData.Frame.TextButton.MouseButton1Click:Connect(function()
			ns:Disconnect()
			ns2:Disconnect()
			ns3:Disconnect()
			Can = 3
		end)
		main.Parent.ChoiseData.Visible = true
		while Can == 0 do
			task.wait()
		end
		if Can == 1 then
			return true
		elseif Can == 2 then
			return false
		else
			return nil
		end
	end
	main.Tools.AutoGenerate.MouseButton1Click:Connect(function()
		if not CanClick() then return end
		main.CanClick.Value = false
		main.Parent.ChoiseData.Frame.TextButton.Visible = true
		local Can = GetData:Invoke()
		if Can == nil then
			main.Parent.ChoiseData.Visible = false
			main.CanClick.Value = true
			return
		end
		main.Parent.ChoiseData.Frame.TextButton.Visible = false
		main.Parent.ChoiseData.Ops.Visible = false
		main.Parent.ChoiseData.Message.Visible = false
		main.Parent.ChoiseData.Message2.Visible = true
		main.Parent.ChoiseData.Cancel.Visible = true
		local data = {Resolution = 1}
		local IsConvex = GetData2:Invoke()
		main.Parent.ChoiseData.Message2.Visible = false
		main.Parent.ChoiseData.Message3.Visible = true
		local Conect = GetData2:Invoke()
		main.Parent.ChoiseData.Message3.Visible = false
		main.Parent.ChoiseData.Loading.Visible = true
		local size = Editable.Size
		if Can == false then
			local a = main.Tools.FolderValue.Value
			main.Load:SetAttribute("Max",1)
			main.Load.Value = 0
			if a then	
				local can,Err = pcall(function()
					local pixels = buffer.fromstring(a:GetAttribute("Image"))
					local Resolution = data.Resolution or 1
					local paths 
					if not IsConvex then
						paths = ConvertPathsToJSON(GetPaths(pixels, size.X, size.Y,Resolution,Conect),size)
					else
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

						if not found then return {} end
						paths = ConvertPathsToJSON({getConvexHull(extremePoints,Conect)},size)
					end	
					local stringPaths = HTTP:JSONEncode(paths)
					a:SetAttribute("VertexData",stringPaths)
					local button = main.Tools.ScrollingFrame:FindFirstChild(a.Name)
					if button and button:GetAttribute("On") then
						editor:LoadJSON(stringPaths)
						local mousePos = UserInputService:GetMouseLocation()
						local guiInset = GuiService:GetGuiInset()
						editor:Render()
						editor:UpdatePreview(mousePos,guiInset)
					end
				end)
				main.Load.Value = 1
				if not can then
					warn("Error with Frame",a.Name,Err)
				end
			end
		else
			local Childs = Folder:GetChildren()
			local Max = #Childs
			main.Load:SetAttribute("Max",Max)
			main.Load.Value = 0
			for i,a in pairs(Folder:GetChildren()) do
				if a:IsA("Folder") then
					local can,Err = pcall(function()
						local pixels = buffer.fromstring(a:GetAttribute("Image"))
						local Resolution = data.Resolution
						local paths 
						if not IsConvex then
							paths = ConvertPathsToJSON(GetPaths(pixels, size.X, size.Y,Resolution,Conect),size)
						else
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

							if not found then return {} end
							paths = ConvertPathsToJSON({getConvexHull(extremePoints,Conect)},size)
						end	
						local stringPaths = HTTP:JSONEncode(paths)
						a:SetAttribute("VertexData",stringPaths)
						local button = main.Tools.ScrollingFrame:FindFirstChild(a.Name)
						if button and button:GetAttribute("On") then
							editor:LoadJSON(stringPaths)
							local mousePos = UserInputService:GetMouseLocation()
							local guiInset = GuiService:GetGuiInset()
							editor:Render()
							editor:UpdatePreview(mousePos,guiInset)
						end
					end)
					if not can then
						warn("Error with Frame",a.Name,Err)
					end
					task.wait()
					main.Load.Value+=1
				end
			end
		end
		main.Parent.ChoiseData.Visible = false
		main.CanClick.Value = true
	end)
end

return module
