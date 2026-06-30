local HttpService = game:GetService("HttpService")
local PathEditor = {}
PathEditor.__index = PathEditor
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
function PathEditor.new(canvas, gridSize,ModeVal:StringValue,AutoSave)
	local self = setmetatable({}, PathEditor)

	self.canvas = canvas
	self.gridSize = gridSize or Vector2.new(5, 5)

	self.points = {{}}
	self.currentShapeIndex = 1
	self.history = {}
	self.redoHistory = {}

	if canvas:FindFirstChild("Grid") then
		canvas.Grid.TileSize = UDim2.fromScale(2/self.gridSize.X, 2/self.gridSize.Y)
	end

	self.activePaths = {}
	self.verticesFolder = Instance.new("Folder", canvas)
	self.verticesFolder.Name = "Vertices"

	self.previewPath = Instance.new("Path2D", canvas)
	self.previewPath.Color3 = Color3.fromRGB(75, 75, 75)
	self.previewPath.Thickness = 3
	self.Mode = ModeVal.Value
	self.previewPath.ZIndex = 20
	self.ModeVal = ModeVal
	self.AutoSave = AutoSave
	ModeVal.Changed:Connect(function(val)
		self:ChangeMode(val)
	end)
	return self
end

local function deepCopy(target)
	local clone = {}
	for i, shape in ipairs(target) do
		clone[i] = {}
		for _, p in ipairs(shape) do
			table.insert(clone[i], p)
		end
	end
	return clone
end

function PathEditor:ChangeMode(mode)
	if mode == "Add" then
		local mousePos = UserInputService:GetMouseLocation()
		local guiInset = GuiService:GetGuiInset()
		self:UpdatePreview(mousePos,guiInset)
		self.previewPath.Visible = true
	else
		self.previewPath.Visible = false
	end
	self.Mode = mode
end

function PathEditor:SaveState()
	table.insert(self.history, {
		data = deepCopy(self.points), 
		currentIndex = self.currentShapeIndex
	})
	self.redoHistory = {}
end

function PathEditor:GetSnappedPosition(mousePos, guiInset)
	local correctedPos = mousePos - (guiInset or Vector2.zero)
	local relativeX = correctedPos.X - self.canvas.AbsolutePosition.X
	local relativeY = correctedPos.Y - self.canvas.AbsolutePosition.Y

	local nx = math.clamp(relativeX / self.canvas.AbsoluteSize.X, 0, 1)
	local ny = math.clamp(relativeY / self.canvas.AbsoluteSize.Y, 0, 1)

	local snappedNX = math.round(nx * self.gridSize.X) / self.gridSize.X
	local snappedNY = math.round(ny * self.gridSize.Y) / self.gridSize.Y

	return Vector2.new(snappedNX, snappedNY)
end

function PathEditor:RemoveRedoUndo()
	self.history = {}
	self.redoHistory = {}
end

