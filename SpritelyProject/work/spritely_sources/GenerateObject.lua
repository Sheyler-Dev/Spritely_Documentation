--!native
local module = {}
module.CreatedColliders = {} 
module.CenterOfMass = {}
module.CreatedSprites = {}
module.Sizes = {}
local AnimationsFolder = require(script.Parent:WaitForChild("AnimationsFolder"))
local CollisionGenerator = require(script.Parent:WaitForChild("CollisionType"))
module.CollisionType = {}
module.Types = {
	"Static",
	"Dynamic"
}
module.CollisionTypes = {
	"Box",
	"Radial",
	"Precise",
	"Convex",
	"Custom"
}

local AssetService = game:GetService("AssetService")

function DrawCollisionDebug(ImageObject:ImageLabel|ImageButton, paths, CenterOfMass, spriteSize, visible, collisiontype,Frame:number,currentFrame:number)
	local SpriteCollider:Frame = ImageObject:FindFirstChild("ColliderMap") or Instance.new("Frame", ImageObject)
	SpriteCollider.Name = "ColliderMap"
	SpriteCollider.BackgroundTransparency = 1
	SpriteCollider.Size = UDim2.fromScale(1, 1)
	SpriteCollider.Visible = visible
	SpriteCollider.ZIndex = 1000
	local SpriteFrame = SpriteCollider:FindFirstChild("_"..Frame) or Instance.new("Frame", SpriteCollider)
	SpriteFrame.Name = "_"..Frame
	SpriteFrame.BackgroundTransparency = 1
	SpriteFrame.Size = UDim2.fromScale(1, 1)
	SpriteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	SpriteFrame.Position = UDim2.fromScale(.5,.5)
	SpriteFrame.ZIndex = 1001
	SpriteFrame.Visible = currentFrame==Frame
	local grosor = 2
	if collisiontype == "Box" or collisiontype == "Custom" or collisiontype == "Precise" or collisiontype == "Convex" then
		local pointColor = Color3.fromRGB(255, 0, 0)
		local lineColor = Color3.fromRGB(0, 85, 255)

		for pathIdx, vertices in ipairs(paths) do
			local currentPathObj = nil
			local pointsInCurrentPath = 0
			local function CreateNewPath()
				local p = Instance.new("Path2D", SpriteFrame)
				p.Name = "Path_" .. pathIdx .. "_Seg"
				p.Thickness = grosor
				p.Color3 = lineColor
				p.ZIndex = 1000
				return p
			end

			currentPathObj = CreateNewPath()

			for i, v in ipairs(vertices) do
				if pointsInCurrentPath >= 100 then
					local lastPoint = vertices[i-1]
					currentPathObj = CreateNewPath()
					currentPathObj:InsertControlPoint(1, Path2DControlPoint.new(UDim2.fromScale(lastPoint.X / spriteSize.X, lastPoint.Y / spriteSize.Y)))
					pointsInCurrentPath = 1
				end

				local pos = UDim2.fromScale(v.X / spriteSize.X, v.Y / spriteSize.Y)
				local dot = Instance.new("Frame", SpriteFrame)
				dot.Name = "__CollisionVertex"
				dot.BackgroundColor3 = pointColor
				dot.BorderSizePixel = 0
				dot.Size = UDim2.fromOffset(5, 5)
				dot.AnchorPoint = Vector2.new(0.5, 0.5)
				dot.Position = pos
				dot.ZIndex = 1005
				pointsInCurrentPath += 1
				currentPathObj:InsertControlPoint(pointsInCurrentPath, Path2DControlPoint.new(pos))
			end
			if #vertices > 0 then
				local firstV = vertices[1]
				local pos = UDim2.fromScale(firstV.X / spriteSize.X, firstV.Y / spriteSize.Y)

				if pointsInCurrentPath < 100 then
					currentPathObj:InsertControlPoint(pointsInCurrentPath + 1, Path2DControlPoint.new(pos))
				else
					local lastV = vertices[#vertices]
					local closerPath = CreateNewPath()
					closerPath:InsertControlPoint(1, Path2DControlPoint.new(UDim2.fromScale(lastV.X / spriteSize.X, lastV.Y / spriteSize.Y)))
					closerPath:InsertControlPoint(2, Path2DControlPoint.new(pos))
				end
			end
		end
	elseif collisiontype == "Radial" then
		local RadialObj = Instance.new("Frame", SpriteFrame)
		RadialObj.Name = "Radial"
		RadialObj.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		RadialObj.BorderSizePixel = 0
		RadialObj.Size = UDim2.fromScale(paths * 2 / spriteSize.X, paths * 2 / spriteSize.Y)
		RadialObj.AnchorPoint = Vector2.new(0.5, 0.5)
		local center = CenterOfMass / spriteSize
		RadialObj.Position = UDim2.fromScale(center.X, center.Y)
		RadialObj.Visible = true
		RadialObj.ZIndex = 1000
		RadialObj.BackgroundTransparency = 0.75

		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(1, 0)
		uicorner.Parent = RadialObj
	end
	ImageObject:GetAttributeChangedSignal("Frame"):Connect(function()
		local cF = ImageObject:GetAttribute("Frame")
		local visible =  cF==Frame
		SpriteFrame.Visible = visible
	end)
	local CenterOfMassFrame = Instance.new("Frame")
	CenterOfMassFrame.Name = "CenterOfMass"
	CenterOfMassFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	CenterOfMassFrame.BorderSizePixel = 0
	CenterOfMassFrame.Size = UDim2.fromOffset(10, 10)
	local uicornerCOM = Instance.new("UICorner")
	uicornerCOM.CornerRadius = UDim.new(1, 0)
	uicornerCOM.Parent = CenterOfMassFrame
	CenterOfMassFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	CenterOfMassFrame.Position = UDim2.fromScale(CenterOfMass.X / spriteSize.X, CenterOfMass.Y / spriteSize.Y)
	CenterOfMassFrame.ZIndex = 1001
	CenterOfMassFrame.Parent = SpriteFrame
	return SpriteCollider
end

function module.SetPixelHash(ImageObject: ImageLabel | ImageButton, SpriteFolder: string, Frame: number?, Type:string)
	Frame = Frame or 1
	local FolderImage = game.ReplicatedStorage:WaitForChild("SpriteFolder"):FindFirstChild(SpriteFolder)
	if not FolderImage then warn("Error. No sprite folder")return end
	if not Type or typeof(Type)~="string" then
		warn("Error. No type")
		return
	end
	
	if not table.find(module.Types,Type) then
		warn("Error. No type")
		return
	end
	
	ImageObject:SetAttribute("Type",Type)
	local size = FolderImage:GetAttribute("Size")
	local CollisionType = FolderImage:GetAttribute("CollisionType")
	if not CollisionType or not table.find(module.CollisionTypes, CollisionType) then
		CollisionType = "Precise"
	end
	if not module.CreatedSprites[SpriteFolder] then
		local Childs = FolderImage:GetChildren()
		module.CreatedColliders[SpriteFolder] = {}
		module.CenterOfMass[SpriteFolder] = {}
		table.sort(Childs, function(a, b) return tonumber(a.Name) < tonumber(b.Name) end)
		local frames = {}
		local frameStatic = {}
		local Data = {Resolution = FolderImage:GetAttribute("Resolution"),Relative = FolderImage:GetAttribute("Relative")}
		local resolution = FolderImage:GetAttribute("Resolution")
		for i, a in ipairs(Childs) do
			local pixels = buffer.fromstring(a:GetAttribute("Image"))
			frames[i] = pixels
			local TempEditable = AssetService:CreateEditableImage({ Size = size })
			TempEditable:WritePixelsBuffer(Vector2.zero, size, pixels)
			local ID = select(2,AssetService:CreateDataModelContentAsync(Content.fromObject(TempEditable)))
			frameStatic[i] = ID
			Data.Custom = a:GetAttribute("VertexData")
			TempEditable:Destroy()
			local paths,CenterOfMass = CollisionGenerator.Generate(CollisionType,pixels, size,Data)
			module.CreatedColliders[SpriteFolder][i] = paths
			module.CenterOfMass[SpriteFolder][i] = CenterOfMass
		end
		module.CollisionType[SpriteFolder] = CollisionType
		module.CreatedSprites[SpriteFolder] = {FramesBuffer = frames,FramesStatic = frameStatic,Cant = #Childs}
		module.Sizes[SpriteFolder] = size
	end
	
	AnimationsFolder.GenerateAnimationEvents(ImageObject)
	if Type == "Static" then
		local Cont = ImageObject.ImageContent.Object
		if Cont then
			Cont:Destroy()
		end
		local Image = module.CreatedSprites[SpriteFolder].FramesStatic[Frame]
		ImageObject.ImageContent = Image
	else
		local pixels = module.CreatedSprites[SpriteFolder].FramesBuffer[Frame]
		local NewEditable = AssetService:CreateEditableImage({ Size = size })
		NewEditable:WritePixelsBuffer(Vector2.zero, size, pixels)
		ImageObject.ImageContent = Content.fromObject(NewEditable)	
	end
	
	ImageObject:SetAttribute("ImageFolder",SpriteFolder)
	ImageObject:SetAttribute("Frame", Frame or 1)
	
	ImageObject:SetAttribute("FPS",ImageObject:GetAttribute("FPS") or 12)
	if workspace:GetAttribute("Debug_Collision_Spritely") then
		for CF=1, #module.CreatedSprites[SpriteFolder].FramesStatic do
			DrawCollisionDebug(ImageObject, module.CreatedColliders[SpriteFolder][CF], module.CenterOfMass[SpriteFolder][CF], size,ImageObject:GetAttribute("Visible_Debug"),CollisionType,CF,Frame)
		end
	end
	return {Cant = module.CreatedSprites[SpriteFolder].Cant,FramesBuffer = module.CreatedSprites[SpriteFolder].FramesBuffer,FramesStatic = module.CreatedSprites[SpriteFolder].FramesStatic, Size = size,CollisionType = CollisionType}
end

return module
