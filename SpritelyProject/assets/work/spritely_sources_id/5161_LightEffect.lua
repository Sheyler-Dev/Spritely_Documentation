--!native
--!optimize 2
local Asset = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpritesFolder = game.ReplicatedStorage:WaitForChild("SpriteFolder")
local Effect = {}

Effect.SystemState = {
	WordIDs = {},
	Buffers = {},
	Lights = {},
	Depths = {},
	NormalDirs = {},
	Actors = {},
	Editables = {}
}

local FRAGMENT_SIZE = 100

local function CreateUniqueId(list)
	local id
	repeat
		id = math.random(10000, 99999)
	until not list[id]
	return id
end

local function ResizeImageBuffer(sourceBuf, originalSize, targetSize:Vector2)
	local w1, h1 = originalSize.X, originalSize.Y
	local w2, h2 = targetSize.X, targetSize.Y

	local newBufSize = w2 * h2 * 4
	local newBuffer = buffer.create(newBufSize)

	local scaleX = w2 / w1
	local scaleY = h2 / h1

	if w1 == w2 and h1 == h2 then
		buffer.copy(newBuffer, 0, sourceBuf, 0, newBufSize)
		return newBuffer, targetSize
	end
	
	local writeu32 = buffer.writeu32
	local readu32 = buffer.readu32

	for y = 0, h2 - 1 do
		local origY = math.floor(y / scaleY)
		local destRowOffset = y * w2 * 4
		local srcRowOffset = origY * w1 * 4

		for x = 0, w2 - 1 do
			local origX = math.floor(x / scaleX)
			local srcOffset = srcRowOffset + (origX * 4)
			local destOffset = destRowOffset + (x * 4)

			writeu32(newBuffer, destOffset, readu32(sourceBuf, srcOffset))
		end
	end

	return newBuffer, Vector2.new(w2, h2)
end

function Effect.AddToImage(ImageLabel:ImageLabel|ImageButton,EditableImage:EditableImage)
	ImageLabel.ImageContent = Content.fromObject(EditableImage)
end

function Effect.CreateWhitBuffer(SpriteName,SpriteFrame,NormalName,NormalFrame)
	local WordId = CreateUniqueId(Effect.SystemState.WordIDs)
	local success, bufColor, bufNormal = pcall(function()
		return buffer.fromstring(SpritesFolder:WaitForChild(SpriteName):WaitForChild(SpriteFrame):GetAttribute("Image")), buffer.fromstring(SpritesFolder:WaitForChild(NormalName):WaitForChild(NormalFrame):GetAttribute("Image"))
	end)
	local finalSize = SpritesFolder:WaitForChild(SpriteName):GetAttribute("Size")
	local editable = Asset:CreateEditableImage({Size = finalSize})
	editable:WritePixelsBuffer(Vector2.zero, finalSize, bufColor)
	Effect.SystemState.WordIDs[WordId] = true
	Effect.SystemState.Buffers[WordId] = {Color = bufColor, Normal = bufNormal}
	Effect.SystemState.Editables[WordId] = editable
	Effect.SystemState.NormalDirs[WordId] = Vector3.new(-1, -1, 1)
	Effect.SystemState.Depths[WordId] = 0.5
	Effect.SystemState.Lights[WordId] = {}
	Effect.SystemState.Actors[WordId] = {}
	local Template = script:WaitForChild("LightActorTemplate")
	local cols = math.ceil(finalSize.X / FRAGMENT_SIZE)
	local rows = math.ceil(finalSize.Y / FRAGMENT_SIZE)

	local actorFolder = game.Players.LocalPlayer.PlayerGui:FindFirstChild("LightActors") 
		or Instance.new("Folder", game.Players.LocalPlayer.PlayerGui)
	actorFolder.Name = "LightActors"

	for y = 0, rows - 1 do
		for x = 0, cols - 1 do
			local actor = Template:Clone()
			actor.Name = "Worker_" .. WordId .. "_" .. x .. "_" .. y

			local startX = x * FRAGMENT_SIZE
			local startY = y * FRAGMENT_SIZE
			local endX = math.min((x + 1) * FRAGMENT_SIZE, finalSize.X)
			local endY = math.min((y + 1) * FRAGMENT_SIZE, finalSize.Y)

			actor:SetAttribute("StartX", startX)
			actor:SetAttribute("StartY", startY)
			actor:SetAttribute("EndX", endX)
			actor:SetAttribute("EndY", endY)
			actor:SetAttribute("ImageWidth", finalSize.X) 
			actor.Parent = actorFolder
			table.insert(Effect.SystemState.Actors[WordId], actor)
		end
	end
	return WordId, editable
end

