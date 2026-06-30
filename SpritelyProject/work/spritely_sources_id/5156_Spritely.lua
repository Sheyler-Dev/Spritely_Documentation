--!native
local Spritely = {}

local AnimationsFolder = require(script:WaitForChild("AnimationsFolder"))
local GenerateObject = require(script:WaitForChild("GenerateObject"))
local Touch = require(script:WaitForChild("Touch"))
local RayCast = require(script:WaitForChild("RayCast"))
local SoundService = require(script:WaitForChild("SoundService"))
local InstanceLoaded = script:WaitForChild("InstanceLoaded")
Spritely.Loadeds = {}

local DetectorTypes = {
	"Fast",
	"Detailed"
}

local Conecter = {
	["Static"] = "FramesStatic",
	["Dynamic"] = "FramesDynamic",
}

local Animator = require(script:WaitForChild("PlayAnimations"))

--[[function Spritely:UpdateCollision(ImageObject)
	GenerateObject.UpdatePixelHash(ImageObject)
end -- Development
]]

function Spritely:CreateObject(ImageObject:ImageButton | ImageLabel,SpriteFolder:string,Frame:number?)
	local NewFrameFolder = GenerateObject.SetPixelHash(ImageObject,SpriteFolder,Frame,"Static")
	if NewFrameFolder then
		AnimationsFolder.AnimationsFolder[SpriteFolder] = NewFrameFolder
	end
	if not table.find(Spritely.Loadeds,ImageObject) then
		table.insert(Spritely.Loadeds,ImageObject)
		InstanceLoaded:Fire(ImageObject)
	end
end

function Spritely:WaitForInstanceLoaded(ImageObject:ImageLabel|ImageButton, TimeOut:number|nil)
	if Spritely.IstanceLoaded(ImageObject) then
		return 0
	end

	TimeOut = (typeof(TimeOut) == "number") and TimeOut or 10
	local Timer = tick()
	local currentThread = coroutine.running()
	local connection

	local timeoutTask = task.delay(TimeOut, function()
		warn("Waiting time exceeded for:", ImageObject)
		if connection then connection:Disconnect() end
		task.spawn(currentThread, false)
	end)

	connection = InstanceLoaded.Event:Connect(function(obj)
		if obj == ImageObject then
			connection:Disconnect()
			task.cancel(timeoutTask)
			task.spawn(currentThread, true)
		end
	end)
	coroutine.yield()
	return tick() - Timer
end

function Spritely:GetImageBuffer(SpriteFolder:string,Frame:number)
	return GenerateObject.CreatedSprites[SpriteFolder][Frame], GenerateObject.Sizes[SpriteFolder]
end

function Spritely.IstanceLoaded(ImageObject:ImageLabel|ImageButton)
	if table.find(Spritely.Loadeds,ImageObject) then
		return true
	else
		return false		
	end
end

	function Spritely:SetImageBuffer(ImageObject:ImageLabel|ImageButton,Buffer)
		local EditableImage:EditableImage = ImageObject.ImageContent.Object
	if EditableImage then
		EditableImage:WritePixelsBuffer(Vector2.zero,EditableImage.Size,Buffer)
	end
end

function Spritely.IsTouching(Image1:ImageLabel,Image2:ImageLabel,Type:string?)
	if not Type or typeof(Type)~="string" then
		Type = "Fast"
	end
	if not table.find(DetectorTypes,Type) then
		warn("Error. Invalid Type")
		return false
	end
	if Type == "Fast" then
		return Touch.collisionFromBoxes(Image1,Image2)
	elseif Type == "Detailed" then
		return Touch.collisionFromBoxesDetailed(Image1,Image2)
	else 
		warn("Error. Invalid Type")
		return false
	end
end

function Spritely:RayCast(Position,Direction,Options)
	return RayCast.performRaycast(Position,Direction,Options)
end

function Spritely:AddSound(SoundId:number,ImageObject)
	return SoundService.CreateSound(SoundId,ImageObject)
end

function Spritely:SetFrame(ImageObject:ImageLabel|ImageButton,Frame)
	local Type = ImageObject:GetAttribute("Type") or "Static"
	local ImageFolder = ImageObject:GetAttribute("ImageFolder")
	if not ImageFolder then
		warn("Error. No ImageFolder")
		return
	end
	if not Frame then
		warn("Error. No Frame")
		return
	end
	local AnimationF = AnimationsFolder.AnimationsFolder[ImageFolder]
	if not AnimationF then
		warn("Error. No Animation Folder")
		return
	end
	if AnimationF.Cant<Frame or Frame < 1 then
		warn("Error. Frame not found")
		return
	end
	if Type == "Static" then
		local FrameStatic = AnimationF.FramesStatic[Frame]
		if not FrameStatic then
			warn("Error. Frame not found")
			return
		end
		ImageObject.ImageContent = FrameStatic
		ImageObject:SetAttribute("Frame",Frame)	
	elseif Type == "Dynamic" then
		local FrameBuffer = AnimationF.FramesBuffer[Frame]
		if not FrameBuffer then
			warn("Error. Frame not found")
			return
		end
		ImageObject.ImageContent.Object:WritePixelsBuffer(Vector2.zero,ImageObject.ImageContent.Object.Size, FrameBuffer)
		ImageObject:SetAttribute("Frame",Frame)	
	end
end

function Spritely:PlayAnimation(ImageLabel:ImageLabel|ImageButton,FPS:number|nil,Loop:boolean,MinFrame:number,MaxFrame:number)
	if ImageLabel and not (ImageLabel:IsA("ImageLabel") or ImageLabel:IsA("ImageButton")) then return end
	Animator:Play(ImageLabel,FPS,Loop,MinFrame,MaxFrame)
end

function Spritely:StopAnimation(ImageLabel)
	Animator:Stop(ImageLabel)
end

function Spritely:GetAnimationEvent(ImageObject:ImageLabel|ImageButton)
	local Default = Animator:GetAnimationEvent(ImageObject) or nil
	return Default
end

return Spritely