function PathEditor:Render()
	self.verticesFolder:ClearAllChildren()
	for _, p in pairs(self.activePaths) do p:Destroy() end
	self.activePaths = {}

	for shapeIdx, shapePoints in ipairs(self.points) do
		if #shapePoints == 0 then continue end

		local isActive = (shapeIdx == self.currentShapeIndex)
		local color = isActive and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 0, 0)

		local CHUNK_SIZE = 100
		local chunks = {}
		local i = 1
		while i <= #shapePoints do
			local chunk = {}
			for j = i, math.min(i + CHUNK_SIZE - 1, #shapePoints) do
				table.insert(chunk, shapePoints[j])
			end
			table.insert(chunks, chunk)
			i = i + CHUNK_SIZE
			if i <= #shapePoints then
				i = i - 1
			end
		end

		for _, chunk in ipairs(chunks) do
			local path = Instance.new("Path2D")
			path.Color3 = color
			path.Thickness = 3
			path.Parent = self.canvas
			path.ZIndex = 10
			table.insert(self.activePaths, path)

			for ci, pt in ipairs(chunk) do
				path:InsertControlPoint(ci, Path2DControlPoint.new(UDim2.fromScale(pt.X, pt.Y)))
			end
		end

		for _, pt in ipairs(shapePoints) do
			local targetUDim = UDim2.fromScale(pt.X, pt.Y)

			local v = Instance.new("Frame")
			v.Size = self.ModeVal.Value == "Add" and UDim2.fromOffset(5,5) or UDim2.fromOffset(10, 10)
			v.AnchorPoint = Vector2.new(0.5, 0.5)
			v.BackgroundColor3 = color
			v.ZIndex = 11
			local UIStroke = Instance.new("UIStroke")
			UIStroke.Parent = v
			UIStroke.Thickness = 2
			UIStroke.Color = Color3.fromRGB(100, 100, 100)
			UIStroke.Enabled = self.ModeVal.Value == "Delete"
			v.Position = targetUDim
			v.Parent = self.verticesFolder
			local ss: RBXScriptConnection
			ss = self.ModeVal.Changed:Connect(function(val)
				if val == "Add" then
					UIStroke.Enabled = false
					v.Size = UDim2.fromOffset(5, 5)
				else
					UIStroke.Enabled = true
					v.Size = UDim2.fromOffset(10,10)
				end
			end)
			v.Destroying:Connect(function() ss:Disconnect() end)
			Instance.new("UICorner", v).CornerRadius = UDim.new(1, 0)
		end
	end
end

function PathEditor:UpdatePreview(mousePos, guiInset)
	local snapped = self:GetSnappedPosition(mousePos, guiInset)
	local sX, sY = snapped.X, snapped.Y

	local currentShape = self.points[self.currentShapeIndex]
	if currentShape and #currentShape > 0 then
		local lastPt = currentShape[#currentShape]
		local lsX, lsY = lastPt.X, lastPt.Y

		self.previewPath:SetControlPoints({
			Path2DControlPoint.new(UDim2.fromScale(lsX, lsY)),
			Path2DControlPoint.new(UDim2.fromScale(sX, sY))
		})
	else
		self.previewPath:SetControlPoints({})
	end

	return UDim2.fromScale(sX, sY)
end

function PathEditor:AddPoint(mousePos, guiInset)
	local snapped = self:GetSnappedPosition(mousePos, guiInset)
	local currentShape = self.points[self.currentShapeIndex]
	if #currentShape > 0 then
		local lastPt = currentShape[#currentShape]
		if snapped == currentShape then
			return false
		end
	end
	self:SaveState()
	local snapped = self:GetSnappedPosition(mousePos, guiInset)
	table.insert(self.points[self.currentShapeIndex], snapped)
	self:Render()
	return true
end

function PathEditor:RemovePoint(mousePos, guiInset)
	local snapped = self:GetSnappedPosition(mousePos, guiInset)
	for shapeIdx = #self.points, 1, -1 do
		local shape = self.points[shapeIdx]
		for ptIdx = #shape, 1, -1 do
			local pt = shape[ptIdx]
			if pt == snapped then
				self:SaveState()
				table.remove(shape, ptIdx)
				self:Render()
				return true
			end
		end
	end
	return false
end

function PathEditor:StartNewShape()
	local currentShape = self.points[self.currentShapeIndex]
	if currentShape and #currentShape > 0 then
		self:SaveState()
		table.insert(self.points, {})
		self.currentShapeIndex = #self.points
		self:Render()
	end
end

function PathEditor:Undo()
	if #self.history > 0 then
		local currentState = {data = deepCopy(self.points), currentIndex = self.currentShapeIndex}
		table.insert(self.redoHistory, currentState)

		local past = table.remove(self.history, #self.history)
		self.points = past.data
		self.currentShapeIndex = past.currentIndex
		self:Render()
		return true
	end
	return false
end

function PathEditor:Redo()
	if #self.redoHistory > 0 then
		local future = table.remove(self.redoHistory, #self.redoHistory)
		table.insert(self.history, {data = deepCopy(self.points), currentIndex = self.currentShapeIndex})

		self.points = future.data
		self.currentShapeIndex = future.currentIndex
		self:Render()
		return true
	end
	return false
end

function PathEditor:GenerateJSON()
	local exportData = {}
	for _, shape in ipairs(self.points) do
		if #shape > 0 then
			local shapeData = {}
			for _, p in ipairs(shape) do
				local gridX = math.round(p.X * self.gridSize.X)
				local gridY = math.round(p.Y * self.gridSize.Y)
				table.insert(shapeData, {X = gridX, Y = gridY})
			end
			table.insert(exportData, shapeData)
		end
	end
	return HttpService:JSONEncode(exportData)
end

function PathEditor:LoadJSON(jsonString)
	local success, decoded = pcall(function() return HttpService:JSONDecode(jsonString) end)
	if success and type(decoded) == "table" then
		self:SaveState()
		self.points = {}
		for _, shapeData in ipairs(decoded) do
			local newShape = {}
			for _, v in ipairs(shapeData) do
				local posX = v.X / self.gridSize.X
				local posY = v.Y / self.gridSize.Y
				table.insert(newShape, Vector2.new(posX, posY))
			end
			table.insert(self.points, newShape)
		end
		if #self.points == 0 then
			table.insert(self.points, {})
		end

		self.currentShapeIndex = #self.points
		self:Render()
		return true
	end
	return false
end

return PathEditor