function Effect.CreateBuffer(ColorMapId, NormalMapId, ImageSize)
	local success, colorImg, normalImg = pcall(function()
		return Asset:CreateEditableImageAsync(Content.fromAssetId(ColorMapId)), Asset:CreateEditableImageAsync(Content.fromAssetId(NormalMapId))
	end)

	if not success then warn("Failed to load images"); return nil end

	local WordId = CreateUniqueId(Effect.SystemState.WordIDs)

	local bufColor, finalSize = ResizeImageBuffer(colorImg:ReadPixelsBuffer(Vector2.zero, colorImg.Size), colorImg.Size, ImageSize)
	local bufNormal, _ = ResizeImageBuffer(normalImg:ReadPixelsBuffer(Vector2.zero, normalImg.Size), normalImg.Size, ImageSize)

	local editable = Asset:CreateEditableImage({Size = finalSize})
	editable:WritePixelsBuffer(Vector2.zero, finalSize, bufColor)
	
	
	Effect.SystemState.WordIDs[WordId] = true
	Effect.SystemState.Buffers[WordId] = {Color = bufColor, Normal = bufNormal}
	Effect.SystemState.Editables[WordId] = editable
	Effect.SystemState.NormalDirs[WordId] = Vector3.new(-1, -1, 1)
	Effect.SystemState.Depths[WordId] = 0.5
	Effect.SystemState.Lights[WordId] = {}
	Effect.SystemState.Actors[WordId] = {}

	local Template = script:WaitForChild("LightActorTemplate")
	local cols = math.ceil(finalSize.X / FRAGMENT_SIZE)
	local rows = math.ceil(finalSize.Y / FRAGMENT_SIZE)

	local actorFolder = game.Players.LocalPlayer.PlayerGui:FindFirstChild("LightActors") 
		or Instance.new("Folder", game.Players.LocalPlayer.PlayerGui)
	actorFolder.Name = "LightActors"

	for y = 0, rows - 1 do
		for x = 0, cols - 1 do
			local actor = Template:Clone()
			actor.Name = "Worker_" .. WordId .. "_" .. x .. "_" .. y

			local startX = x * FRAGMENT_SIZE
			local startY = y * FRAGMENT_SIZE
			local endX = math.min((x + 1) * FRAGMENT_SIZE, finalSize.X)
			local endY = math.min((y + 1) * FRAGMENT_SIZE, finalSize.Y)

			actor:SetAttribute("StartX", startX)
			actor:SetAttribute("StartY", startY)
			actor:SetAttribute("EndX", endX)
			actor:SetAttribute("EndY", endY)
			actor:SetAttribute("ImageWidth", finalSize.X)
			actor.Parent = actorFolder
			table.insert(Effect.SystemState.Actors[WordId], actor)
			
		end
	end
	colorImg:Destroy()
	normalImg:Destroy()
	return WordId, editable
end

function Effect.ChangeDir(ID,Direction:Vector3)
	if typeof(Direction) ~= "Vector3" then
		warn("Invalid direction type. Expected Vector3.")
		return
	end
	Effect.SystemState.NormalDirs[ID] = Direction
end

local function DispatchUpdate(ID)
	local actors = Effect.SystemState.Actors[ID]
	if not actors then return end

	local depth = Effect.SystemState.Depths[ID]
	local editable = Effect.SystemState.Editables[ID]
	local bufs = Effect.SystemState.Buffers[ID]
	local lights = Effect.SystemState.Lights[ID]
	local normDir = Effect.SystemState.NormalDirs[ID]
	
	local lightData = {}
	for _, l in pairs(lights) do
		local pos = l.Position or Vector2.zero
		local lCol = l.Color or Color3.new(1, 1, 1)
		table.insert(lightData, pos.X)
		table.insert(lightData, pos.Y)
		table.insert(lightData, l.Range or 0.5)
		table.insert(lightData, l.Brightness or 0.5)
		table.insert(lightData, lCol.R)
		table.insert(lightData, lCol.G)
		table.insert(lightData, lCol.B)
	end

	for _, actor in ipairs(actors) do
		actor:SendMessage("UpdateRender", 
			editable, 
			bufs.Color, 
			bufs.Normal, 
			lightData, 
			normDir, 
			depth
		)
	end
end

function Effect.AddLight(ID, Attr)
	local LightID = CreateUniqueId({})
	Effect.SystemState.Lights[ID][LightID] = Attr
	DispatchUpdate(ID)
	return LightID
end

function Effect.UpdateLight(ID, LightID, Attr)
	local l = Effect.SystemState.Lights[ID][LightID]
	if l then
		if Attr.Position then l.Position = Attr.Position end
		if Attr.Brightness then l.Brightness = Attr.Brightness end
		if Attr.Range then l.Range = Attr.Range end
		DispatchUpdate(ID)
	end
end

function Effect.RemoveLight(ID, LightID)
	Effect.SystemState.Lights[ID][LightID] = nil
	DispatchUpdate(ID)
end

function Effect.ChangeDepth(ID, val)
	Effect.SystemState.Depths[ID] = val
	DispatchUpdate(ID)
end

return Effect