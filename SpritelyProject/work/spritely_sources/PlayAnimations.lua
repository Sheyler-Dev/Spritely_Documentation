--!native
local RunService = game:GetService("RunService")
local Animations = {}
local AnimationEvents = {}

type AnimationEventsTable = {
	Stopped: RBXScriptSignal,
	Played: RBXScriptSignal,
	Ended: RBXScriptSignal,
	FrameChanged: RBXScriptSignal
}
local Parent  = require(script.Parent:WaitForChild("AnimationsFolder"))
local AnimationContext = {}

function RenderAnimation(FPS,Frame,MaxFrameR,MinFrameR,Loop:boolean,ImageObject:ImageLabel|ImageButton,Finished:BindableEvent,Folder,Changed:BindableEvent)
	local Type = ImageObject:GetAttribute("Type")
	local Timer = FPS
	if Type == "Static" then
		local AnimationsFolder = Folder.FramesStatic
		local obj = RunService.RenderStepped:Connect(function(dt)
			Timer+=dt
			if Timer>= FPS then
				Frame += 1
				if Frame > MaxFrameR then
					if not Loop then
						Finished:Fire()
						AnimationContext[ImageObject] = "Ended"
						Animations:Stop(ImageObject)
						return
					end
					Frame = MinFrameR
				end
				Changed:Fire(Frame)
				ImageObject.ImageContent = AnimationsFolder[Frame]
				ImageObject:SetAttribute("Frame",Frame)
				Timer = 0	
			end
		end)
		if not Parent.Animations[ImageObject] then
			Parent.Animations[ImageObject] = {}
		end
		table.insert(Parent.Animations[ImageObject],obj)
	elseif Type == "Dynamic" then
		local AnimationsFolder = Folder.FramesBuffer
		local ImageContent = ImageObject.ImageContent.Object
		local obj = RunService.RenderStepped:Connect(function(dt)
			Timer+=dt
			if Timer>= FPS then
				Frame += 1
				if Frame > MaxFrameR then
					if not Loop then
						Finished:Fire()
						AnimationContext[ImageObject] = "Ended"
						Animations:Stop(ImageObject)
						return
					end
					Frame = MinFrameR
				end
				Changed:Fire(Frame)
				ImageContent:WritePixelsBuffer(Vector2.zero,ImageContent.Size,AnimationsFolder[Frame])
				ImageObject:SetAttribute("Frame",Frame)
				Timer = 0	
			end
		end)
		if not Parent.Animations[ImageObject] then
			Parent.Animations[ImageObject] = {}
		end
		table.insert(Parent.Animations[ImageObject],obj)
	end
end

function Animations:Play(ImageObject:ImageLabel|ImageButton,FPS:number,Loop:boolean,MinFrame:number,MaxFrame:number)
	FPS = FPS or 12
	if typeof(FPS) ~= "number" then
		FPS = 12
	end
	FPS = math.clamp(FPS,1,120)
	FPS = 1/FPS
	local Folder = Parent.AnimationsFolder[ImageObject:GetAttribute("ImageFolder")]
	if not Folder then
		warn("Error.",ImageObject)
		return
	end
	local MinFrameR = MinFrame or 1
	local Frame = MinFrameR
	local MaxFrameR = MaxFrame or Folder.Cant
	if MaxFrameR>Folder.Cant then
		MaxFrameR = Folder.Cant
	end
	if MinFrameR<1 then
		MinFrameR = 1
	elseif MinFrameR>MaxFrameR then
		MinFrameR = MaxFrameR
	end
	AnimationContext[ImageObject] = "nil"
	local Events = Parent.GenerateAnimationEvents(ImageObject)
	if not AnimationEvents[ImageObject] then
		AnimationEvents[ImageObject] = {}
		for i,a:BindableEvent in pairs(Events) do
			AnimationEvents[ImageObject][i] = a.Event
		end
	end
	local Timer = FPS
	AnimationContext[ImageObject] = "Playing"
	Events.Played:Fire()
	RenderAnimation(FPS,Frame,MaxFrameR,MinFrameR,Loop,ImageObject,Events.Ended,Folder,Events.FrameChanged)
end

function Animations:Stop(ImageObject:ImageLabel|ImageButton)
	if Parent.Animations[ImageObject] then
		for i,a in pairs(Parent.Animations[ImageObject]) do
			a:Disconnect()
			table.remove(Parent.Animations[ImageObject],i)	
		end
	end
end

function Animations:GetAnimationEvent(ImageObject:ImageLabel|ImageButton): AnimationEventsTable?
	if AnimationEvents[ImageObject] then
		return AnimationEvents[ImageObject]
	else
		local Events = Parent.GenerateAnimationEvents(ImageObject)
		if not AnimationEvents[ImageObject] then
			AnimationEvents[ImageObject] = {}
			for i,a:BindableEvent in pairs(Events) do
				AnimationEvents[ImageObject][i] = a.Event
			end
		end
		return AnimationEvents[ImageObject]
	end
end

return Animations
